extends Node3D
## Readable hold -> cardinal slam -> hold. No per-frame random turns or flashing cues.
const Data=preload("res://scripts/level_data.gd")
const Art=preload("res://scripts/art.gd")
const SLAM_TIME=0.16
const DIRECTIONS={0:Vector2i.UP,90:Vector2i.LEFT,180:Vector2i.DOWN,270:Vector2i.RIGHT}
var world: Node3D
var balls: Array=[]
func setup(data: Dictionary, owner_world: Node3D) -> void:
 world=owner_world
 for obj in data.objects:
  if obj.type!="spike_ball": continue
  var body=Art.spike_ball()
  body.position=world.cell_position(obj.pos)
  add_child(body)
  Art.batch_static(body,[]) # Four instanced material groups instead of individual spikes.
  var cue=Node3D.new()
  add_child(cue)
  var rng=RandomNumberGenerator.new()
  rng.seed=hash(obj.id)
  var route: Array=[obj.pos]
  for p in obj.get("waypoints",[]):
   if p!=route[-1]: route.append(p)
  var ball={"node":body,"cue":cue,"obj":obj,"route":route,"route_index":0,"rng":rng,"direction":Vector2i.ZERO,"target":body.position,"from":body.position,"previous":body.position,"moving":false,"time":0.0,"hold":float(obj.get("pause",2)),"stopped":false,"slams":0}
  balls.append(ball)
  choose_target(ball)
func choose_target(ball: Dictionary) -> void:
 var here: Vector2i=world.position_cell(ball.node.position)
 var target=here
 if ball.obj.get("behavior","free_shift")=="slam_patrol":
  if ball.route.size()>1:
   var next=int(ball.route_index)+1
   if next>=ball.route.size():
    if ball.obj.get("patrol_loop",true): next=0
    else: ball.stopped=true
   if not ball.stopped:
    var p: Array=ball.route[next]
    if Data.spike_segment_open(world.level,[here.x,here.y],p):
     target=Vector2i(p[0],p[1])
     ball.route_index=next
 else:
  var choices: Array=[]
  for angle in ball.obj.get("directions",[0,90,180,270]):
   var dir: Vector2i=DIRECTIONS[int(angle)]
   var end=here
   for distance in range(1,int(ball.obj.get("range",3))+1):
    var p=here+dir*distance
    if not Data.spike_cell_open(world.level,p): break
    end=p
   if end!=here: choices.append({"dir":dir,"end":end})
  var forward=choices.filter(func(item: Dictionary): return item.dir!=-ball.direction)
  if not forward.is_empty(): choices=forward
  if not choices.is_empty():
   var choice: Dictionary=choices[ball.rng.randi_range(0,choices.size()-1)]
   target=choice.end
   ball.direction=choice.dir
 ball.target=world.cell_position([target.x,target.y])
 ball.hold=float(ball.obj.get("pause",2))
 show_target(ball)
func show_target(ball: Dictionary) -> void:
 for child in ball.cue.get_children():
  ball.cue.remove_child(child)
  child.queue_free()
 var delta: Vector3=ball.target-ball.node.position
 if delta.length()<0.01: return
 # Stable track and endpoint marker announce exactly where the next slam goes.
 var strip=Art.box(ball.cue,Vector3(0.11,0.025,delta.length()),(ball.node.position+ball.target)*0.5+Vector3(0,0.035,0),Color("d99b56"))
 strip.rotation.y=atan2(delta.x,delta.z)
 Art.cylinder(ball.cue,0.43,0.43,0.025,ball.target+Vector3(0,0.04,0),Color("d99b56"),8)
 Art.cylinder(ball.cue,0.28,0.28,0.027,ball.target+Vector3(0,0.055,0),Color("55402e"),8)
 var limit=0.0 if world.editing or world.map_view else float(world.level.get("draw_distance",18))*world.CELL
 for mesh in ball.cue.get_children():
  mesh.visibility_range_end=limit
  mesh.visibility_range_end_margin=world.CELL
func start_slam(ball: Dictionary) -> void:
 if ball.stopped or ball.node.position.distance_to(ball.target)<0.01: return
 var here: Vector2i=world.position_cell(ball.node.position)
 var end: Vector2i=world.position_cell(ball.target)
 if not Data.spike_segment_open(world.level,[here.x,here.y],[end.x,end.y]):
  choose_target(ball)
  return
 ball.from=ball.node.position
 ball.time=0.0
 ball.moving=true
 ball.slams+=1
func begin_beat() -> void:
 for ball in balls:
  if ball.moving: continue
  if ball.hold>0:
   ball.hold-=1.0
  else: start_slam(ball)
func advance(delta: float, old_player: Vector3, new_player: Vector3, airborne: bool, tile: bool=false) -> void:
 for ball in balls:
  ball.previous=ball.node.position
  if not tile and not ball.moving:
   ball.hold=maxf(0,ball.hold-delta)
   if ball.hold<=0: start_slam(ball)
  if ball.moving:
   ball.time=minf(SLAM_TIME,float(ball.time)+delta)
   ball.node.position=ball.from.lerp(ball.target,float(ball.time)/SLAM_TIME)
   if ball.time>=SLAM_TIME:
    ball.moving=false
    ball.node.position=ball.target
    choose_target(ball)
  # Relative swept collision covers the whole fast slam and the frog's motion.
  var relative_start=old_player-ball.previous
  var relative_end=new_player-ball.node.position
  var nearest=Geometry3D.get_closest_point_to_segment(Vector3.ZERO,relative_start,relative_end)
  if not airborne and nearest.length()<0.82:
   world.death_cause="spike_ball"
   world.finish("SPIKED!")
   return
  var charge=1.0-clampf(float(ball.hold)/maxf(1,float(ball.obj.get("pause",2))),0,1)
  ball.node.scale=Vector3.ONE*(0.94+0.06*charge)
