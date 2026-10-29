extends Node3D
## Authored park encounters: proximity warning, fixed attack, then a safe recovery.
## Paths and phase durations are deterministic; no attack tracks the frog after warning.
const Kit = preload("res://scripts/nyc_art.gd")
const Detail = preload("res://scripts/nyc_streetlife_art.gd")
const DURATIONS = {
	"ambusher": [0.85, 0.62, 1.8], "purse": [0.9, 0.65, 1.9],
	"pigeons": [1.1, 1.65, 2.3]
}
var encounters: Array[Dictionary] = []
var contacts: Array[Dictionary] = []
var world: Node3D
var clock := 0.0

func setup(level: Dictionary, owner_world: Node3D) -> void:
	name = "ParkEncounters"
	world = owner_world
	for spec in level.get("park_encounters", []):
		var anchor := Node3D.new()
		anchor.name = str(spec.id)
		anchor.position = world.cell_position(spec.pos)
		var dir: Array = spec.get("direction", [0, -1])
		anchor.rotation.y = atan2(-float(dir[0]), -float(dir[1]))
		add_child(anchor)
		var kind := str(spec.kind)
		var e := {"spec": spec, "anchor": anchor, "kind": kind, "state": "idle", "time": 0.0,
			"clock": float(spec.get("phase", 0.0)), "people": [], "birds": [], "warning": null}
		if kind == "ice_duet":
			for i in range(2):
				var person := person_model(Color("618fcb") if i == 0 else Color("c9668e"), true)
				anchor.add_child(person)
				e.people.append(person)
		else:
			var person := person_model(Color("665270") if kind == "ambusher" else (Color("bc824e") if kind == "pigeons" else Color("976484")))
			anchor.add_child(person)
			e.people.append(person)
			var length := 7.0 if kind == "pigeons" else 2.6
			var warning := Node3D.new()
			warning.name = "WarningPath"
			anchor.add_child(warning)
			if kind == "purse":
				# Match the swinging bag's arc, rather than implying a narrow lunge.
				for i in range(9):
					var angle := lerpf(-1.15, 1.15, i / 8.0)
					var marker := Kit.box(warning, "SwingArc", Vector3(0.70, 0.018, 0.70), Vector3(sin(angle) * 1.6, 0.028, -cos(angle) * 1.6), Color("e8bc56"))
					marker.rotation.y = -angle
			else:
				Kit.box(warning, "ApproachPath", Vector3(1.4, 0.018, length), Vector3(0, 0.028, -length * 0.5), Color("e8bc56"))
			warning.visible = false
			e.warning = warning
			# The path is a gameplay telegraph; it does not pretend to be city markings.
			if kind == "ambusher":
				for side in [-1, 0, 1]:
					Detail.orb(anchor, "Bush", Vector3(1.1, 1.0, 1.1), Vector3(side * 0.45, 0.45, 0.15), Color("476e45"))
				var knife := Kit.box(person.get_node("RightArm"), "CartoonKnife", Vector3(0.075, 0.30, 0.035), Vector3(0, -0.58, -0.09), Color("d9dfe1"))
				knife.rotation.x = -0.7
			elif kind == "purse":
				var bag := Node3D.new()
				bag.name = "SwingingPurse"
				anchor.add_child(bag)
				Kit.box(bag, "Bag", Vector3(0.48, 0.36, 0.22), Vector3.ZERO, Color("713b35"))
				for side in [-1, 1]:
					Kit.box(bag, "Strap", Vector3(0.025, 0.38, 0.025), Vector3(side * 0.16, 0.31, 0), Color("bc8d57"))
				e.bag = bag
			else:
				for i in range(7):
					var bird := bird_model()
					anchor.add_child(bird)
					e.birds.append(bird)
		encounters.append(e)
		pose(e)

