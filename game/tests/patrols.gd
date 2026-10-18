extends SceneTree
const Data = preload("res://scripts/level_data.gd")
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
 app.completed_stages = [0,1,2,3]
 app.load_builtin(3, "human")
 var original: Dictionary = Data.load_json("res://tests/fixtures/Frogbutt_original.json")
 var revised: Dictionary = app.level.duplicate(true)
 var expected: Dictionary = original.duplicate(true)
 for obj in expected.objects:
  if obj.type == "critter" and obj.get("behavior") == "patrol":
   obj.waypoints = [[7,1],[7,11]]
   obj.patrol_loop = true
 suite.check(not original.is_empty() and revised == expected, "Only the existing Frogbutt worm route changed; tiles, other enemies, scenery, traps and positions are preserved")
 suite.check(Data.validate(revised).is_empty() and Data.reachable(revised), "Frogbutt remains valid and its spawn-to-exit route is connected")
 app.enter_editor()
 app.selection = "mire-patrol"
 app.make_north_south_loop()
 suite.check(app.selected_object().waypoints == [[7,1],[7,11]] and app.selected_object().patrol_loop, "Editor north–south preset scans the clear column and repeats its endpoints")
 app.change_property("patrol_loop", false)
 app.selection = "mire-patrol"
 suite.check(not app.selected_object().patrol_loop, "Loop checkbox is an editable saved property")
 app.undo()
 app.selection = "mire-patrol"
 suite.check(app.selected_object().patrol_loop, "Undo restores the looping patrol property")
 var round_trip: Dictionary = Data.normalize(JSON.parse_string(JSON.stringify(app.level)))
 suite.check(round_trip == app.level and Data.validate(round_trip).is_empty(), "Loop route survives JSON export/import without a schema version change")
 var malformed: Dictionary = revised.duplicate(true)
 malformed.objects[0].patrol_loop = "yes"
 suite.check(not Data.validate(malformed).is_empty(), "Invalid loop property types are rejected")
 var legacy: Dictionary = original.duplicate(true)
 app.world.load_level(legacy, true, app.hat)
 var worm: Node3D = app.world.critters.filter(func(c): return c.behavior == "patrol")[0]
 suite.check(worm.patrol_loop and Data.validate(legacy).is_empty(), "Legacy version-1 patrols without a loop property retain repeating behavior")
 worm.waypoint_index = worm.waypoints.size()-1
 worm.advance_waypoint()
 suite.check(worm.waypoint_index == 0 and not worm.patrol_finished, "Legacy final waypoint wraps to the first")
 worm.patrol_loop = false
 worm.waypoint_index = worm.waypoints.size()-1
 worm.advance_waypoint()
 var stopped := worm.position
 await physics_frame
 worm.step(1.0/60.0)
 suite.check(worm.patrol_finished and worm.position.distance_to(stopped) < 0.001, "Non-looping patrol stops at the final waypoint")
 app.world.load_level(revised, true, app.hat)
 worm = app.world.critters.filter(func(c): return c.behavior == "patrol")[0]
 var x: float = worm.position.x
 var north := false
 var south := false
 var reversals := 0
 var last_direction := 0
 var max_x_drift := 0.0
 for i in range(4800):
  await physics_frame
  worm.step(1.0/60.0)
  max_x_drift = maxf(max_x_drift, absf(worm.position.x-x))
  var cell: Vector2i = app.world.position_cell(worm.position)
  north = north or cell.y == 1
  south = south or cell.y == 11
  var direction := signi(int(round(worm.direction.z)))
  if direction != 0 and direction != last_direction:
   reversals += 1
   last_direction = direction
 suite.check(north and south and reversals >= 5 and max_x_drift < 0.01, "Real worm collider traverses both vertical endpoints repeatedly without horizontal drift (80 simulated seconds)")
 # Preset endpoints stop at water and at static scenery rather than crossing them.
 app.enter_editor()
 app.selection = "mire-3"
 app.make_north_south_loop()
 var obj: Dictionary = app.selected_object()
 suite.check(obj.waypoints == [[11,7],[11,11]], "Editor preset stops at the water immediately north of this critter")
 print("PATROL CHECKS: %d checks, %d failures" % [suite.checks,suite.failures.size()])
 quit(0 if suite.failures.is_empty() else 1)
