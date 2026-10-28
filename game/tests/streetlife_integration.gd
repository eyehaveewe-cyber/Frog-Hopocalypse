extends RefCounted
## Real scene, movement, impact and editor checks for the NYC streetlife kit.
const Data = preload("res://scripts/level_data.gd")
var checks := 0
var failures: Array[String] = []

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures.append(description)
		push_error("FAIL: " + description)

func frames(app: Control, count: int = 2) -> void:
	for _i in range(count):
		await app.get_tree().physics_frame

func fixture() -> Dictionary:
	var map := Data.blank("Streetlife motion fixture", "nyc")
	map.objects = [{"id": "rider", "type": "skater", "pos": [5, 4], "variant": 0, "speed": 3.0,
		"route": [{"pos": [5, 4], "height": 0.0, "trick": "push"},
			{"pos": [11, 4], "height": 0.57, "trick": "grind"},
			{"pos": [11, 8], "height": 0.57, "trick": "ramp"},
			{"pos": [5, 8], "height": 0.0, "trick": "cruise"}]}]
	return map

func rider(map: Dictionary) -> Dictionary:
	for obj in map.objects:
		if obj.type == "skater":
			return obj
	return {}

func run(app: Control) -> void:
	app.set_process(false)
	var plaza := Data.load_json("res://levels/nyc_06_brooklyn_skate_circle.json")
	check(not plaza.is_empty(), "Regular campaign contains the eighteen-tile-diameter skate plaza")
	if plaza.is_empty():
		return
	check(Data.reachable(plaza), "Skate plaza has a dry route from frog to exit")
	check(Data.save_json("user://streetlife-roundtrip.json", plaza) == OK and Data.load_json("user://streetlife-roundtrip.json") == plaza,
		"Roaches, prop variants and elevated skater routes survive JSON round trip")
	var variants: Dictionary = {}
	var props: Dictionary = {}
	var roaches := 0
	for obj in plaza.objects:
		if obj.type == "skater":
			variants[obj.variant] = true
		elif obj.type == "city_prop":
			props[obj.variant] = true
		elif obj.type == "roach":
			roaches += 1
	check(variants.size() == 3, "Plaza authors three distinct skateboard enemy variants")
	check(props.size() >= 8, "Plaza uses a varied set of the new city assets")
	check(roaches >= 2, "Roaches are integrated into the playable city plaza")
	var invalid: Dictionary = plaza.duplicate(true)
	rider(invalid).route[1].pos = rider(invalid).route[0].pos.duplicate()
	check(not Data.validate(invalid).is_empty(), "Importer rejects a zero-length skater route segment")
	invalid = plaza.duplicate(true)
	rider(invalid).variant = 99
	check(not Data.validate(invalid).is_empty(), "Importer rejects an unknown skateboard enemy variant")
	invalid = plaza.duplicate(true)
	rider(invalid).route[0].height = NAN
	check(not Data.validate(invalid).is_empty(), "Importer rejects a nonfinite skater elevation")
	invalid = plaza.duplicate(true)
	rider(invalid).route[0].height = 10.0
	check(not Data.validate(invalid).is_empty(), "Importer rejects a skater elevation outside the authored range")
	invalid = plaza.duplicate(true)
	rider(invalid).route[0].trick = "teleport"
	check(not Data.validate(invalid).is_empty(), "Importer rejects unknown skating actions")
	invalid = plaza.duplicate(true)
	rider(invalid).route[1].pos = [1, 1]
	check(not Data.validate(invalid).is_empty(), "Importer rejects skating routes outside the circular arena")
	app.level = plaza.duplicate(true)
	app.world.load_level(app.level, false)
	app.world.halted = true
	await frames(app)
	check(app.world.skaters.size() == 3, "All three skateboard enemies instantiate in the shared game world")
	var all_rigs := true
	var starts: Array[Vector3] = []
	for skater in app.world.skaters:
		starts.append(skater.position)
		for path in ["Board", "RiderRoot/Body", "RiderRoot/Head", "RiderRoot/ArmL", "RiderRoot/ArmR", "RiderRoot/LegL", "RiderRoot/LegR"]:
			all_rigs = all_rigs and skater.visual.has_node(path)
	check(all_rigs, "Every rider model has separate board, head, torso and limb pivots")
	var actual_roaches: Array = []
	for critter in app.world.critters:
		if critter.species == "roach":
			actual_roaches.append(critter)
	check(actual_roaches.size() == roaches, "Authored roaches instantiate as animated ground enemies")
	if not actual_roaches.is_empty():
		var roach: Node3D = actual_roaches[0]
		var legs: Array[Node] = roach.visual.find_children("Leg_*", "Node3D", true, false)
		check(legs.size() == 6, "Roach model has six independently articulated legs")
		if not legs.is_empty():
			var pose_before: Transform3D = legs[0].transform
			var roach_before := roach.position
			roach.step(0.2)
			check(roach.position.distance_to(roach_before) > 0.01 and legs[0].transform != pose_before,
				"Moving roach advances its real articulated leg pose")
	# A live world tick must cause each contact outcome.
	app.world.player.position = app.world.skaters[0].position
	app.world.halted = false
	await frames(app, 3)
	check(app.world.result == "SKATED!", "Skater contact causes its own in-game collision result")
	app.retry()
	app.world.halted = true
	check(app.world.result.is_empty() and app.world.skaters[0].position == starts[0], "Retry resets skater positions and clears the collision state")
	for critter in app.world.critters:
		if critter.species == "roach":
			app.world.player.position = critter.position
			break
	app.world.halted = false
	await frames(app, 3)
	check(app.world.result == "CROAKED!", "Roach contact uses the real critter death system")
	app.retry()
	app.world.halted = true
	app.mode = "play"
	app.overlay.hide()
	app.world.halted = false
	app.toggle_map()
	var frozen: Vector3 = app.world.skaters[0].position
	var frozen_clock: float = app.world.skaters[0].clock
	await frames(app, 4)
	check(app.world.skaters[0].position == frozen and app.world.skaters[0].clock == frozen_clock,
		"Overhead map freezes skating motion and action phases")
	app.toggle_map()
	app.world.halted = true
	frozen_clock = app.world.skaters[0].clock
	await frames(app, 4)
	check(app.world.skaters[0].clock == frozen_clock, "World pause freezes skateboard action timing")
	app.world.load_level(plaza, true)
	await frames(app, 4)
	check(app.world.skaters[0].clock == 0.0, "Editor preview holds skaters at their authored start poses")
	# A known rectangular loop exercises all action transitions without a planner.
	var motion_map := fixture()
	check(Data.validate(motion_map).is_empty(), "Motion fixture follows the same imported skater format")
	app.world.load_level(motion_map, false)
	app.world.halted = true
	var skater: Node3D = app.world.skaters[0]
	var states: Dictionary = {}
	var highest := 0.0
	var grind_balance := false
	var ramp_crouch := false
	var origin := skater.position
	for _i in range(150):
		skater.step(0.1)
		states[skater.state] = true
		highest = maxf(highest, skater.height)
		if skater.state == "grind":
			grind_balance = grind_balance or absf(skater.visual.get_node("RiderRoot/ArmL").rotation.z) > 0.6
		if skater.state == "ramp":
			ramp_crouch = ramp_crouch or skater.visual.get_node("RiderRoot").position.y < -0.05
	check(states.has("push") and states.has("grind") and states.has("ramp") and states.has("cruise"),
		"A continuous authored loop actually enters push, grind, ramp and cruising states")
	check(highest >= 0.56 and skater.position.distance_to(origin) > 0.1,
		"Skating changes both ground position and elevated board contact height")
	check(grind_balance and ramp_crouch, "Grind balance arms and ramp crouching are actual distinct articulated poses")
	var rates: Array[Vector3] = []
	var heights: Array[float] = []
	for hz in [30, 60, 120]:
		app.world.load_level(motion_map, false)
		app.world.halted = true
		skater = app.world.skaters[0]
		for _i in range(hz * 6):
			skater.step(1.0 / hz)
		rates.append(skater.position)
		heights.append(skater.height)
	check(rates[0].distance_to(rates[1]) < 0.002 and rates[1].distance_to(rates[2]) < 0.002 and absf(heights[0] - heights[2]) < 0.002,
		"Skater movement and elevation agree at 30, 60 and 120 simulation steps per second")
	app.world.load_level(motion_map, false)
	app.world.halted = true
	skater = app.world.skaters[0]
	var start: Vector3 = skater.position
	check(skater.hits_player(start + Vector3(-2, 0, 0), start + Vector3(2, 0, 0)),
		"Swept frog contact detects crossing a board between endpoint poses")
	check(not skater.hits_player(start + Vector3(0, 0, 2), start + Vector3(0, 0, 2)),
		"A pedestrian outside the board envelope is clear")
	skater.step(1.2)
	var intersect: Vector3 = start + Vector3(1.8, 0, 0)
	check(skater.hits_player(intersect, intersect), "Swept skater movement detects a fast pass between endpoints")
	app.world.load_level(motion_map, false)
	app.world.halted = true
	skater = app.world.skaters[0]
	skater.step((skater.loop_length - 0.05) / skater.speed)
	var seam_before: Vector3 = skater.position
	skater.step(0.1)
	check(skater.position.distance_to(seam_before) <= skater.speed * 0.1 + 0.001,
		"Loop closing follows a continuous spatial edge without teleporting the rider")
	skater.step(10000.0)
	check(is_finite(skater.position.x) and is_finite(skater.position.z) and skater.sweeps.size() <= motion_map.objects[0].route.size() + 2,
		"A large diagnostic time skip remains finite and produces bounded collision evidence")
	await live_plaza_route(app, plaza)
	# Ordinary editor actions construct all new object types and preserve history.
	app.new_level("nyc")
	app.set_tool("roach")
	app.stroke_changed = false
	app.edit_cell(Vector2i(4, 4))
	check(app.selected_object().get("type") == "roach", "Editor places a roach enemy through the shared palette")
	app.set_tool("skater")
	app.stroke_changed = false
	app.edit_cell(Vector2i(8, 6))
	check(app.selected_object().get("type") == "skater" and Data.validate(app.level).is_empty(),
		"Editor places a valid cyclic skateboard enemy")
	app.set_tool("city_prop")
	app.stroke_changed = false
	app.edit_cell(Vector2i(12, 9))
	check(app.selected_object().get("type") == "city_prop", "Editor places a city prop through the shared palette")
	app.undo()
	check(not app.level.objects.any(func(obj): return obj.type == "city_prop"), "Undo removes the newly placed city prop")
	print("STREETLIFE INTEGRATION: %d checks, %d failures" % [checks, failures.size()])

