extends SceneTree
## Reproduce: bash tools/godot.sh --headless --script res://tests/skater_contacts.gd
## Measures actual procedural mesh bounds and runtime poses on the authored plaza.
const Data = preload("res://scripts/level_data.gd")
const Skater = preload("res://scripts/skater.gd")
const Kit = preload("res://scripts/nyc_streetlife_art.gd")
const PLAZA = "res://levels/nyc_06_brooklyn_skate_circle.json"
var failures: Array[String] = []
var checks := 0

class GridWorld:
	extends Node3D
	var level: Dictionary
	func cell_position(p: Array) -> Vector3:
		return Vector3((float(p[0]) - (float(level.width) - 1) * 0.5) * 1.8, 0, (float(p[1]) - (float(level.height) - 1) * 0.5) * 1.8)

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures.append(description)
		push_error(description)

func mesh_y(node: MeshInstance3D, top: bool) -> float:
	var bounds := node.mesh.get_aabb()
	var result := -INF if top else INF
	for x in [0.0, 1.0]:
		for y in [0.0, 1.0]:
			for z in [0.0, 1.0]:
				var point := node.global_transform * (bounds.position + bounds.size * Vector3(x, y, z))
				result = maxf(result, point.y) if top else minf(result, point.y)
	return result

func sole_gap(skater: Node3D, leg: Node3D) -> float:
	var sole: MeshInstance3D = leg.get_node("ShoeSole")
	var grip: MeshInstance3D = skater.board.get_node("GripTape")
	var bounds := sole.mesh.get_aabb()
	var bottom := bounds.position + bounds.size * Vector3(0.5, 0, 0.5)
	var in_visual: Vector3 = skater.rider.transform * leg.transform * sole.transform * bottom
	var in_board: Vector3 = skater.board.transform.affine_inverse() * in_visual
	var grip_top := grip.position.y + grip.mesh.get_aabb().end.y
	return in_board.y - grip_top

func run() -> void:
	var map := Data.load_json(PLAZA)
	check(not map.is_empty(), "Authored skate plaza loads for contact inspection")
	if map.is_empty():
		quit(1)
		return
	var world := GridWorld.new()
	world.level = map
	root.add_child(world)
	var rails: Array[MeshInstance3D] = []
	for obj in map.objects:
		if obj.type == "city_prop" and obj.variant == "skate_rail":
			var rail := Kit.prop("skate_rail")
			world.add_child(rail)
			rail.position = world.cell_position(obj.pos)
			rail.rotation.y = deg_to_rad(float(obj.get("rotation", 0)))
			rails.append(rail.get_node("GrindRail"))
	check(rails.size() >= 2, "Actual authored rail supports instantiate")
	for rail in rails:
		check(absf(mesh_y(rail, true) - 0.65) < 0.00001, "GrindRail mesh top is 0.650000 world units")
	var expected_final: Dictionary = {}
	for fps in [30, 60, 120]:
		for obj in map.objects:
			if obj.type != "skater":
				continue
			var skater := Skater.new()
			world.add_child(skater)
			skater.setup(obj, world)
			var trucks: Array[Node] = skater.board.find_children("Truck*", "MeshInstance3D", true, false)
			var max_sole_gap := 0.0
			var max_rail_gap := 0.0
			var rail_samples := 0
			var states: Dictionary = {}
			var expects_grind := false
			for point in obj.route:
				expects_grind = expects_grind or point.trick == "grind"
			for _frame in range(fps * 40):
				skater.step(1.0 / fps)
				states[skater.state] = true
				max_sole_gap = maxf(max_sole_gap, absf(sole_gap(skater, skater.leg_l)))
				if skater.state in ["grind", "ramp"]:
					max_sole_gap = maxf(max_sole_gap, absf(sole_gap(skater, skater.leg_r)))
				if skater.state != "grind":
					continue
				for truck in trucks:
					for rail in rails:
						var local: Vector3 = rail.to_local(truck.global_position)
						# Inspect full truck contact only inside the rail ends. At entry
						# and exit a truck may intentionally be supported by the ramp.
						if absf(local.x) < 0.05 and absf(local.z) < 1.9:
							max_rail_gap = maxf(max_rail_gap, absf(mesh_y(truck, false) - mesh_y(rail, true)))
							rail_samples += 1
			check(max_sole_gap < 0.025, "%s at %d Hz keeps planted soles within 0.025 of deck" % [obj.id, fps])
			if expects_grind:
				check(rail_samples > 10 and max_rail_gap < 0.00001, "%s at %d Hz trucks contact actual rails within 0.00001" % [obj.id, fps])
			if fps == 30:
				expected_final[obj.id] = skater.position
			else:
				check(skater.position.distance_to(expected_final[obj.id]) < 0.00001, "%s at %d Hz matches the 30 Hz route position" % [obj.id, fps])
			print("SKATER CONTACT: %s, %d Hz, sole error=%.6f, rail error=%.6f, rail samples=%d, states=%s" % [obj.id, fps, max_sole_gap, max_rail_gap, rail_samples, str(states.keys())])
			skater.free()
	print("SKATER CONTACTS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