static func person_model(coat: Color, skates: bool = false) -> Node3D:
	var person := Node3D.new()
	Kit.box(person, "Coat", Vector3(0.48, 0.58, 0.30), Vector3(0, 0.95, 0), coat)
	Detail.orb(person, "Head", Vector3(0.34, 0.38, 0.34), Vector3(0, 1.43, 0), Color("d2a27e"))
	Kit.box(person, "Hair", Vector3(0.35, 0.12, 0.33), Vector3(0, 1.62, 0), Color("51443f"))
	for side in [-1, 1]:
		Kit.box(person, "Eye", Vector3(0.045, 0.045, 0.025), Vector3(side * 0.075, 1.46, -0.17), Color("293747"))
		var arm := Node3D.new()
		arm.name = "LeftArm" if side == -1 else "RightArm"
		arm.position = Vector3(side * 0.29, 1.17, 0)
		person.add_child(arm)
		Kit.box(arm, "Sleeve", Vector3(0.14, 0.38, 0.17), Vector3(0, -0.15, 0), coat)
		Detail.orb(arm, "Hand", Vector3(0.14, 0.16, 0.14), Vector3(0, -0.40, 0), Color("d2a27e"))
		var leg := Node3D.new()
		leg.name = "LeftLeg" if side == -1 else "RightLeg"
		leg.position = Vector3(side * 0.13, 0.68, 0)
		person.add_child(leg)
		Kit.box(leg, "Trouser", Vector3(0.17, 0.47, 0.18), Vector3(0, -0.22, 0), Color("364755"))
		Kit.box(leg, "Shoe", Vector3(0.20, 0.13, 0.34), Vector3(0, -0.51, -0.06), Color("e5dfd4") if skates else Color("323844"))
		if skates:
			Kit.box(leg, "Blade", Vector3(0.025, 0.08, 0.40), Vector3(0, -0.60, -0.04), Color("b7d4dd"))
	return person

static func bird_model() -> Node3D:
	var bird := Node3D.new()
	Detail.orb(bird, "Body", Vector3(0.26, 0.25, 0.43), Vector3.ZERO, Color("82909b"))
	Detail.orb(bird, "Head", Vector3(0.19, 0.19, 0.19), Vector3(0, 0.13, -0.20), Color("576a7b"))
	Kit.box(bird, "Beak", Vector3(0.055, 0.045, 0.13), Vector3(0, 0.10, -0.31), Color("d4b381"))
	for side in [-1, 1]:
		var wing := Node3D.new()
		wing.name = "WingL" if side == -1 else "WingR"
		bird.add_child(wing)
		Kit.box(wing, "Feathers", Vector3(0.38, 0.045, 0.27), Vector3(side * 0.20, 0, 0.02), Color("9ca6ad"))
	return bird

func danger_points(e: Dictionary) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var anchor: Node3D = e.anchor
	if e.kind == "ice_duet":
		var radius := float(e.spec.get("radius", 2.5))
		for side in [-1, 1]:
			var angle: float = float(e.clock) * 0.75 + (PI if side == -1 else 0)
			points.append(anchor.transform * Vector3(cos(angle) * radius, 0, sin(angle) * radius))
	elif e.state == "attack":
		var u := clampf(float(e.time) / float(DURATIONS[e.kind][1]), 0, 1)
		var p := Vector3.ZERO
		if e.kind == "ambusher": p = Vector3(0, 0, -0.45 - 2.3 * sin(u * PI * 0.5))
		elif e.kind == "purse": p = Vector3(sin(lerpf(-1.15, 1.15, u)) * 1.6, 0, -cos(lerpf(-1.15, 1.15, u)) * 1.6)
		else: p = Vector3(0, 0, -0.4 - 7.0 * u)
		points.append(anchor.transform * p)
	return points

func step(delta: float) -> void:
	contacts.clear()
	if delta <= 0: return
	var cursor := 0.0
	while cursor < delta - 0.000001:
		var dt := minf(1.0 / 60.0, delta - cursor)
		for e in encounters:
			var before := danger_points(e)
			e.clock += dt
			if e.kind != "ice_duet":
				if e.state == "idle":
					if world.player != null and world.player.position.distance_to(e.anchor.position) < 6.0:
						e.state = "warning"
						e.time = 0.0
				else:
					e.time += dt
					var stage: int = ["warning", "attack", "recovery"].find(e.state)
					var duration := float(DURATIONS[e.kind][stage])
					if e.time >= duration:
						e.time -= duration
						e.state = ["attack", "recovery", "idle"][stage]
			var after := danger_points(e)
			if not after.is_empty():
				for i in range(after.size()):
					contacts.append({"from": before[i] if i < before.size() else after[i], "to": after[i],
						"start": cursor / delta, "end": (cursor + dt) / delta,
						"radius": 0.70 if e.kind == "pigeons" else (0.42 if e.kind == "ice_duet" else 0.37), "kind": e.kind})
		cursor += dt
	clock += delta
	for e in encounters: pose(e)

