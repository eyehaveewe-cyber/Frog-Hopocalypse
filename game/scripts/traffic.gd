extends Node3D
## Deterministic lane traffic with relative swept collision and seam copies.
const City = preload("res://scripts/nyc_art.gd")
const CELL := 1.8
var lanes: Array = []
var vehicles: Array[Dictionary] = []
var clock := 0.0
var span := 0.0
var left := 0.0
var signals: Array[Dictionary] = []

func setup(level: Dictionary) -> void:
	name = "CityTraffic"
	lanes = level.get("traffic", []).duplicate(true)
	clock = 0.0
	span = (float(level.width) - 2) * CELL + 12.0
	left = -span * 0.5
	for lane_index in range(lanes.size()):
		var lane: Dictionary = lanes[lane_index]
		if lane.has("jam"):
			for side in [-1, 1]:
				var pole := Node3D.new()
				var signal_x: float = side * (float(level.width) - 3) * CELL * 0.5
				if lane.has("columns"):
					signal_x = (float(lane.columns[0] if side == -1 else lane.columns[1]) - (float(level.width) - 1) * 0.5) * CELL
				pole.position = Vector3(signal_x, 0, (float(lane.row) - (float(level.height) - 1) * 0.5) * CELL - 0.9)
				add_child(pole)
				City.cylinder(pole, "SignalPost", 0.065, 1.5, Vector3(0, 0.75, 0), Color("434b53"))
				City.box(pole, "SignalCase", Vector3(0.36, 0.55, 0.24), Vector3(0, 1.55, 0), Color("252a35"))
				var light := City.box(pole, "TrafficLight", Vector3(0.24, 0.24, 0.04), Vector3(0, 1.55, 0.14), Color("e65a4d"), 0.4)
				signals.append({"node": light, "lane": lane_index})
		var lane_left := left
		var lane_span := span
		if lane.has("columns"):
			lane_left = (float(lane.columns[0]) - (float(level.width) - 1) * 0.5 - 0.5) * CELL - 3.0
			lane_span = (float(lane.columns[1]) - float(lane.columns[0]) + 1.0) * CELL + 6.0
		var count := maxi(1, floori(lane_span / float(lane.spacing)))
		var interval := lane_span / count
		for slot in range(count):
			var kind: String = lane.vehicles[slot % lane.vehicles.size()]
			var node := City.vehicle(kind, slot + lane_index)
			node.name = "%s_L%d_%d" % [kind.capitalize(), lane_index, slot]
			node.rotation.y = 0 if lane.direction == 1 else PI
			node.position = Vector3(lane_left + fposmod(slot * interval + float(lane.get("offset", 0)), lane_span), 0, (float(lane.row) - (float(level.height) - 1) * 0.5) * CELL)
			add_child(node)
			vehicles.append({"node": node, "lane": lane_index, "span": lane_span, "left": lane_left, "kind": kind, "length": City.vehicle_length(kind), "origin_x": node.position.x, "previous": node.position, "unwrapped": node.position, "wrapped": false, "wheels": node.find_children("Wheel_*", "Node3D", true, false)})

# Integral of a square-wave traffic signal. Integrating absolute time prevents
# crossing a stop/go boundary at different frame rates from changing the gap.
static func moving_seconds(time: float, jam: Dictionary) -> float:
	var stopped := float(jam.stopped)
	var moving := float(jam.moving)
	var cycle := stopped + moving
	var cycles := floorf(time / cycle)
	return cycles * moving + maxf(0.0, fposmod(time, cycle) - stopped)

static func lane_travel(lane: Dictionary, start: float, duration: float) -> float:
	if not lane.has("jam"):
		return float(lane.speed) * float(lane.direction) * duration
	var jam: Dictionary = lane.jam
	var phase := float(jam.get("phase", 0.0))
	return float(lane.speed) * float(lane.direction) * (moving_seconds(start + duration + phase, jam) - moving_seconds(start + phase, jam))

func step(delta: float) -> void:
	var before_clock := clock
	clock += delta
	for signal_light in signals:
		var jam: Dictionary = lanes[signal_light.lane].jam
		var moving := fposmod(clock + float(jam.get("phase", 0)), float(jam.stopped) + float(jam.moving)) >= float(jam.stopped)
		signal_light.node.material_override = City.material(Color("70d9a2") if moving else Color("e65a4d"), 0.4)
	for vehicle in vehicles:
		var node: Node3D = vehicle.node
		var lane: Dictionary = lanes[vehicle.lane]
		var travel := lane_travel(lane, before_clock, delta)
		vehicle.previous = node.position
		vehicle.unwrapped = node.position + Vector3(travel, 0, 0)
		node.position.x = float(vehicle.left) + fposmod(vehicle.unwrapped.x - float(vehicle.left), float(vehicle.span))
		if lane.has("jam"):
			# Rebuild from absolute travel to avoid float32 transform accumulation.
			node.position.x = float(vehicle.left) + fposmod(float(vehicle.origin_x) + lane_travel(lane, 0.0, clock) - float(vehicle.left), float(vehicle.span))
		vehicle.wrapped = absf(node.position.x - vehicle.unwrapped.x) > float(vehicle.span) * 0.5
		for wheel in vehicle.wheels:
			wheel.rotation.z -= absf(travel) / 0.29

func hits_player(from: Vector3, to: Vector3, radius: float = 0.32) -> bool:
	for vehicle in vehicles:
		# Raised bridge decks and airborne riders pass above a vehicle only when
		# both ends of their sweep clear its roof.
		var roof := 1.62 if vehicle.kind in ["bus", "truck"] else 1.24
		if minf(from.y, to.y) > roof + 0.15:
			continue
		var half := Vector2(float(vehicle.length) * 0.5 + radius, 0.55 + radius)
		# A seam copy catches re-entry without sweeping across the whole street.
		var shifts: Array = [0.0]
		if vehicle.wrapped:
			shifts.append(-float(vehicle.span) if vehicle.unwrapped.x > float(vehicle.left) + float(vehicle.span) else float(vehicle.span))
		for shift in shifts:
			var before: Vector3 = vehicle.previous + Vector3(shift, 0, 0)
			var after: Vector3 = vehicle.unwrapped + Vector3(shift, 0, 0)
			if segment_box(Vector2(from.x - before.x, from.z - before.z), Vector2(to.x - after.x, to.z - after.z), half):
				return true
	return false

static func segment_box(a: Vector2, b: Vector2, half: Vector2) -> bool:
	var start := 0.0
	var end := 1.0
	var delta := b - a
	for axis in range(2):
		if absf(delta[axis]) < 0.00001:
			if absf(a[axis]) > half[axis]:
				return false
		else:
			var near_time := (-half[axis] - a[axis]) / delta[axis]
			var far_time := (half[axis] - a[axis]) / delta[axis]
			start = maxf(start, minf(near_time, far_time))
			end = minf(end, maxf(near_time, far_time))
			if start > end:
				return false
	return true
