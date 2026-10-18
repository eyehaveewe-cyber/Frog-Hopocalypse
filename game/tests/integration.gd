extends RefCounted
## Invoked only by --integration-test. Tests drive the real editor and physics world.
var failures: Array[String] = []
var checks := 0

func check(condition: bool, text: String) -> void:
	checks += 1
	if not condition:
		failures.append(text)
		push_error("FAIL: " + text)
	else:
		print("PASS: " + text)

func run(app: Control) -> void:
	await app.get_tree().process_frame
	var Data = preload("res://scripts/level_data.gd")
	for path in app.BUILTINS:
		var map := Data.load_json(path)
		check(not map.is_empty(), "Bundled JSON validates: " + path)
		if not map.is_empty():
			check(Data.reachable(map), "Exit has a dry, unblocked route: " + map.name)
	app.new_level()
	app.set_tool("wall")
	app.stroke_changed = false
	app.edit_cell(Vector2i(3, 3))
	check(app.level.tiles[3][3] == "wall", "Editor paints a wall")
	app.undo()
	check(app.level.tiles[3][3] == "floor", "Undo restores terrain")
	app.redo()
	check(app.level.tiles[3][3] == "wall", "Redo restores wall")
	app.set_tool("critter")
	app.stroke_changed = false
	app.edit_cell(Vector2i(6, 6))
	app.change_property("behavior", "patrol")
	app.set_tool("route")
	app.edit_cell(Vector2i(8, 6))
	app.edit_cell(Vector2i(8, 8))
	check(app.selected_object().waypoints.size() == 2, "Editor records patrol waypoints")
	app.set_tool("emitter")
	app.stroke_changed = false
	app.edit_cell(Vector2i(10, 6))
	app.change_property("interval", 1.25)
	app.change_property("rotation", 270)
	var draft: Dictionary = app.level.duplicate(true)
	check(Data.validate(draft) == "", "Authored map validates")
	check(Data.save_json("user://test-roundtrip.json", draft) == OK, "Map JSON writes successfully")
	var reread := Data.load_json("user://test-roundtrip.json")
	check(reread == Data.normalize(draft), "JSON round trip preserves terrain, objects and properties")
	app.save_level()
	var original_slot: String = app.slot_id
	app.duplicate_level()
	check(app.slot_id != original_slot and app.library.size() >= 2, "Duplicate creates an independent local save")
	var saved_count: int = app.library.size()
	app.library.clear()
	app.load_library()
	check(app.library.size() == saved_count, "Local save library reloads from disk")
	app.level = draft.duplicate(true)
	app.sync_editor()
	app.start_play(true)
	await app.get_tree().physics_frame
	await app.get_tree().physics_frame
	check(app.world.critters.size() == 1 and app.world.emitters.size() == 1, "Playtest instantiates authored AI and trap")
	check(app.world.camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "Gameplay uses the perspective frog camera")
	app.toggle_map()
	var map_time: float = app.world.elapsed
	var map_position: Vector3 = app.world.player.position
	await app.get_tree().physics_frame
	await app.get_tree().physics_frame
	check(app.world.map_view and app.world.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Map inspection uses the preserved overhead camera")
	check(app.world.elapsed == map_time and app.world.player.position == map_position, "Map inspection pauses simulation without moving the frog")
	app.toggle_map()
	check(not app.world.map_view and app.world.camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "Leaving the map restores perspective gameplay")
	app.enter_editor()
	check(app.world.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "The editor retains its overhead construction view")
	check(app.level == draft, "Returning from playtest preserves all edits")
	# Circle-vs-solid collision, driven for enough frames to reach the wall.
	app.level = Data.blank("Physics test")
	app.level.tiles[10][1] = "wall"
	app.sync_editor()
	app.start_play(true)
	app.set_process(false)
	app.world.input_vector = Vector2(0, -1)
	for _i in range(55):
		await app.get_tree().physics_frame
	var barrier: Vector3 = app.world.cell_position([1, 10])
	check(app.world.player.position.z > barrier.z + 1.1, "Frog cannot move through a solid wall")
	app.world.input_vector = Vector2.ZERO
	app.level = Data.blank("Hazard test")
	app.level.tiles[5][5] = "water"
	app.world.load_level(app.level, false)
	await app.get_tree().physics_frame
	app.world.player.position = app.world.cell_position([5, 5])
	await app.get_tree().physics_frame
	check(app.world.result == "SPLASHED!", "Water triggers splash death")
	app.retry()
	check(app.world.result == "" and app.world.projectiles.is_empty(), "Retry resets death and projectiles")
	app.world.player.position = app.world.cell_position(app.level.exit)
	await app.get_tree().physics_frame
	await app.get_tree().physics_frame
	check(app.world.result == "LEVEL COMPLETE!", "Exit triggers victory")
	app.level = Data.blank("Critter test")
	app.level.objects.append({"id": "bug", "type": "critter", "pos": [5, 5], "behavior": "wander", "waypoints": [], "speed": 1.6})
	app.world.load_level(app.level, false)
	await app.get_tree().physics_frame
	app.world.player.position = app.world.critters[0].position
	await app.get_tree().physics_frame
	check(app.world.result == "CROAKED!", "Critter contact causes immediate death")
	app.level = Data.blank("Projectile test")
	app.world.load_level(app.level, false)
	await app.get_tree().physics_frame
	app.world.spawn_projectile(app.world.player.position + Vector3(0, 0.36, -0.2), Vector3.BACK)
	await app.get_tree().physics_frame
	check(app.world.result == "HIT!", "Projectile contact causes hit death")
	app.level.tiles[5][5] = "wall"
	app.world.load_level(app.level, false)
	await app.get_tree().physics_frame
	await app.get_tree().physics_frame
	app.world.spawn_projectile(app.world.cell_position([5, 6]) + Vector3(0, 0.4, 0), Vector3.FORWARD)
	for _i in range(18):
		await app.get_tree().physics_frame
	check(app.world.projectiles.is_empty(), "Dart is destroyed by world geometry")
	# Reject malformed/untrusted maps without replacing the current document.
	var before: Dictionary = app.level.duplicate(true)
	check(not app.import_text('{"version":999}'), "Unsupported map versions are rejected")
	check(not app.import_text('{"version":true}'), "Malformed version types are rejected safely")
	check(app.level == before, "Rejected import leaves current map intact")
	app.level = Data.blank("Twenty critters")
	for i in range(20):
		app.level.objects.append({"id": "bug%d" % i, "type": "critter", "pos": [4 + i % 10, 2 + i / 10], "behavior": "wander", "speed": 1.6, "waypoints": []})
	app.world.load_level(app.level, false)
	for _i in range(30):
		await app.get_tree().physics_frame
	check(app.world.critters.size() == 20 and app.world.elapsed > 0, "Twenty critters simulate in the shared runtime")
	var bug_before: Vector3 = app.world.critters[0].position
	for _i in range(20):
		await app.get_tree().physics_frame
	check(app.world.critters[0].position.distance_to(bug_before) > 0.1, "Wandering critters actually move independently")
	for path in app.BUILTINS:
		var demo := Data.load_json(path)
		app.level = demo
		app.world.load_level(demo, true)
		await app.get_tree().physics_frame
		await app.get_tree().physics_frame
		var route := physical_route(demo)
		var traversed := true
		for cell in route:
			var target: Vector3 = app.world.cell_position([cell.x, cell.y])
			var steps := 0
			while app.world.player.position.distance_to(target) > 0.08 and steps < 100:
				var offset: Vector3 = target - app.world.player.position
				app.world.player.step(1.0 / 60, Vector2(offset.x, offset.z).normalized())
				steps += 1
				await app.get_tree().physics_frame
			if steps == 100:
				traversed = false
				break
		check(traversed and app.world.player.position.distance_to(app.world.cell_position(demo.exit)) < 0.15, "Full dry route physically traversable with hazards paused: " + demo.name)
	app.set_process(true)
	print("INTEGRATION: %d checks, %d failures" % [checks, failures.size()])
	app.get_tree().quit(0 if failures.is_empty() else 1)

func physical_route(demo: Dictionary) -> Array[Vector2i]:
	var start := Vector2i(demo.spawn[0], demo.spawn[1])
	var goal := Vector2i(demo.exit[0], demo.exit[1])
	var blocked: Dictionary = {}
	for obj in demo.objects:
		if obj.type in ["pillar", "tree", "emitter"] or obj.get("solid", false):
			blocked[Vector2i(obj.pos[0], obj.pos[1])] = true
	var queue: Array[Vector2i] = [start]
	var previous: Dictionary = {start: start}
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		if p == goal:
			var route: Array[Vector2i] = []
			while p != start:
				route.push_front(p)
				p = previous[p]
			return route
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = p + offset
			if n.x < 0 or n.y < 0 or n.x >= demo.width or n.y >= demo.height or previous.has(n) or blocked.has(n):
				continue
			if demo.tiles[n.y][n.x] in ["wall", "water"]:
				continue
			previous[n] = p
			queue.append(n)
	return []
