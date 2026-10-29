extends Node3D
## Authoritative authored-loop movement; the pose only animates child pivots.
## Routes are validated at the level boundary, including their closing segment.
const Kit = preload("res://scripts/nyc_streetlife_art.gd")
const CONTACT_RADIUS := 0.74
const FROG_CLEARANCE := 0.78
var visual: Node3D
var variant := 0
var speed := 3.0
var clock := 0.0
var distance := 0.0
var route: Array[Dictionary] = []
var segment := 0
var segment_progress := 0.0
var state := "cruise"
var height := 0.0
var previous_position := Vector3.ZERO
var sweeps: Array[Dictionary] = []
var loop_length := 0.0
var points: Array[Vector3] = []
var lengths: Array[float] = []
var starts: Array[float] = []
var full_loop_sweep := false
var rider: Node3D
var board: Node3D
var body: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var head: Node3D
var wheels: Array[Node] = []
var rest: Dictionary = {}
var facing := 0.0

func setup(obj: Dictionary, world: Node3D) -> void:
	name = str(obj.id)
	variant = int(obj.get("variant", 0))
	speed = float(obj.get("speed", 3.0))
	route.clear()
	points.clear()
	lengths.clear()
	starts.clear()
	loop_length = 0.0
	clock = 0.0
	distance = 0.0
	for node in obj.route:
		route.append(node.duplicate(true))
		var point: Vector3 = world.cell_position(node.pos)
		point.y = float(node.get("height", 0.0))
		points.append(point)
	for i in range(points.size()):
		starts.append(loop_length)
		var offset := points[(i + 1) % points.size()] - points[i]
		var length := Vector2(offset.x, offset.z).length()
		lengths.append(length)
		loop_length += length
	visual = Kit.skater(variant)
	add_child(visual)
	rider = visual.get_node("RiderRoot")
	board = visual.get_node("Board")
	body = rider.get_node("Body")
	arm_l = rider.get_node("ArmL")
	arm_r = rider.get_node("ArmR")
	leg_l = rider.get_node("LegL")
	leg_r = rider.get_node("LegR")
	head = rider.get_node("Head")
	wheels = board.find_children("Wheel_*", "Node3D", true, false)
	for part in [rider, board, body, arm_l, arm_r, leg_l, leg_r, head]:
		rest[part] = {"position": part.position, "rotation": part.rotation, "scale": part.scale}
	apply_sample(sample_at_distance(0.0))
	previous_position = position
	facing = segment_facing(segment)
	rotation.y = facing
	sweeps.assign([{"from": position, "to": position, "t0": 0.0, "t1": 1.0}])
	pose(0.0, 0.0)

func sample_at_distance(along: float) -> Dictionary:
	var cursor := fposmod(along, loop_length)
	for i in range(lengths.size()):
		if cursor < starts[i] + lengths[i] or i == lengths.size() - 1:
			var progress := clampf((cursor - starts[i]) / lengths[i], 0.0, 1.0)
			var point := points[i].lerp(points[(i + 1) % points.size()], progress)
			return {"position": point, "segment": i, "progress": progress, "height": point.y, "state": str(route[i].get("trick", "cruise"))}
	return {}

func apply_sample(sample: Dictionary) -> void:
	position = sample.position
	segment = sample.segment
	segment_progress = sample.progress
	state = sample.state
	height = sample.height

func segment_facing(index: int) -> float:
	var direction := points[(index + 1) % points.size()] - points[index]
	return atan2(-direction.x, -direction.z)

func step(delta: float) -> void:
	previous_position = position
	sweeps.clear()
	full_loop_sweep = false
	if delta <= 0.0:
		sweeps.append({"from": position, "to": position, "t0": 0.0, "t1": 1.0})
		return
	var travel := speed * delta
	clock += delta
	# Ordinary physics ticks produce exact time-stamped sweeps at every corner.
	# A diagnostic jump exceeding a whole circuit uses bounded conservative
	# route occupancy instead of allocating an unbounded number of loop sweeps.
	if travel >= loop_length:
		full_loop_sweep = true
		for i in range(points.size()):
			sweeps.append({"from": points[i], "to": points[(i + 1) % points.size()], "t0": 0.0, "t1": 1.0})
	else:
		trace_step(travel)
	distance += travel
	apply_sample(sample_at_distance(distance))
	var desired := segment_facing(segment)
	var turn := angle_difference(facing, desired)
	facing = lerp_angle(facing, desired, 1.0 - exp(-12.0 * delta))
	rotation.y = facing
	pose(delta, turn)

func trace_step(travel: float) -> void:
	var remaining := travel
	var cursor := fposmod(distance, loop_length)
	var spent := 0.0
	# At most one circuit is traced, with an extra fragment at its closing edge.
	for _unit in range(points.size() + 2):
		if remaining <= 0.000001:
			break
		var sample := sample_at_distance(cursor)
		var index: int = sample.segment
		var available := lengths[index] * (1.0 - float(sample.progress))
		var amount := minf(remaining, available)
		var progress := clampf(float(sample.progress) + amount / lengths[index], 0.0, 1.0)
		var target := points[index].lerp(points[(index + 1) % points.size()], progress)
		sweeps.append({"from": sample.position, "to": target, "t0": spent / travel, "t1": (spent + amount) / travel})
		spent += amount
		remaining -= amount
		cursor = fposmod(cursor + amount, loop_length)
		# Pin exact endpoints to the following start to avoid roundoff fragments.
		if available - amount < 0.000001:
			cursor = starts[(index + 1) % points.size()]

