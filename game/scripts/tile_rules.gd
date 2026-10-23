extends RefCounted
## Cardinal tile simulation. One accepted hop advances one hazard beat in Move with me.
const Data = preload("res://scripts/level_data.gd")
const Rules = preload("res://scripts/level_rules.gd")
const HOP_TIME = 0.34
const BEAT_TIME = 0.62
var world: Node3D
var jumping = false
var long_hop = false
var hop_time = 0.0
var from = Vector3.ZERO
var to = Vector3.ZERO
var beat_clock = 0.0
var repeat_clock = 0.0
var moves: Array = []
var facing = Vector2i.UP
var hop_count = 0
var beat_count = 0
var last_block = ""
var last_player = Vector3.ZERO
var queued_direction = Vector2i.ZERO
var queued_big = false
var charge_remaining = 0
var reserve = false
var fragments = 0
var collected: Array = []
var long_hops_used = 0
var pickups_collected = 0

func _init(owner_world: Node3D) -> void:
 world = owner_world

func airborne() -> bool:
 return jumping and long_hop and sin(PI * clampf(hop_time / HOP_TIME, 0, 1)) > 0.48

func point(pos: Vector3) -> Vector2:
 return Vector2(pos.x / world.CELL + (world.level.width - 1) * 0.5, pos.z / world.CELL + (world.level.height - 1) * 0.5)

func open_cell(cell: Vector2i, landing: bool = true) -> bool:
 if not world.inside(cell) or world.level.tiles[cell.y][cell.x] in ["wall", "cheese_wall"]:
  return false
 if landing:
  for obj in world.level.objects:
   if obj.pos == [cell.x,cell.y] and (obj.type in ["pillar","tree","emitter"] or obj.get("solid", false)):
    return false
 return true

func ready_for_input() -> bool:
 return not jumping and repeat_clock <= 0.08

func long_hop_ready() -> bool:
 if Rules.collectible(world.level): return reserve
 return not Rules.charged(world.level) or charge_remaining == 0

func resource_label() -> String:
 if Rules.mode(world.level) == "fragments": return "READY" if reserve else "%d / 3 FRAGMENTS" % fragments
 if Rules.mode(world.level) == "powerup": return "READY" if reserve else "FIND HOP SEED"
 return "READY" if charge_remaining == 0 else "%d SHORT HOPS" % charge_remaining

func checkpoint_state() -> Dictionary:
 return {"reserve":reserve,"fragments":fragments,"collected":collected.duplicate()}

func restore_resource(state: Dictionary) -> void:
 if not Rules.collectible(world.level): return
 reserve = state.get("reserve",false)
 fragments = int(state.get("fragments",0))
 collected = state.get("collected",[]).duplicate()
 for entry in world.hop_pickups: entry.node.visible = entry.obj.id not in collected

func collect_landing(cell: Vector2i) -> void:
 if not Rules.collectible(world.level) or reserve: return
 var wanted := "hop_fragment" if Rules.mode(world.level) == "fragments" else "hop_seed"
 for entry in world.hop_pickups:
  if entry.obj.type != wanted or entry.obj.id in collected or entry.obj.pos != [cell.x,cell.y]: continue
  collected.append(entry.obj.id)
  entry.node.hide()
  pickups_collected += 1
  if wanted == "hop_fragment":
   fragments += 1
   if fragments >= 3: fragments = 0; reserve = true
  else: reserve = true
  world.hint_changed.emit(("Long hop ready. Tap Long hop, then choose a direction." if reserve else "%d / 3 fragments. Land on two more." % fragments) if fragments != 2 else "2 / 3 fragments. One more to earn a long hop.")
  break

func queue_hop(direction: Vector2i, big: bool) -> void:
 queued_direction = direction
 queued_big = big

func request(direction: Vector2i, big: bool) -> bool:
 if jumping or direction == Vector2i.ZERO:
  return false
 if big and not long_hop_ready():
  last_block = resource_label() + " · " + Rules.short_rule(world.level)
  world.hint_changed.emit(last_block)
  return false
 var start: Vector2i = world.position_cell(world.player.position)
 var target = start + direction * (2 if big else 1)
 if not open_cell(target) or (big and not open_cell(start + direction, false)):
  last_block = "A wall or blocked landing stops that hop."
  world.hint_changed.emit(last_block)
  return false
 last_block = ""
 from = world.player.position
 to = world.cell_position([target.x,target.y])
 facing = direction
 long_hop = big
 if big:
  long_hops_used += 1
  if Rules.collectible(world.level): reserve = false
 if big and Rules.charged(world.level):
  charge_remaining = Rules.charge_hops(world.level)
 hop_time = 0
 jumping = true
 hop_count += 1
 world.player.visual.rotation.y = atan2(-float(direction.x), -float(direction.y))
 world.hop_started.emit(big)
 if world.level.get("move_with_me", false):
  begin_beat()
 return true

