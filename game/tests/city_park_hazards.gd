extends SceneTree
## Run: bash tools/godot.sh --headless --script res://tests/city_park_hazards.gd
const Park = preload("res://scripts/park_hazards.gd")
const Traffic = preload("res://scripts/traffic.gd")
var failures: Array[String] = []
var checks := 0
class TestWorld:
	extends Node3D
	var player: Node3D
	func cell_position(p: Array) -> Vector3:
		return Vector3(float(p[0]) * 1.8, 0, float(p[1]) * 1.8)

func _initialize() -> void: call_deferred("run")
func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok: failures.append(description); push_error(description)
	else: print("PASS " + description)

func make_park(kind: String) -> Node3D:
	var world := TestWorld.new()
	root.add_child(world)
	world.player = Node3D.new()
	world.add_child(world.player)
	world.player.position = Vector3(1, 0, -1)
	var park := Park.new()
	world.add_child(park)
	park.setup({"park_encounters": [{"id": kind, "kind": kind, "pos": [0, 0], "direction": [0, -1]}]}, world)
	return park

func run() -> void:
	for kind in ["ambusher", "purse", "pigeons"]:
		var park := make_park(kind)
		var e: Dictionary = park.encounters[0]
		park.world.player.position = Vector3(30, 0, 30)
		park.step(2.0)
		check(e.state == "idle" and park.contacts.is_empty(), kind + " stays idle while distant")
		park.world.player.position = Vector3(1, 0, -1)
		park.step(0.1)
		check(e.state == "warning" and e.warning.visible and not park.get_hint().is_empty(), kind + " telegraphs before attacking")
		check(park.hits_player(Vector3.ZERO, Vector3(0, 0, -2)).is_empty(), kind + " warning is harmless")
		for _i in range(100):
			park.step(1.0 / 120.0)
			if e.state == "attack": break
		if e.state != "attack":
			for _i in range(100):
				park.step(1.0 / 120.0)
				if e.state == "attack": break
		park.step(0.12)
		check(e.state == "attack" and not park.contacts.is_empty(), kind + " attack creates swept collision")
		var point: Vector3 = park.contacts[-1].to
		check(not park.hits_player(point, point).is_empty(), kind + " actual attack point hits frog")
		check(park.hits_player(point + Vector3.UP * 2.5, point + Vector3.UP * 2.5).is_empty(), kind + " cannot hit raised bridge deck")
		check(park.hits_player(Vector3(10,0,10), Vector3(10,0,10)).is_empty(), kind + " has a clear sidestep escape")
		for _i in range(240):
			park.step(1.0 / 120.0)
			if e.state == "recovery": break
		park.step(0.05)
		check(e.state == "recovery" and park.contacts.is_empty(), kind + " recovery is a safe crossing window")
		park.get_parent().free()
	var duet := make_park("ice_duet")
	var start: Array = duet.danger_points(duet.encounters[0])
	duet.step(0.5)
	var after: Array = duet.danger_points(duet.encounters[0])
	check(start[0].distance_to(after[0]) > 0.5, "Duet skaters move on actual rink orbit")
	check(after[0].distance_to(-after[1]) < 0.001, "Duet partners keep mirrored formation")
	check(not duet.hits_player(after[0], after[0]).is_empty(), "Duet collision follows visible skating position")
	check(duet.hits_player(Vector3.ZERO, Vector3.ZERO).is_empty(), "Duet leaves an inside crossing option")
	duet.get_parent().free()
	var lane := {"row": 5, "direction": 1, "speed": 4.0, "spacing": 6.0, "vehicles": ["taxi"], "jam": {"stopped": 3.0, "moving": 4.0, "phase": 0.0}}
	check(is_zero_approx(Traffic.lane_travel(lane, 0, 3)), "Jam holds cars fully stopped for red interval")
	check(absf(Traffic.lane_travel(lane, 2.5, 1.0) - 2.0) < 0.00001, "Jam integrates only moving half of boundary frame")
	check(absf(Traffic.lane_travel(lane, 0, 7) - 16.0) < 0.00001, "Jam complete cycle has expected travel")
	var ordinary := lane.duplicate(true)
	ordinary.erase("jam")
	check(absf(Traffic.lane_travel(ordinary, 8.1, 0.2) - 0.8) < 0.00001, "Existing continuous lanes retain original speed")
	var lane_spans: Array = []
	for fps in [30, 60, 120]:
		var traffic := Traffic.new()
		root.add_child(traffic)
		var localized := lane.duplicate(true)
		localized.columns = [2, 12]
		traffic.setup({"width": 49, "height": 59, "traffic": [localized]})
		var before: float = traffic.vehicles[0].node.position.x
		for _i in range(fps * 7): traffic.step(1.0 / fps)
		var travelled := fposmod(traffic.vehicles[0].node.position.x - before, float(traffic.vehicles[0].span))
		check(absf(travelled - 16.0) < 0.0001, "Jam motion is stable at %d Hz" % fps)
		check(traffic.vehicles[0].span < traffic.span * 0.4, "Localized street uses its own wrap span at %d Hz" % fps)
		var center: Vector3 = traffic.vehicles[0].node.position
		traffic.step(0)
		check(traffic.hits_player(center, center), "Stopped car still occupies its lane at %d Hz" % fps)
		check(not traffic.hits_player(center + Vector3.UP * 2.5, center + Vector3.UP * 2.5), "Bridge deck clears stopped taxi at %d Hz" % fps)
		traffic.free()
	print("CITY PARK HAZARDS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
