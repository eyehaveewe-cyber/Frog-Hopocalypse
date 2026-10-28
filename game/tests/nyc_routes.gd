extends RefCounted
## Full live-traffic campaign traversals. Only ordinary player input moves the frog.
const Data = preload("res://scripts/level_data.gd")
const SPEED := 4.2
const STEP := 1.0 / 60.0
var checks := 0
var failures: Array[String] = []

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures.append(description)
		push_error("FAIL: " + description)

func patrol_cells(map: Dictionary) -> Dictionary:
	var cells: Dictionary = {}
	for obj in map.objects:
		if obj.type in ["critter", "roach"]:
			var points: Array = [obj.pos] + obj.get("waypoints", [])
			for a in points:
				for b in points:
					for y in range(mini(int(a[1]), int(b[1])), maxi(int(a[1]), int(b[1])) + 1):
						for x in range(mini(int(a[0]), int(b[0])), maxi(int(a[0]), int(b[0])) + 1):
							cells[Vector2i(x, y)] = true
	return cells

func route(map: Dictionary) -> Array[Vector2i]:
	var start := Vector2i(map.spawn[0], map.spawn[1])
	var goal := Vector2i(map.exit[0], map.exit[1])
	var blocked: Dictionary = {}
	for obj in map.objects:
		if obj.type in ["pillar", "tree", "emitter"] or obj.get("solid", false):
			blocked[Vector2i(obj.pos[0], obj.pos[1])] = true
	var patrol := patrol_cells(map)
	var queue: Array[Vector2i] = [start]
	var previous: Dictionary = {start: start}
	var distances: Dictionary = {start: 0}
	while not queue.is_empty():
		var nearest := 0
		for i in range(1, queue.size()):
			if distances[queue[i]] < distances[queue[nearest]]:
				nearest = i
		var p: Vector2i = queue[nearest]
		queue.remove_at(nearest)
		if p == goal:
			var result: Array[Vector2i] = []
			while p != start:
				result.push_front(p)
				p = previous[p]
			return result
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = p + offset
			if n.x < 0 or n.y < 0 or n.x >= map.width or n.y >= map.height or blocked.has(n):
				continue
			if map.tiles[n.y][n.x] in ["wall", "water"]:
				continue
			# Walk laterally on sidewalks, then commit to a straight avenue crossing.
			if offset.x != 0 and (map.tiles[p.y][p.x] == "road" or map.tiles[n.y][n.x] == "road"):
				continue
			var cost: int = distances[p] + (20 if patrol.has(n) else 1)
			if not distances.has(n) or cost < distances[n]:
				distances[n] = cost
				previous[n] = p
				if not queue.has(n):
					queue.append(n)
	return []

func critters_clear(world: Node3D, targets: Array[Vector3]) -> bool:
	var total := 0.0
	var from: Vector3 = world.player.position
	for target in targets:
		total += from.distance_to(target) / SPEED
		from = target
	for critter in world.critters:
		from = world.player.position
		for target in targets:
			var closest := Geometry3D.get_closest_point_to_segment(critter.position, from, target)
			# A speed bound remains safe even if the patrol reverses at a waypoint.
			if closest.distance_to(critter.position) <= 0.85 + float(critter.speed) * total:
				return false
			from = target
	return true

func crossing_clear(world: Node3D, target: Vector3) -> bool:
	var origin: Vector3 = world.player.position
	var duration := origin.distance_to(target) / SPEED
	for vehicle in world.traffic.vehicles:
		var lane: Dictionary = world.traffic.lanes[vehicle.lane]
		var velocity := Vector3(float(lane.speed) * float(lane.direction), 0, 0)
		# Test continuous relative motion, including copies across the loop seam.
		# The 0.10 margin permits ordinary input/physics-frame rounding.
		var half := Vector2(float(vehicle.length) * 0.5 + 0.42, 0.55 + 0.42)
		for copy in [-1, 0, 1]:
			var start: Vector3 = vehicle.node.position + Vector3(copy * world.traffic.span, 0, 0)
			var relative_start := Vector2(origin.x - start.x, origin.z - start.z)
			var relative_end := Vector2(target.x - start.x - velocity.x * duration, target.z - start.z)
			if intersects_box(relative_start, relative_end, half):
				return false
	return true

func intersects_box(origin: Vector2, target: Vector2, half: Vector2) -> bool:
	var direction := target - origin
	var low := 0.0
	var high := 1.0
	for axis in range(2):
		if absf(direction[axis]) < 0.00001:
			if absf(origin[axis]) > half[axis]:
				return false
		else:
			var first := (-half[axis] - origin[axis]) / direction[axis]
			var last := (half[axis] - origin[axis]) / direction[axis]
			low = maxf(low, minf(first, last))
			high = minf(high, maxf(first, last))
			if low > high:
				return false
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

func run(app: Control) -> void:
	app.set_process(false)
	for index in range(3, 8):
		var map := Data.load_json(app.BUILTINS[index])
		var path := route(map)
		var patrol := patrol_cells(map)
		check(not path.is_empty(), "Live traversal has a safe-sidewalk route: " + map.name)
		if path.is_empty():
			continue
		app.level = map
		app.mode = "test"
		app.world.load_level(map, false)
		app.overlay.hide()
		await app.get_tree().physics_frame
		await app.get_tree().physics_frame
		var cursor := 0
		var traversed := true
		var bands_crossed := 0
		var waited_frames := 0
		while cursor < path.size():
			var cell: Vector2i = path[cursor]
			var is_road: bool = map.tiles[cell.y][cell.x] == "road"
			var near_patrol := patrol.has(cell)
			var segment_start := cursor
			if is_road:
				# Include the first dry cell beyond the entire avenue pair. Never
				# wait between adjacent lanes where the car envelope can reach us.
				while cursor < path.size() - 1 and map.tiles[path[cursor].y][path[cursor].x] == "road":
					cursor += 1
				cell = path[cursor]
			elif near_patrol:
				while cursor < path.size() - 1 and patrol.has(path[cursor]):
					cursor += 1
				cell = path[cursor]
			var target: Vector3 = app.world.cell_position([cell.x, cell.y])
			var targets: Array[Vector3] = []
			if is_road:
				targets.append(target)
			else:
				for i in range(segment_start, cursor + 1):
					targets.append(app.world.cell_position([path[i].x, path[i].y]))
			if is_road or near_patrol:
				var clear := false
				for _wait in range(1800):
					if (not is_road or crossing_clear(app.world, target)) and critters_clear(app.world, targets):
						clear = true
						break
					waited_frames += 1
					await app.get_tree().physics_frame
					if not app.world.result.is_empty():
						break
				if not clear:
					traversed = false
					break
				if is_road:
					bands_crossed += 1
			for point in targets:
				if not await move_to(app, point):
					traversed = false
					break
			if not traversed:
				break
			cursor += 1
		app.world.input_vector = Vector2.ZERO
		check(traversed and app.world.result == "LEVEL COMPLETE!",
			"Full route reaches the exit with traffic and AI active: " + map.name)
		check(bands_crossed > 0 and app.world.traffic.clock > 0,
			"Live traversal crossed avenue bands without stopping traffic: " + map.name)
		print("NYC ROUTE: %s, %d bands, %.2fs waiting, %.2fs simulated, result=%s" % [map.name, bands_crossed, waited_frames * STEP, app.world.elapsed, app.world.result])
	print("NYC ROUTES: %d checks, %d failures" % [checks, failures.size()])
