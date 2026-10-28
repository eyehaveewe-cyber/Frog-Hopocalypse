extends Node3D
## Deterministic lane traffic with relative swept collision and seam copies.
const City = preload("res://scripts/nyc_art.gd")
const CELL := 1.8
var lanes: Array = []
var vehicles: Array[Dictionary] = []
var clock := 0.0
var span := 0.0
var left := 0.0

func setup(level: Dictionary) -> void:
	name = "CityTraffic"
	lanes = level.get("traffic", []).duplicate(true)
	span = (float(level.width) - 2) * CELL + 12.0
	left = -span * 0.5
	for lane_index in range(lanes.size()):
		var lane: Dictionary = lanes[lane_index]
		var count := maxi(1, floori(span / float(lane.spacing)))
		var interval := span / count
		for slot in range(count):
			var kind: String = lane.vehicles[slot % lane.vehicles.size()]
			var node := City.vehicle(kind, slot + lane_index)
			node.name = "%s_L%d_%d" % [kind.capitalize(), lane_index, slot]
			node.rotation.y = 0 if lane.direction == 1 else PI
			node.position = Vector3(left + fposmod(slot * interval + float(lane.get("offset", 0)), span), 0, (float(lane.row) - (float(level.height) - 1) * 0.5) * CELL)
			add_child(node)
			vehicles.append({"node": node, "lane": lane_index, "kind": kind, "length": City.vehicle_length(kind), "previous": node.position, "unwrapped": node.position, "wrapped": false, "wheels": node.find_children("Wheel_*", "Node3D", true, false)})

func step(delta: float) -> void:
	clock += delta
	for vehicle in vehicles:
		var node: Node3D = vehicle.node
		var lane: Dictionary = lanes[vehicle.lane]
		var travel := float(lane.speed) * float(lane.direction) * delta
		vehicle.previous = node.position
		vehicle.unwrapped = node.position + Vector3(travel, 0, 0)
		node.position.x = left + fposmod(vehicle.unwrapped.x - left, span)
		vehicle.wrapped = absf(node.position.x - vehicle.unwrapped.x) > span * 0.5
		for wheel in vehicle.wheels:
			wheel.rotation.z -= absf(travel) / 0.29

func hits_player(from: Vector3, to: Vector3, radius: float = 0.32) -> bool:
	for vehicle in vehicles:
		var half := Vector2(float(vehicle.length) * 0.5 + radius, 0.55 + radius)
		# A seam copy catches re-entry without sweeping across the whole street.
		var shifts: Array = [0.0]
		if vehicle.wrapped:
			shifts.append(-span if vehicle.unwrapped.x > left + span else span)
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
