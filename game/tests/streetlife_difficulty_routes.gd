extends SceneTree
## Full live-traffic campaign traversals. Only ordinary player input moves the frog.
const Data = preload("res://scripts/level_data.gd")
const Props = preload("res://scripts/streetlife_specs.gd")
const SPEED := 4.2
const STEP := 1.0 / 60.0
var checks := 0
var naive := "--naive" in OS.get_cmdline_user_args()
var baseline := "--baseline" in OS.get_cmdline_user_args()
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
		elif obj.type == "skater":
			for i in range(obj.route.size()):
				var a := Vector2(obj.route[i].pos[0],obj.route[i].pos[1])
				var b := Vector2(obj.route[(i+1)%obj.route.size()].pos[0],obj.route[(i+1)%obj.route.size()].pos[1])
				for y in range(map.height):
					for x in range(map.width):
						var p := Vector2(x,y)
						if p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b)) < 0.85:
							cells[Vector2i(x,y)] = true
	return cells

func route(map: Dictionary) -> Array[Vector2i]:
	var start := Vector2i(map.spawn[0], map.spawn[1])
	var goal := Vector2i(map.exit[0], map.exit[1])
	var blocked: Dictionary = {}
	for obj in map.objects:
		if obj.type == "city_prop" and obj.get("solid", false):
			for y in range(map.height):
				for x in range(map.width):
					if Props.covers(obj, Vector2(x,y), 0.40): blocked[Vector2i(x,y)] = true
		elif obj.type in ["pillar", "tree", "emitter"] or obj.get("solid", false):
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
	# Predict the existing deterministic patrol, including its .20-unit turn.
	# This test never changes runtime hazard positions or speeds.
	var snapshots: Array = []
	for c in world.critters:
		snapshots.append({"actor":c,"position":c.position,"index":c.waypoint_index})
	var from: Vector3 = world.player.position
	for target in targets:
		var steps := maxi(1,ceili(from.distance_to(target)/SPEED/STEP))
		for i in range(1,steps+1):
			var player_point := from.lerp(target,float(i)/steps)
			for state in snapshots:
				var c = state.actor
				if c.waypoints.is_empty():continue
				var waypoint: Vector3 = c.waypoints[state.index]
				if state.position.distance_to(waypoint)<0.20:
					state.index = (int(state.index)+1)%c.waypoints.size()
					waypoint = c.waypoints[state.index]
				state.position += (waypoint-state.position).normalized()*float(c.speed)*STEP
				if state.position.distance_to(player_point)<0.88:return false
		from = target
	return true

func skaters_clear(world: Node3D, targets: Array[Vector3]) -> bool:
	var elapsed := 0.0
	var from: Vector3 = world.player.position
	for target in targets:
		var duration := from.distance_to(target) / SPEED
		var steps := maxi(1,ceili(duration / STEP))
		for i in range(steps+1):
			var portion := float(i)/steps
			var player_point := from.lerp(target,portion)
			for skater in world.skaters:
				var sample: Dictionary = skater.sample_at_distance(skater.distance + skater.speed * (elapsed+portion*duration))
				var rider: Vector3 = sample.position
				if Vector2(rider.x-player_point.x,rider.z-player_point.z).length() < 1.05: return false
		elapsed += duration
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
	print("MOVE FAILED target=",world.position_cell(target)," at=",world.position_cell(world.player.position)," result=",world.result)
	world.input_vector = Vector2.ZERO
	return false

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.rule_notices_enabled = false
	await run_routes(app)
	quit(1 if failures.size() else 0)

func run_routes(app: Control) -> void:
	app.set_process(false)
	for phase in ([0.0,0.5,1.0,1.5,2.0,2.5,3.0,3.5,4.0,4.5] if naive else [0.0, 0.75, 1.5]):
		await run_phase(app,phase)

func run_phase(app: Control,phase: float) -> void:
	for index in range(6):
		var source: String = app.STREETLIFE_LEVELS[index]
		var map := Data.load_json("/tmp/streetlife-baseline/"+source.get_file() if baseline else source)
		check(not map.is_empty(), "Map validates: " + str(index))
		if map.is_empty(): continue
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
		for _phase_frame in range(roundi(phase/STEP)):
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
			if not naive:
				var clear := false
				for _wait in range(1800):
					if (not is_road or crossing_clear(app.world, target)) and critters_clear(app.world, targets) and skaters_clear(app.world, targets):
						clear = true
						break
					waited_frames += 1
					await app.get_tree().physics_frame
					if not app.world.result.is_empty():
						break
				if not clear:
					print("WAIT FAILED at ",app.world.position_cell(app.world.player.position)," target=",cell," result=",app.world.result)
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
		if not naive: check(traversed and app.world.result == "LEVEL COMPLETE!",
			"Full route reaches the exit with traffic and AI active: " + map.name)
		check(app.world.elapsed > phase and app.world.traffic.clock > 0,
			"Live simulation advanced throughout the route: " + map.name)
		print("STREETLIFE ROUTE: %s, phase=%.2f, %d cells, %d bands, %.2fs waiting, %.2fs simulated, result=%s" % [map.name, phase, path.size(),bands_crossed, waited_frames * STEP, app.world.elapsed, app.world.result])
	print("STREETLIFE ROUTES: %d checks, %d failures" % [checks, failures.size()])
