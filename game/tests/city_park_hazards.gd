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

var checked_feed := false
func check_once_feed(flock: Node3D,e: Dictionary) -> void:
	if checked_feed: return
	checked_feed = true
	var p: Vector3 = flock.danger_points(e)[0]
	check(not flock.hits_player(p,p).is_empty(),"Feeding flock remains a dangerous occupied patch")

func run() -> void:
	for kind in ["ambusher","purse"]:
		var park := make_park(kind)
		var e: Dictionary = park.encounters[0]
		park.world.player.position = Vector3(30,0,30)
		park.step(2)
		check(e.state == "idle" and park.contacts.is_empty(),kind+" stays idle while distant")
		park.world.player.position = Vector3(1,0,-1)
		var armed_clock: float = e.clock
		park.step(0.05)
		check(e.state == "warning" and not park.get_hint().is_empty(),kind+" uses quick pose anticipation")
		check(park.find_children("WarningPath","Node3D",true,false).is_empty(),kind+" has no painted queued attack path")
		check(park.hits_player(Vector3.ZERO,Vector3(0,0,-2)).is_empty(),kind+" wind-up is harmless")
		for _i in range(80):
			park.step(1.0/120)
			if e.state == "attack": break
		check(float(e.clock)-armed_clock<0.35,kind+" begins attack within0.35s")
		park.step(0.04)
		var point: Vector3 = park.contacts[-1].to
		check(not park.hits_player(point,point).is_empty(),kind+" fast swept attack hits at actual path")
		check(park.hits_player(point+Vector3.UP*2.5,point+Vector3.UP*2.5).is_empty(),kind+" ignores raised deck")
		if kind == "purse":
			var visible: Vector3 = e.bag.global_position
			var contact: Vector3 = park.danger_points(e)[0]
			check(Vector2(visible.x-contact.x,visible.z-contact.z).length()<0.001,"Purse contact follows attached visible bag")
			check(e.bag.get_parent()==e.people[0].get_node("RightArm"),"Purse strap stays attached to swinging hand")
		for _i in range(100):
			park.step(1.0/120)
			if e.state == "recovery": break
		park.step(0.025)
		check(e.state == "recovery" and park.contacts.is_empty(),kind+" recovery offers safe crossing")
		park.get_parent().free()
	var flock := make_park("pigeons")
	var bird_e: Dictionary = flock.encounters[0]
	flock.step(0.01)
	check(bird_e.state == "seed" and flock.contacts.is_empty(),"Seed toss precedes flock danger")
	flock.step(0.12)
	check(bird_e.seeds[0].visible and bird_e.seeds[0].position.y>0.1,"Visible seed scatters through an arc")
	check(bird_e.seeds[0].scale.x<=0.121 and bird_e.seeds[0].scale.z<=0.121,"Toss animation preserves small seed model scale")
	var states: Array = [bird_e.state]
	var feed_first := Vector3.ZERO
	var feed_last := Vector3.ZERO
	var saw_feed := false
	for _i in range(300):
		flock.step(1.0/120)
		if bird_e.state not in states: states.append(bird_e.state)
		if bird_e.state == "feed":
			if not saw_feed: feed_first = bird_e.birds[0].position; saw_feed = true
			feed_last = bird_e.birds[0].position
			check_once_feed(flock,bird_e)
	check(states == ["seed","swoop","feed","depart","return","perch"],"Flock completes seed, swoop, feed, departure, return and perch loop")
	check(Vector2(feed_first.x-feed_last.x,feed_first.z-feed_last.z).length()<0.01,"Pigeons stay over seed while pecking instead of flying past")
	bird_e.state = "perch"; bird_e.time = 0; flock.pose(bird_e)
	check(bird_e.birds[0].position.z>0 and bird_e.birds[0].position.y>1.2,"Pigeons return behind and onto keeper")
	check(flock.find_children("WarningPath","Node3D",true,false).is_empty(),"Flock uses seed rather than painted line")
	flock.get_parent().free()
	for kind in ["ambusher","purse","pigeons"]:
		var poses: Array = []
		var phases: Array = []
		for hz in [30,60,120]:
			var timed := make_park(kind)
			for i in range(hz*2): timed.step(1.0/hz)
			var e: Dictionary = timed.encounters[0]
			phases.append(e.state)
			poses.append(e.birds[0].global_position if kind == "pigeons" else (e.bag.global_position if kind == "purse" else e.people[0].global_position))
			timed.get_parent().free()
		check(phases[0]==phases[2] and poses[0].distance_to(poses[2])<0.02,kind+" quick cycle agrees at30/60/120Hz")
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