func begin_beat() -> void:
 # Finish the preceding beat exactly before choosing the next tile.
 for motion in moves:
  if is_instance_valid(motion.node): motion.node.position = motion.to
 moves.clear()
 beat_count += 1
 world.spikes.begin_beat()
 for actor in world.critters:
  var here = point(actor.position).snapped(Vector2(0.5,0.5))
  var dir = Vector2.ZERO
  if actor.behavior in ["patrol","seam_patrol"] and not actor.waypoints.is_empty():
   var goal: Vector3 = actor.waypoints[actor.waypoint_index]
   if actor.position.distance_to(goal) < 0.05:
    actor.advance_waypoint()
    goal = actor.waypoints[actor.waypoint_index]
   if not actor.patrol_finished:
    var diff = point(goal) - here
    dir = Vector2(signf(diff.x),0) if absf(diff.x) > 0.01 else Vector2(0,signf(diff.y))
  elif actor.behavior != "seam_patrol":
   actor.turn_timer -= 1.0
   if actor.turn_timer <= 0: actor.choose_direction()
   dir = Vector2(signf(actor.direction.x),0) if absf(actor.direction.x) >= absf(actor.direction.z) else Vector2(0,signf(actor.direction.z))
  var next = here + dir
  var allowed = Data.seam_point_open(world.level, [next.x,next.y]) if actor.behavior == "seam_patrol" else open_cell(Vector2i(roundi(next.x), roundi(next.y)))
  if allowed and actor.behavior != "seam_patrol":
   allowed = world.level.tiles[roundi(next.y)][roundi(next.x)] != "water"
  if dir != Vector2.ZERO and allowed:
   var end: Vector3 = world.cell_position([next.x,next.y])
   moves.append({"node":actor,"from":actor.position,"to":end,"time":0.0,"actor":true})
   actor.visual.rotation.y = atan2(-dir.x,-dir.y)
  elif actor.behavior in ["patrol","seam_patrol"]:
   actor.advance_waypoint()
  else:
   actor.direction = -actor.direction
 for mover in world.crossing.movers:
  var start: Vector3 = mover.node.position
  var cell: Vector2i = world.position_cell(start)
  var target = cell
  if mover.kind == "patrol_car":
   # Drawn routes retain their orthogonal road routing; each beat covers one cell.
   if not mover.route.is_empty():
    var goal: Array = mover.route[mover.route_index]
    if cell == Vector2i(goal[0],goal[1]):
     mover.route_index = (int(mover.route_index) + 1) % mover.route.size()
     goal = mover.route[mover.route_index]
    var diff = Vector2i(goal[0],goal[1]) - cell
    target += Vector2i(signi(diff.x),0) if diff.x != 0 else Vector2i(0,signi(diff.y))
    if not Data.road_cell_open(world.level,target): target = cell
   else:
    var step = Vector2i(0,mover.direction) if mover.axis == "north_south" else Vector2i(mover.direction,0)
    if not Data.road_cell_open(world.level,cell+step):
     mover.direction = -mover.direction
     step = -step
    if Data.road_cell_open(world.level,cell+step): target += step
   mover.vertical = target.y != cell.y
   mover.node.rotation.y = PI/2 if mover.vertical else 0.0
  else:
   var step = Vector2i(signi(int(signf(mover.speed))),0)
   var next = cell + step
   var terrain = "water" if mover.kind == "log" else "road"
   if not world.inside(next) or world.level.tiles[next.y][next.x] != terrain or (mover.kind == "car" and not Data.road_cell_open(world.level,next)):
    mover.speed = -mover.speed
    next = cell - step
   if world.inside(next) and world.level.tiles[next.y][next.x] == terrain and (mover.kind != "car" or Data.road_cell_open(world.level,next)): target = next
  mover.previous = start
  mover.wrapped = false
  moves.append({"node":mover.node,"from":start,"to":world.cell_position([target.x,target.y]),"time":0.0,"actor":false})
 for emitter in world.emitters:
  emitter.clock -= 1.0
  if emitter.clock <= 0:
   emitter.clock += ceilf(emitter.interval)
   var cell: Vector2i = world.position_cell(emitter.pos)
   world.spawn_projectile(world.cell_position([cell.x,cell.y])+Vector3(0,0.36,0)+emitter.dir*world.CELL,emitter.dir)
 for shot in world.projectiles:
  shot.tile_from = shot.node.position
  shot.tile_to = shot.node.position + shot.dir * world.CELL
  shot.tile_time = 0.0