func pose(delta: float, turn: float) -> void:
	for part in [rider, board, body, arm_l, arm_r, leg_l, leg_r, head]:
		part.position = rest[part].position
		part.rotation = rest[part].rotation
		part.scale = rest[part].scale
	var cycle := distance * TAU / 2.8
	var stroke := maxf(0.0, sin(cycle))
	var crouch := 0.0
	if state == "grind":
		crouch = 0.055
		arm_l.rotation.z = -1.0 + sin(cycle * 0.6) * 0.12
		arm_r.rotation.z = 1.0 + sin(cycle * 0.6 + 0.7) * 0.12
		body.rotation.z = clampf(turn * 0.18, -0.16, 0.16) + sin(cycle * 0.6) * 0.035
	elif state == "ramp":
		crouch = 0.11
		arm_l.rotation.x = -0.28
		arm_r.rotation.x = 0.20
		arm_l.rotation.z = -0.48
		arm_r.rotation.z = 0.48
		body.rotation.x = -0.12
	else:
		# One foot stays on the deck while the trailing foot delivers a stroke.
		var strength := 1.0 if state == "push" else 0.48
		leg_r.rotation.x -= stroke * 0.64 * strength
		arm_l.rotation.x += sin(cycle) * 0.22 * strength
		arm_r.rotation.x -= sin(cycle) * 0.26 * strength
		body.rotation.x = -0.07 - stroke * 0.04
		body.rotation.z = clampf(turn * 0.20, -0.18, 0.18)
	# Shorten the stylized legs as the pelvis lowers so the planted soles retain
	# their deck contact instead of sinking through the board during a crouch.
	rider.position.y -= crouch
	var compression := 1.0 - crouch / 0.55
	leg_l.scale.y *= compression
	leg_r.scale.y *= compression
	head.rotation.y += sin(cycle * 0.35 + variant) * 0.06
	var next := points[(segment + 1) % points.size()]
	var slope := atan2(next.y - points[segment].y, lengths[segment])
	# Deck and planted feet share the authored slope; torso counterlean is local.
	visual.rotation.x = slope
	if delta > 0.0:
		for wheel in wheels:
			wheel.rotation.x -= speed * delta / 0.065

func hits_player(from: Vector3, to: Vector3) -> bool:
	for sweep in sweeps:
		var start: Vector3 = sweep.from
		var finish: Vector3 = sweep.to
		if full_loop_sweep:
			# Only used for deliberate skips longer than a complete circuit. There
			# is no trustworthy sub-frame timing then; conservatively test the route.
			if minf(start.y, finish.y) > maxf(from.y, to.y) + FROG_CLEARANCE or minf(from.y,to.y)>maxf(start.y,finish.y)+FROG_CLEARANCE:
				continue
			if segments_close(Vector2(start.x, start.z), Vector2(finish.x, finish.z), Vector2(from.x, from.z), Vector2(to.x, to.z)):
				return true
			continue
		var player_start := from.lerp(to, float(sweep.t0))
		var player_end := from.lerp(to, float(sweep.t1))
		var low := 0.0
		var high := 1.0
		var height_start := start.y - player_start.y
		var height_delta := finish.y - player_end.y-height_start
		if absf(height_delta)<0.000001:
			if absf(height_start)>FROG_CLEARANCE: continue
		else:
			var near_time:=(-FROG_CLEARANCE-height_start)/height_delta
			var far_time:=(FROG_CLEARANCE-height_start)/height_delta
			low=maxf(low,minf(near_time,far_time))
			high=minf(high,maxf(near_time,far_time))
			if low>high: continue
		var relative_start := Vector2(player_start.x - start.x, player_start.z - start.z)
		var relative_end := Vector2(player_end.x - finish.x, player_end.z - finish.z)
		var a := relative_start.lerp(relative_end, low)
		var b := relative_start.lerp(relative_end, high)
		var closest := Geometry2D.get_closest_point_to_segment(Vector2.ZERO, a, b)
		if closest.length_squared() < CONTACT_RADIUS * CONTACT_RADIUS:
			return true
	return false

static func segments_close(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	if Geometry2D.segment_intersects_segment(a, b, c, d) != null:
		return true
	var radius_squared := CONTACT_RADIUS * CONTACT_RADIUS
	for endpoint in [c, d]:
		if endpoint.distance_squared_to(Geometry2D.get_closest_point_to_segment(endpoint, a, b)) < radius_squared:
			return true
	for endpoint in [a, b]:
		if endpoint.distance_squared_to(Geometry2D.get_closest_point_to_segment(endpoint, c, d)) < radius_squared:
			return true
	return false
