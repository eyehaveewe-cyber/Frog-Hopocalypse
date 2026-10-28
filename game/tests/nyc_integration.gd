extends RefCounted
## Supplements the original editor/physics suite; uses actual world traffic.
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

func frame(app: Control, count: int = 2) -> void:
	for _i in range(count):
		await app.get_tree().physics_frame

func fixture() -> Dictionary:
	var map := Data.blank("Traffic test", "nyc")
	for x in range(1, map.width - 1):
		map.tiles[6][x] = "road"
	map.traffic = [{"row": 6, "direction": 1, "speed": 4.0,
		"spacing": 12.0, "offset": 0.0, "vehicles": ["taxi", "bus"]}]
	map.crossings = [8]
	return map

func run(app: Control) -> void:
	app.set_process(false)
	check(app.BUILTINS.size() >= 8, "Campaign keeps the original three maps and adds five NYC maps")
	var city_maps: Array[Dictionary] = []
	for index in range(3, 8):
		var map := Data.load_json(app.BUILTINS[index])
		check(not map.is_empty() and map.get("theme") == "nyc", "NYC campaign entry loads: " + str(index - 2))
		if map.is_empty():
			continue
		city_maps.append(map)
		var save_path := "user://nyc-%d-roundtrip.json" % index
		check(Data.save_json(save_path, map) == OK and Data.load_json(save_path) == map,
			"NYC traffic and road data survive JSON round trip: " + map.name)
	check(city_maps.size() == 5, "All five new maps are registered as regular campaign levels")
	if city_maps.size() != 5:
		return
	var valid := fixture()
	check(Data.validate(valid).is_empty(), "NYC road and traffic fixture passes the map boundary validator")
	var invalid: Dictionary = valid.duplicate(true)
	invalid.traffic[0].direction = 0
	check(not Data.validate(invalid).is_empty(), "Traffic importer rejects an invalid lane direction")
	invalid = valid.duplicate(true)
	invalid.traffic[0].speed = -1
	check(not Data.validate(invalid).is_empty(), "Traffic importer rejects a negative lane speed")
	invalid = valid.duplicate(true)
	invalid.traffic.append(invalid.traffic[0].duplicate(true))
	check(not Data.validate(invalid).is_empty(), "Traffic importer rejects overlapping lane definitions")
	invalid = valid.duplicate(true)
	invalid.tiles[6][8] = "floor"
	check(not Data.validate(invalid).is_empty(), "Traffic importer rejects a broken road lane")
	invalid = valid.duplicate(true)
	invalid.traffic[0].vehicles = ["dragon"]
	check(not Data.validate(invalid).is_empty(), "Traffic importer rejects unknown vehicle models")
	invalid = valid.duplicate(true)
	invalid.traffic[0].spacing = 1.0
	check(not Data.validate(invalid).is_empty(), "Traffic importer rejects spacing with no safe vehicle gaps")
	invalid = valid.duplicate(true)
	invalid.crossings = [-1]
	check(not Data.validate(invalid).is_empty(), "Traffic importer rejects off-map crosswalks")
	app.level = city_maps[4].duplicate(true)
	app.world.load_level(app.level, false)
	app.world.halted = true
	await frame(app)
	var traffic: Node3D = app.world.traffic
	check(traffic.vehicles.size() >= 20, "Midtown finale simulates a substantial traffic ensemble")
	var kinds: Dictionary = {}
	var start: Array[Vector3] = []
	for vehicle in traffic.vehicles:
		kinds[vehicle.kind] = true
		start.append(vehicle.node.position)
	check(kinds.size() == 4, "Midtown traffic includes taxis, sedans, buses and delivery trucks")
	var all_wheels_present := true
	for vehicle in traffic.vehicles:
		for pivot_name in ["Wheel_Front_Left", "Wheel_Front_Right", "Wheel_Rear_Left", "Wheel_Rear_Right"]:
			all_wheels_present = all_wheels_present and vehicle.node.has_node(pivot_name)
	check(all_wheels_present, "Every traffic vehicle has four named mechanical wheel pivots")
	var wheel: Node3D = traffic.vehicles[0].node.get_node("Wheel_Front_Left")
	var wheel_angle_before := wheel.rotation.z
	traffic.step(0.1)
	var wheel_angle_after := wheel.rotation.z
	check(absf(wheel_angle_after - wheel_angle_before) > 0.01, "Traffic travel actually rotates mechanical wheel pivots")
	print("NYC WHEEL: first vehicle %s, delta=0.100s, z angle %.6f -> %.6f radians" % [traffic.vehicles[0].kind, wheel_angle_before, wheel_angle_after])
	var positive := false
	var negative := false
	for index in range(traffic.vehicles.size()):
		var difference: float = traffic.vehicles[index].node.position.x - start[index].x
		if absf(difference) < 2.0:
			positive = positive or difference > 0.05
			negative = negative or difference < -0.05
	check(positive and negative, "Opposing traffic lanes actually move in both directions")
	app.world.halted = false
	app.mode = "play"
	app.overlay.hide()
	app.toggle_map()
	var frozen_clock: float = traffic.clock
	var frozen_position: Vector3 = traffic.vehicles[0].node.position
	await frame(app, 4)
	check(traffic.clock == frozen_clock and traffic.vehicles[0].node.position == frozen_position,
		"Overhead map freezes traffic simulation and vehicle poses")
	app.toggle_map()
	app.world.halted = true
	frozen_clock = traffic.clock
	await frame(app, 4)
	check(traffic.clock == frozen_clock, "World pause freezes traffic simulation")
	app.retry()
	app.world.halted = true
	check(app.world.traffic.clock == 0.0 and app.world.traffic.vehicles[0].node.position == start[0],
		"Retry restores deterministic initial traffic phase")
	# A real world tick, rather than a direct result assignment, must detect impact.
	var first: Dictionary = app.world.traffic.vehicles[0]
	for vehicle in app.world.traffic.vehicles:
		if absf(vehicle.node.position.x) < 5.0:
			first = vehicle
			break
	app.world.player.position = first.node.position
	app.world.player.position.y = 0
	app.world.halted = false
	await frame(app, 3)
	check(app.world.result == "FLATTENED!", "Physical contact with moving traffic causes a traffic death")
	app.retry()
	app.world.halted = true
	check(app.world.result.is_empty(), "Traffic death can retry into a fresh playable world")
	app.level = fixture()
	app.world.load_level(app.level, false)
	app.world.halted = true
	traffic = app.world.traffic
	first = traffic.vehicles[0]
	var center: Vector3 = first.node.position
	check(traffic.hits_player(center + Vector3(0, 0, -3), center + Vector3(0, 0, 3)),
		"Swept frog collision catches a crossing through a vehicle between frames")
	check(not traffic.hits_player(center + Vector3(0, 0, -2), center + Vector3(0, 0, -2)),
		"Traffic collision leaves adjacent safe sidewalk space clear")
	traffic.vehicles.resize(1)
	first.node.position.x = -3.0
	traffic.step(1.5)
	var stationary := Vector3(0, 0, first.node.position.z)
	check(traffic.hits_player(stationary, stationary), "Fast vehicle sweep catches impact between endpoint poses")
	first.node.position.x = traffic.left + traffic.span - 0.02
	traffic.step(0.01)
	check(first.wrapped and not traffic.hits_player(stationary, stationary),
		"Looping traffic does not create a phantom collision across the road")
	var reentry: Vector3 = first.node.position
	check(traffic.hits_player(reentry, reentry), "Wrapped vehicle collision remains active at lane re-entry")
	app.world.load_level(app.level, true)
	await frame(app)
	frozen_clock = app.world.traffic.clock
	await frame(app, 4)
	check(app.world.traffic.clock == frozen_clock, "Editor preview keeps traffic stationary")
	# Cross one complete road row with real movement and the hazard system active.
	# A generous deterministic lane gap permits success without disabling vehicles.
	app.level = fixture()
	app.world.load_level(app.level, false)
	app.world.halted = true
	var crossing_x := -1
	for x in range(2, 15):
		var target: Vector3 = app.world.cell_position([x, 6])
		var safe := true
		for vehicle in app.world.traffic.vehicles:
			var projected_x: float = vehicle.node.position.x + 4.0 * 0.43
			if absf(projected_x - target.x) < vehicle.length * 0.5 + 1.0:
				safe = false
		if safe:
			crossing_x = x
			break
	check(crossing_x >= 0, "Traffic fixture exposes a readable crossing gap")
	if crossing_x < 0:
		return
	app.world.player.position = app.world.cell_position([crossing_x, 7])
	app.world.halted = false
	app.world.input_vector = Vector2(0, -1)
	var cleared := false
	for _i in range(75):
		await app.get_tree().physics_frame
		if not app.world.result.is_empty():
			break
		if app.world.player.position.z <= app.world.cell_position([crossing_x, 5]).z + 0.1:
			cleared = true
			break
	app.world.input_vector = Vector2.ZERO
	check(cleared and app.world.result.is_empty(), "Frog crosses a live road lane through its timing gap")
	print("NYC INTEGRATION: %d checks, %d failures" % [checks, failures.size()])