func pose(e: Dictionary) -> void:
	var people: Array = e.people
	if e.kind == "ice_duet":
		var points := danger_points(e)
		for i in range(2):
			var person: Node3D = people[i]
			person.position = e.anchor.transform.affine_inverse() * points[i]
			person.rotation.y = -float(e.clock) * 0.75 - i * PI
			person.rotation.z = 0.12
			person.get_node("LeftArm").rotation.z = -1.1
			person.get_node("RightArm").rotation.z = 1.1
			person.get_node("LeftLeg").rotation.x = sin(float(e.clock) * 2) * 0.18
			person.get_node("RightLeg").rotation.x = -sin(float(e.clock) * 2) * 0.18
		return
	var person: Node3D = people[0]
	var warning: Node3D = e.warning
	warning.visible = e.state == "warning"
	if warning.visible:
		warning.scale.x = 0.85 + 0.15 * sin(float(e.time) * 18)
	var attack: bool = e.state == "attack"
	var u := clampf(float(e.time) / float(DURATIONS[e.kind][1]), 0, 1) if attack else 0.0
	person.get_node("RightArm").rotation.x = -1.2 if e.state == "warning" else (-0.7 if attack else 0.0)
	person.get_node("LeftArm").rotation.z = 0.2 * sin(float(e.clock) * 2)
	person.position = Vector3.ZERO
	if e.kind == "ambusher":
		if attack: person.position.z = -2.3 * sin(u * PI * 0.5)
		elif e.state == "recovery": person.position.z = lerpf(-2.3, 0, clampf(float(e.time) / 1.1, 0, 1))
		person.get_node("LeftLeg").rotation.x = sin(float(e.clock) * 15) * 0.45 if attack else 0.0
		person.get_node("RightLeg").rotation.x = -person.get_node("LeftLeg").rotation.x
	elif e.kind == "purse":
		var angle := lerpf(-1.15, 1.15, u) if attack else -1.15
		e.bag.position = Vector3(sin(angle) * 1.6, 0.65, -cos(angle) * 1.6)
		e.bag.rotation.z = -angle
		person.rotation.y = -angle * 0.5
	else:
		for i in range(e.birds.size()):
			var bird: Node3D = e.birds[i]
			var lateral := (i % 3 - 1) * 0.45
			bird.position = Vector3(lateral, 0.7 + sin(float(e.clock) * 9 + i) * 0.1 if attack else 0.18, -0.4 - 7.0 * u - (i / 3) * 0.22)
			bird.get_node("WingL").rotation.z = sin(float(e.clock) * 18 + i) * 0.8 if attack else 0.0
			bird.get_node("WingR").rotation.z = -bird.get_node("WingL").rotation.z

func hits_player(from: Vector3, to: Vector3) -> String:
	for contact in contacts:
		var a: Vector3 = from.lerp(to, contact.start) - contact.from
		var b: Vector3 = from.lerp(to, contact.end) - contact.to
		# Bridge riders and jumping frogs above these low park hazards stay clear.
		if minf(a.y, b.y) > 0.95 or maxf(a.y, b.y) < -0.8: continue
		var nearest := Geometry2D.get_closest_point_to_segment(Vector2.ZERO, Vector2(a.x, a.z), Vector2(b.x, b.z))
		if nearest.length() < float(contact.radius) + 0.32:
			return {"ambusher": "BUSH AMBUSH!", "purse": "PURSE WHACK!", "pigeons": "PIGEON PILEUP!", "ice_duet": "ICE COLLISION!"}[contact.kind]
	return ""

func get_hint() -> String:
	for e in encounters:
		if e.state == "warning":
			return {"ambusher": "Rustling bush — leave the yellow lunge path!", "purse": "Purse winding up — step outside the swing!", "pigeons": "Pigeons gathering — clear the yellow flight path!"}[e.kind]
	return ""
