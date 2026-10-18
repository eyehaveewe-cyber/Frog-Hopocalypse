extends SceneTree
const Data = preload("res://scripts/level_data.gd")
const Actor = preload("res://scripts/actor.gd")
const Suite = preload("res://tests/integration.gd")
var suite = Suite.new()
var app: Control
func _initialize() -> void:
 app = preload("res://main.tscn").instantiate()
 root.add_child(app)
 call_deferred("run")
func run() -> void:
 await process_frame
 app.set_process(false)
 app.world.set_physics_process(false)
 var level := Data.blank("Cheese and seams", "egypt", 7, 7)
 for y in range(1,6): level.tiles[y][3] = "cheese_wall"
 suite.check(Data.validate(level).is_empty() and not Data.reachable(level), "Cheese wall terrain blocks route validation")
 level.tiles[1][3] = "floor"
 suite.check(Data.reachable(level), "An open gap restores a playable route")
 app.level = level
 app.enter_editor()
 app.set_tool("cheese_wall")
 app.edit_cell(Vector2i(2,3))
 suite.check(app.level.tiles[3][2] == "cheese_wall", "Editor paints cheese walls")
 app.undo()
 suite.check(app.level.tiles[3][2] == "floor", "Undo restores painted terrain")
 app.set_tool("cheese_wall")
 app.edit_cell(Vector2i(1,5))
 suite.check(app.level.tiles[5][1] != "cheese_wall", "Editor protects frog spawn from cheese walls")
 app.world.load_level(level, false, app.hat)
 var world: Node3D = app.world
 await physics_frame
 world.player.position = world.cell_position([2,3])
 for i in range(80):
  await physics_frame
  world.player.step(1.0/60.0, Vector2.RIGHT)
 suite.check(world.player.position.x < world.cell_position([3,3]).x - 0.9, "Real frog collider cannot cross cheese wall")
 for behavior in ["wander", "patrol", "seam_patrol"]:
  var enemy := Actor.new()
  enemy.setup(false,"egypt",{"behavior":behavior,"speed":2.0})
  enemy.position = world.cell_position([2,2])
  world.geometry.add_child(enemy)
  enemy.waypoints.append(world.cell_position([4,2]))
  for i in range(80):
   await physics_frame
   enemy.direction = Vector3.RIGHT
   enemy.turn_timer = 100
   enemy.step(1.0/60.0)
  suite.check(enemy.position.x < world.cell_position([3,2]).x - 0.9, "Cheese blocks enemy collider: " + behavior)
  enemy.queue_free()
 world.player.position = world.cell_position([4,3])
 world.spawn_projectile(world.cell_position([2,3])+Vector3(0,0.36,0),Vector3.RIGHT)
 for i in range(45):
  await physics_frame
  world._physics_process(1.0/60.0)
  if not world.result.is_empty(): break
 suite.check(world.result == "HIT!", "Real dart passes through cheese and kills frog behind it")
 level.tiles[3][3] = "wall"
 world.load_level(level,false,app.hat)
 world.player.position = world.cell_position([4,3])
 world.spawn_projectile(world.cell_position([2,3])+Vector3(0,0.36,0),Vector3.RIGHT)
 for i in range(45):
  await physics_frame
  world._physics_process(1.0/60.0)
 suite.check(world.result.is_empty() and world.projectiles.is_empty(), "Ordinary walls still stop darts")
 app.level = Data.blank("Seam route", "egypt", 7,7)
 app.enter_editor()
 app.set_tool("seam_worm")
 app.stroke_changed = false
 app.edit_cell(Vector2i(2,2))
 var worm_id: String = app.selection
 suite.check(app.selected_object().behavior == "seam_patrol" and app.selected_object().pos == [2.5,2.5], "Editor places a distinct seam worm at a tile junction")
 app.set_tool("route")
 app.edit_cell(Vector2i(4,2))
 app.edit_cell(Vector2i(4,4))
 app.edit_cell(Vector2i(2,4))
 app.edit_cell(Vector2i(2,2))
 suite.check(Data.validate(app.level).is_empty() and app.selected_object().waypoints.size() == 4, "Editor draws a valid square loop along tile seams")
 var decoded: Dictionary = Data.normalize(JSON.parse_string(JSON.stringify(app.level)))
 suite.check(decoded == app.level and Data.validate(decoded).is_empty(), "Half-tile seam routes round-trip through JSON")
 var bad: Dictionary = app.level.duplicate(true)
 bad.objects[0].waypoints = [[4.5,4.5]]
 suite.check(not Data.validate(bad).is_empty(), "Diagonal seam shortcuts are rejected")
 bad = app.level.duplicate(true)
 bad.tiles[3][3] = "cheese_wall"
 suite.check(not Data.validate(bad).is_empty(), "Seam routes beside solid cheese are rejected")
 world.load_level(app.level,true,app.hat)
 var worm: Node3D = world.critters[0]
 var on_seams := true
 var turns := 0
 var previous_index := 0
 for i in range(1200):
  await physics_frame
  worm.step(1.0/60.0)
  var coords: Vector2 = Vector2(worm.position.x, worm.position.z)/world.CELL + Vector2(3,3)
  on_seams = on_seams and (absf(fposmod(coords.x,1)-0.5)<0.01 or absf(fposmod(coords.y,1)-0.5)<0.01)
  if worm.waypoint_index != previous_index:
   turns += 1
   previous_index = worm.waypoint_index
 suite.check(on_seams and turns >= 6, "Real seam-worm collider follows repeated square turns without cutting through tiles")
 app.voice.rng.seed = 99
 suite.check(app.voice.death_cue("CROAKED!","seam_patrol") in ["wormed","wormsploded","busted"], "Seam worms use the existing worm-death recordings")
 print("CHEESE/SEAM: %d checks, %d failures" % [suite.checks,suite.failures.size()])
 quit(0 if suite.failures.is_empty() else 1)