func advance(delta: float, input: Vector2, big: bool) -> void:
 last_player = world.player.position
 repeat_clock = maxf(0,repeat_clock-delta)
 if ready_for_input() and queued_direction != Vector2i.ZERO:
  var dir = queued_direction
  queued_direction = Vector2i.ZERO
  repeat_clock = HOP_TIME + 0.08 if request(dir,queued_big) else 0.15
 if not jumping and repeat_clock <= 0 and input.length() > 0.3:
  var dir = Vector2i(signi(int(signf(input.x))),0) if absf(input.x) >= absf(input.y) else Vector2i(0,signi(int(signf(input.y))))
  if request(dir,big): repeat_clock = HOP_TIME + 0.08
  else: repeat_clock = 0.15
 var linked: bool = world.level.get("move_with_me",false)
 var was_jumping = jumping
 var ticking = not linked or jumping
 if not ticking:
  return
 world.elapsed += delta
 if not linked:
  beat_clock += delta
  if beat_clock >= BEAT_TIME:
   beat_clock -= BEAT_TIME
   begin_beat()
 if jumping:
  hop_time = minf(HOP_TIME,hop_time + delta)
  var t = hop_time / HOP_TIME
  world.player.position = from.lerp(to,t)
  world.player.visual.position.y = sin(t*PI) * (1.35 if long_hop else 0.48)
  world.player.hop_pose_style = world.hop_pose_style
  world.player.pose_tile_hop(t, long_hop)
  if t >= 1.0:
   jumping = false
   if not long_hop and charge_remaining > 0:
    charge_remaining -= 1
   world.player.position = to
   world.player.visual.position.y = 0
 for mover in world.crossing.movers:
  mover.previous = mover.node.position
  if mover.kind == "patrol_car": mover.segments.clear()
 var support: Dictionary = world.crossing.log_at(world.player.position) if not was_jumping else {}
 for motion in moves:
  motion.time = minf(HOP_TIME,float(motion.time) + delta)
  var t: float = motion.time/HOP_TIME
  motion.node.position = motion.from.lerp(motion.to,t)
  if motion.actor: motion.node.visual.position.y = sin(t*PI)*0.22
 # Logs carry the resting frog by the same grid-aligned step, without teleporting.
 if not support.is_empty():
  world.player.position += support.node.position - support.previous
  if not jumping and support.node.position.distance_to(support.previous) > 0:
   world.player.position.z = support.node.position.z
 for mover in world.crossing.movers:
  if mover.kind == "patrol_car":
   mover.segments.append({"from":mover.previous,"to":mover.node.position,"vertical":mover.vertical})
 var protected = airborne()
 world.spikes.advance(delta,last_player,world.player.position,protected,true)
 if not world.result.is_empty(): return
 if not protected and world.crossing.traffic_hit(last_player,world.player.position):
  world.finish("SQUISHED!")
  return
 for actor in world.critters:
  if not protected and world.player.position.distance_to(actor.position) < 0.78:
   world.death_cause = actor.behavior
   world.finish("CROAKED!")
   return
 for i in range(world.projectiles.size()-1,-1,-1):
  var shot: Dictionary = world.projectiles[i]
  if not shot.has("tile_from"): continue
  var old: Vector3 = shot.node.position
  shot.tile_time = minf(HOP_TIME,float(shot.tile_time) + delta)
  var next: Vector3 = shot.tile_from.lerp(shot.tile_to,shot.tile_time/HOP_TIME)
  var query = PhysicsRayQueryParameters3D.create(old,next,1)
  var hit: Dictionary = world.get_world_3d().direct_space_state.intersect_ray(query) if old.distance_to(next)>0.001 else {}
  var near = Geometry3D.get_closest_point_to_segment(world.player.position+Vector3(0,0.36,0),old,next)
  if not protected and near.distance_to(world.player.position+Vector3(0,0.36,0)) < 0.48:
   world.finish("HIT!")
   return
  shot.node.position = next
  shot.life -= delta
  if not hit.is_empty() or shot.life <= 0:
   shot.node.queue_free()
   world.projectiles.remove_at(i)
 if not jumping:
  var cell: Vector2i = world.position_cell(world.player.position)
  if not world.inside(cell) or (world.level.tiles[cell.y][cell.x] == "water" and world.crossing.log_at(world.player.position).is_empty()):
   world.finish("SPLASHED!")
   return
  if was_jumping: world.hop_landed.emit(long_hop)
  collect_landing(cell)
  if world.level.has("checkpoint") and not world.crossing.checkpoint_claimed and cell.y <= int(world.level.checkpoint[1]) and world.level.tiles[cell.y][cell.x] not in ["water","road"]:
   world.crossing.checkpoint_claimed = true
   world.claim_checkpoint(world.level.checkpoint)
  for p in world.level.get("checkpoints",[]):
   if cell == Vector2i(p[0],p[1]): world.claim_checkpoint(p)
  if world.player.position.distance_to(world.cell_position(world.level.exit)) < 0.65:
   world.finish("LEVEL COMPLETE!")