func safe_step(world: Node3D, target: Vector3) -> bool:
	var origin: Vector3 = world.player.position
	var duration := origin.distance_to(target) / 4.2
	var count := maxi(1, ceili(duration * 60.0))
	for enemy in world.skaters:
		for index in range(count):
			var a_time := duration * index / count
			var b_time := duration * (index + 1) / count
			var a: Vector3 = enemy.sample_at_distance(enemy.distance + enemy.speed * a_time).position
			var b: Vector3 = enemy.sample_at_distance(enemy.distance + enemy.speed * b_time).position
			if minf(a.y, b.y) > 0.78:
				continue
			var frog_a := origin.lerp(target, float(index) / count)
			var frog_b := origin.lerp(target, float(index + 1) / count)
			var relative_a := Vector2(frog_a.x - a.x, frog_a.z - a.z)
			var relative_b := Vector2(frog_b.x - b.x, frog_b.z - b.z)
			if Geometry2D.get_closest_point_to_segment(Vector2.ZERO, relative_a, relative_b).length() < 0.90:
				return false
	for roach in world.critters:
		var nearest := Geometry3D.get_closest_point_to_segment(roach.position, origin, target)
		if nearest.distance_to(roach.position) < 0.85 + roach.speed * duration:
			return false
	return true

func live_plaza_route(app: Control, plaza: Dictionary) -> void:
	var path := Data.find_route(plaza)
	check(not path.is_empty(), "Live skate-plaza traversal has a complete physical route")
	app.level = plaza.duplicate(true)
	app.mode = "test"
	app.overlay.hide()
	app.world.load_level(app.level, false)
	await frames(app)
	var traversed := true
	var waited := 0
	for cell in path:
		var target: Vector3 = app.world.cell_position([cell.x, cell.y])
		var ready := false
		for _attempt in range(600):
			if not app.world.result.is_empty():
				break
			if safe_step(app.world, target):
				ready = true
				break
			waited += 1
			await app.get_tree().physics_frame
		if not ready:
			traversed = false
			break
		var arrived := false
		for _step in range(120):
			if app.world.result == "LEVEL COMPLETE!":
				arrived = true
				break
			if not app.world.result.is_empty():
				break
			var offset: Vector3 = target - app.world.player.position
			if offset.length() <= 0.08:
				arrived = true
				break
			app.world.input_vector = Vector2(offset.x, offset.z).normalized()
			await app.get_tree().physics_frame
		app.world.input_vector = Vector2.ZERO
		if not arrived:
			traversed = false
			break
	check(traversed and app.world.result == "LEVEL COMPLETE!", "Frog reaches the plaza exit with skaters and roaches active")
	print("STREETLIFE ROUTE: %.2fs simulated, %.2fs waiting, result=%s" % [app.world.elapsed, waited / 60.0, app.world.result])
