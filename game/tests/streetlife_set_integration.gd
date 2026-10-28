extends RefCounted
## Six-map campaign checks and real-input live traversal with all hazards active.
const Data = preload("res://scripts/level_data.gd")
const Props = preload("res://scripts/streetlife_specs.gd")
const SPEED := 4.2
const STEP := 1.0 / 60.0
var checks := 0
var failures: Array[String] = []
var summaries: Array[Dictionary] = []

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures.append(description)
		push_error("FAIL: " + description)

func patrol_cells(map: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for obj in map.objects:
		if obj.type not in ["critter", "roach"]:
			continue
		var points: Array = [obj.pos] + obj.get("waypoints", [])
		for a in points:
			for b in points:
				for y in range(mini(int(a[1]), int(b[1])), maxi(int(a[1]), int(b[1])) + 1):
					for x in range(mini(int(a[0]), int(b[0])), maxi(int(a[0]), int(b[0])) + 1):
						result[Vector2i(x, y)] = true
	return result

func planned_route(map: Dictionary) -> Array[Vector2i]:
	var start := Vector2i(map.spawn[0], map.spawn[1])
	var goal := Vector2i(map.exit[0], map.exit[1])
	var blocked: Dictionary = {}
	for obj in map.objects:
		if obj.type == "city_prop" and obj.get("solid", false):
			for y in range(int(map.height)):
				for x in range(int(map.width)):
					if Props.covers(obj, Vector2(x, y)):
						blocked[Vector2i(x, y)] = true
		elif obj.type in ["pillar", "tree", "emitter"] or obj.get("solid", false):
			blocked[Vector2i(int(obj.pos[0]), int(obj.pos[1]))] = true
	var patrol := patrol_cells(map)
	var pending: Array[Vector2i] = [start]
	var previous: Dictionary = {start: start}
	var costs: Dictionary = {start: 0}
	while not pending.is_empty():
		var nearest := 0
		for i in range(1, pending.size()):
			if costs[pending[i]] < costs[pending[nearest]]:
				nearest = i
		var p: Vector2i = pending[nearest]
		pending.remove_at(nearest)
		if p == goal:
			var result: Array[Vector2i] = []
			while p != start:
				result.push_front(p)
				p = previous[p]
			return result
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var q: Vector2i = p + offset
			if q.x < 0 or q.y < 0 or q.x >= map.width or q.y >= map.height or blocked.has(q):
				continue
			if map.tiles[q.y][q.x] in ["wall", "water"]:
				continue
			# Commit straight across an avenue; never wait in its opposite lane.
			if offset.x != 0 and (map.tiles[q.y][q.x] == "road" or map.tiles[p.y][p.x] == "road"):
				continue
			var cost: int = costs[p] + (12 if patrol.has(q) else 1)
			if not costs.has(q) or cost < costs[q]:
				costs[q] = cost
				previous[q] = p
				if not pending.has(q):
					pending.append(q)
	return []

static func box_hit(a: Vector2, b: Vector2, half: Vector2) -> bool:
	var low := 0.0
	var high := 1.0
	var direction := b - a
	for axis in range(2):
		if absf(direction[axis]) < 0.000001:
			if absf(a[axis]) > half[axis]:
				return false
		else:
			var first := (-half[axis] - a[axis]) / direction[axis]
			var last := (half[axis] - a[axis]) / direction[axis]
			low = maxf(low, minf(first, last))
			high = minf(high, maxf(first, last))
			if low > high:
				return false
	return true

func safe_move(world: Node3D, targets: Array[Vector3]) -> bool:
	var elapsed := 0.0
	var origin: Vector3 = world.player.position
	for target in targets:
		var duration := origin.distance_to(target) / SPEED
		var count := maxi(1, ceili(duration * 60.0))
		for rider in world.skaters:
			for sample in range(count):
				var t0 := elapsed + duration * sample / count
				var t1 := elapsed + duration * (sample + 1) / count
				var a: Vector3 = rider.sample_at_distance(rider.distance + rider.speed * t0).position
				var b: Vector3 = rider.sample_at_distance(rider.distance + rider.speed * t1).position
				if minf(a.y, b.y) > 0.78:
					continue
				var frog_a := origin.lerp(target, float(sample) / count)
				var frog_b := origin.lerp(target, float(sample + 1) / count)
				var relative_a := Vector2(frog_a.x - a.x, frog_a.z - a.z)
				var relative_b := Vector2(frog_b.x - b.x, frog_b.z - b.z)
				if Geometry2D.get_closest_point_to_segment(Vector2.ZERO, relative_a, relative_b).length() < 0.88:
					return false
		for vehicle in world.traffic.vehicles:
			var lane: Dictionary = world.traffic.lanes[vehicle.lane]
			var velocity := Vector3(float(lane.speed) * float(lane.direction), 0, 0)
			var half := Vector2(float(vehicle.length) * 0.5 + 0.42, 0.55 + 0.42)
			for copy in [-1, 0, 1]:
				var a: Vector3 = vehicle.node.position + Vector3(copy * world.traffic.span, 0, 0) + velocity * elapsed
				var b: Vector3 = a + velocity * duration
				if box_hit(Vector2(origin.x - a.x, origin.z - a.z), Vector2(target.x - b.x, target.z - b.z), half):
					return false
		for critter in world.critters:
			var nearest := Geometry3D.get_closest_point_to_segment(critter.position, origin, target)
			# A distance bound remains safe when a short patrol turns mid-crossing.
			if nearest.distance_to(critter.position) < 0.83 + critter.speed * (elapsed + duration):
				return false
		elapsed += duration
		origin = target
	return true

func move_to(app: Control, target: Vector3) -> bool:
	var world: Node3D = app.world
	var budget := ceili(world.player.position.distance_to(target) / SPEED / STEP) + 30
	for _step in range(budget):
		if world.result == "LEVEL COMPLETE!":
			world.input_vector = Vector2.ZERO
			return true
		if not world.result.is_empty():
			world.input_vector = Vector2.ZERO
			return false
		var offset: Vector3 = target - world.player.position
		if offset.length() <= 0.08:
			world.input_vector = Vector2.ZERO
			return true
		world.input_vector = Vector2(offset.x, offset.z).normalized()
		await app.get_tree().physics_frame
	world.input_vector = Vector2.ZERO
	return false

func dry_route(app: Control, map: Dictionary) -> bool:
	app.world.load_level(map, true)
	await app.get_tree().physics_frame
	await app.get_tree().physics_frame
	for cell in Data.find_route(map):
		var target: Vector3 = app.world.cell_position([cell.x, cell.y])
		var arrived := false
		for _step in range(100):
			var offset: Vector3 = target - app.world.player.position
			if offset.length() <= 0.08:
				arrived = true
				break
			app.world.player.step(STEP, Vector2(offset.x, offset.z).normalized())
			await app.get_tree().physics_frame
		if not arrived:
			return false
	return app.world.player.position.distance_to(app.world.cell_position(map.exit)) < 0.15

func live_route(app: Control, map: Dictionary) -> bool:
	var path := planned_route(map)
	check(not path.is_empty(), "Set live route has a complete sidewalk plan: " + map.name)
	if path.is_empty():
		return false
	app.level = map.duplicate(true)
	app.mode = "test"
	app.overlay.hide()
	app.world.load_level(app.level, false)
	await app.get_tree().physics_frame
	await app.get_tree().physics_frame
	var patrol := patrol_cells(map)
	var cursor := 0
	var waited := 0
	var crossed_bands := 0
	var arrived := true
	while cursor < path.size():
		var targets: Array[Vector3] = []
		var cell: Vector2i = path[cursor]
		var on_road: bool = map.tiles[cell.y][cell.x] == "road"
		if on_road:
			while cursor < path.size() - 1 and map.tiles[path[cursor].y][path[cursor].x] == "road":
				cursor += 1
			cell = path[cursor]
			crossed_bands += 1
			targets.append(app.world.cell_position([cell.x, cell.y]))
		elif patrol.has(cell):
			# Commit beyond the patrol's swept row instead of stopping on it and
			# being caught while waiting for the following grid step.
			var first := cursor
			while cursor < path.size() - 1 and patrol.has(path[cursor]):
				cursor += 1
			cell = path[cursor]
			for i in range(first, cursor + 1):
				targets.append(app.world.cell_position([path[i].x, path[i].y]))
		else:
			targets.append(app.world.cell_position([cell.x, cell.y]))
		var clear := false
		for _attempt in range(1800):
			if not app.world.result.is_empty():
				break
			if safe_move(app.world, targets):
				clear = true
				break
			waited += 1
			await app.get_tree().physics_frame
		if not clear:
			print("SET ROUTE BLOCKED: cell=%s frog=%s targets=%s result=%s" % [cell, app.world.player.position, targets, app.world.result])
			for enemy in app.world.critters:
				print("SET NEARBY ROACH: %s at %s direction %s" % [enemy.name, enemy.position, enemy.direction])
			arrived = false
			break
		for target in targets:
			if not await move_to(app, target):
				print("SET ROUTE MOVE FAILED: cell=%s frog=%s target=%s result=%s" % [cell, app.world.player.position, target, app.world.result])
				arrived = false
				break
		if not arrived:
			break
		cursor += 1
	app.world.input_vector = Vector2.ZERO
	var completed: bool = arrived and app.world.result == "LEVEL COMPLETE!"
	summaries.append({"index": map.set_index, "name": map.name, "seconds": app.world.elapsed, "waiting": waited * STEP, "bands": crossed_bands, "result": app.world.result})
	print("SET ROUTE: %s, %.2fs simulated, %.2fs waiting, %d traffic bands, result=%s" % [map.name, app.world.elapsed, waited * STEP, crossed_bands, app.world.result])
	return completed

func visible_buttons(app: Control) -> Array[String]:
	var result: Array[String] = []
	for child in app.find_children("*", "Button", true, false):
		if child.is_visible_in_tree() and app.overlay.is_ancestor_of(child):
			result.append(child.text)
	return result

func run(app: Control) -> void:
	app.set_process(false)
	var maps: Array[Dictionary] = []
	var indices: Array[int] = []
	for index in range(app.BUILTINS.size()):
		var map := Data.load_json(app.BUILTINS[index])
		if map.get("level_set") == "nyc_streetlife":
			maps.append(map)
			indices.append(index)
	check(maps.size() == 6, "NYC Streetlife is a distinct six-level set alongside the previous campaign")
	if maps.size() != 6:
		return
	var identities: Dictionary = {}
	var prop_kinds: Dictionary = {}
	var rider_variants: Dictionary = {}
	var tricks: Dictionary = {}
	for index in range(maps.size()):
		var map: Dictionary = maps[index]
		check(map.set_index == index + 1, "Streetlife set has ordered metadata for level %d" % (index + 1))
		check(Data.reachable(map), "Set level has a dry route: " + map.name)
		var save_path := "user://streetlife-set-%d.json" % (index + 1)
		check(Data.save_json(save_path, map) == OK and Data.load_json(save_path) == map, "Set level preserves authored assets and hazards in JSON: " + map.name)
		identities[JSON.stringify(map.tiles) + JSON.stringify(map.spawn) + JSON.stringify(map.exit)] = true
		for obj in map.objects:
			if obj.type == "city_prop":
				prop_kinds[obj.variant] = true
			elif obj.type == "skater":
				rider_variants[obj.variant] = true
				for point in obj.route:
					tricks[point.get("trick", "cruise")] = true
		check(await dry_route(app, map), "Real frog physically traverses the set layout with hazards paused: " + map.name)
		check(await live_route(app, map), "Frog reaches set exit with all authored hazards active: " + map.name)
	check(identities.size() == 6, "All six set levels have distinct terrain and entry/exit geometry")
	check(prop_kinds.size() >= 10 and rider_variants.size() == 3 and tricks.has("grind") and tricks.has("ramp"), "The set exercises the complete new prop, rider, grind and ramp kit")
	# Trigger genuine result handling, then invoke the actual next/replay buttons.
	for offset in range(maps.size()):
		app.load_builtin(indices[offset])
		app.mode = "play"
		app.slot_id = ""
		app.world.finish("LEVEL COMPLETE!")
		await app.get_tree().process_frame
		var labels := visible_buttons(app)
		if offset < maps.size() - 1:
			check("Next level →" in labels, "Set victory offers its next level: %d" % (offset + 1))
			for button in app.find_children("*", "Button", true, false):
				if button.text == "Next level →" and button.is_visible_in_tree():
					button.pressed.emit()
					break
			check(app.level.get("level_set") == "nyc_streetlife" and app.level.set_index == offset + 2, "Next level launches the following set map: %d" % (offset + 2))
		else:
			check(not "Next level →" in labels and labels.any(func(label): return "Replay NYC Streetlife" in label), "Sixth level completes the set and offers replay instead of leaving the set")
			for button in app.find_children("*", "Button", true, false):
				if button.text == "Replay NYC Streetlife" and button.is_visible_in_tree():
					button.pressed.emit()
					break
			check(app.level.get("level_set") == "nyc_streetlife" and app.level.set_index == 1 and app.mode == "play", "Set replay restarts level one through its real menu action")
	# Completing the prior campaign must not silently start this separate set.
	app.load_builtin(indices[0] - 1)
	app.mode = "play"
	app.slot_id = ""
	app.world.finish("LEVEL COMPLETE!")
	await app.get_tree().process_frame
	check(not "Next level →" in visible_buttons(app), "Previous campaign completion stays separate from the new six-level set")
	print("STREETLIFE SET: %d checks, %d failures" % [checks, failures.size()])
