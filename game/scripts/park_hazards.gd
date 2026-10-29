extends Node3D
## Fast pose-led attacks. Seed/flock phases share their visual and contact paths.
const Kit = preload("res://scripts/nyc_art.gd")
const Detail = preload("res://scripts/nyc_streetlife_art.gd")
const DURATIONS = {"ambusher": [0.22, 0.18, 0.75], "purse": [0.24, 0.22, 0.85]}
const BIRD_PHASES = ["seed", "swoop", "feed", "depart", "return", "perch"]
const BIRD_TIMES = [0.28, 0.32, 0.55, 0.25, 0.45, 0.38]
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
		var e := {"spec":spec,"anchor":anchor,"kind":kind,"state":"idle","time":0.0,
			"clock":float(spec.get("phase",0)),"people":[],"birds":[],"seeds":[]}
		if kind == "ice_duet":
			for i in range(2):
				var person := person_model(Color("618fcb") if i == 0 else Color("c9668e"), true)
				anchor.add_child(person)
				e.people.append(person)
		else:
			var person := person_model(Color("665270") if kind == "ambusher" else (Color("bc824e") if kind == "pigeons" else Color("976484")))
			anchor.add_child(person)
			e.people.append(person)
			if kind == "ambusher":
				for side in [-1,0,1]:
					Detail.orb(anchor,"Bush",Vector3(1.1,1,1.1),Vector3(side*0.45,0.45,0.15),Color("476e45"))
				var knife := Kit.box(person.get_node("RightArm"),"CartoonKnife",Vector3(0.075,0.30,0.035),Vector3(0,-0.55,-0.09),Color("d9dfe1"))
				knife.rotation.x = -0.7
			elif kind == "purse":
				var bag := Node3D.new()
				bag.name = "SwingingPurse"
				bag.position = Vector3(0,-0.95,0)
				person.get_node("RightArm").add_child(bag)
				Kit.box(bag,"Bag",Vector3(0.48,0.36,0.22),Vector3.ZERO,Color("713b35"))
				for side in [-1,1]:
					Kit.box(bag,"Strap",Vector3(0.025,0.40,0.025),Vector3(side*0.16,0.34,0),Color("bc8d57"))
				e.bag = bag
			else:
				Kit.box(person,"SeedPouch",Vector3(0.25,0.31,0.18),Vector3(-0.32,0.83,-0.15),Color("aa8451"))
				for i in range(7):
					var bird := bird_model()
					anchor.add_child(bird)
					e.birds.append(bird)
				for i in range(14):
					e.seeds.append(Detail.orb(anchor,"BirdSeed",Vector3(0.12,0.075,0.12),Vector3.ZERO,Color("dcb477")))
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

func bird_local(e: Dictionary, index: int) -> Vector3:
	var state: String = e.state
	var phase: int = BIRD_PHASES.find(state)
	var u := clampf(float(e.time)/float(BIRD_TIMES[phase]),0,1) if phase >= 0 else 0.0
	var perch := Vector3((index%3-1)*0.23,1.45+float(index/3)*0.18,0.25+float(index%2)*0.18)
	var feeding := Vector3((index%3-1)*0.48,0.16,-2.8-float(index/3)*0.42)
	if state == "swoop":
		return perch.lerp(feeding,smoothstep(0,1,u))+Vector3(0,sin(u*PI)*0.45,0)
	if state == "feed":
		return feeding+Vector3(0,maxf(0,sin(float(e.clock)*16+index))*0.10,0)
	var outgoing := feeding+Vector3((index%2*2-1)*0.55,1.55,-2.2)
	if state == "depart": return feeding.lerp(outgoing,u)+Vector3(0,sin(u*PI)*0.5,0)
	if state == "return":
		var behind := Vector3((index%2*2-1)*1.15,1.9,1.3)
		return outgoing.lerp(behind,u*2) if u<0.5 else behind.lerp(perch,(u-0.5)*2)
	return perch

func purse_pose(e: Dictionary) -> Dictionary:
	var twist := 0.0
	var arm := Vector3(0,0,-0.12)
	if e.state == "warning":
		var u := smoothstep(0,1,clampf(float(e.time)/DURATIONS.purse[0],0,1))
		twist = -0.30*u
		arm = Vector3(PI/2,-1.45,0)*u
	elif e.state == "attack":
		var u := smoothstep(0,1,clampf(float(e.time)/DURATIONS.purse[1],0,1))
		twist = lerpf(-0.3,0.40,u)
		arm = Vector3(PI/2,lerpf(-1.45,1.25,u),0)
	elif e.state == "recovery":
		var u := smoothstep(0,1,clampf(float(e.time)/0.45,0,1))
		twist = 0.4*(1-u)
		arm = Vector3(PI/2,1.25,0)*(1-u)
	return {"twist":twist,"arm":arm}

func danger_points(e: Dictionary) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var anchor: Node3D = e.anchor
	if e.kind == "ice_duet":
		var radius := float(e.spec.get("radius",2.5))
		for side in [-1,1]:
			var angle: float = float(e.clock)*0.75+(PI if side == -1 else 0)
			points.append(anchor.transform*Vector3(cos(angle)*radius,0,sin(angle)*radius))
	elif e.kind == "pigeons":
		if e.state in ["swoop","feed"]:
			for i in range(7):
				var point := bird_local(e,i)
				point.y = 0 # Low flock collision height; airborne departures are harmless.
				points.append(anchor.transform*point)
	elif e.state == "attack":
		var u := clampf(float(e.time)/float(DURATIONS[e.kind][1]),0,1)
		var p := Vector3(0,0,-0.45-2.3*sin(u*PI*0.5))
		if e.kind == "purse":
			var pose_data := purse_pose(e)
			p = Basis(Vector3.UP,pose_data.twist)*(Vector3(0.29,1.17,0)+Basis.from_euler(pose_data.arm)*Vector3(0,-0.95,0))
			p.y = 0
		points.append(anchor.transform*p)
	return points

# Also used by read-only test forecasts on copied encounter dictionaries.
func advance_state(e: Dictionary, delta: float, player_position: Vector3) -> void:
	e.clock += delta
	if e.kind == "ice_duet": return
	if e.state == "idle":
		if player_position.distance_to(e.anchor.position)<6.0:
			e.state = "seed" if e.kind == "pigeons" else "warning"
			e.time = 0.0
		return
	e.time += delta
	if e.kind == "pigeons":
		var phase: int = BIRD_PHASES.find(e.state)
		if e.time>=BIRD_TIMES[phase]:
			e.time -= BIRD_TIMES[phase]
			e.state = BIRD_PHASES[(phase+1)%BIRD_PHASES.size()]
			if e.state == "seed" and player_position.distance_to(e.anchor.position)>9.0: e.state = "idle"
	else:
		var phase: int = ["warning","attack","recovery"].find(e.state)
		if e.time>=DURATIONS[e.kind][phase]:
			e.time -= DURATIONS[e.kind][phase]
			e.state = ["attack","recovery","idle"][phase]

func step(delta: float) -> void:
	contacts.clear()
	if delta<=0: return
	var cursor := 0.0
	while cursor<delta-0.000001:
		var dt := minf(1.0/120.0,delta-cursor)
		for e in encounters:
			var before := danger_points(e)
			advance_state(e,dt,world.player.position if world.player != null else Vector3(10000,0,0))
			var after := danger_points(e)
			for i in range(after.size()):
				contacts.append({"from":before[i] if i<before.size() else after[i],"to":after[i],
					"start":cursor/delta,"end":(cursor+dt)/delta,"radius":0.32 if e.kind == "pigeons" else (0.42 if e.kind == "ice_duet" else 0.37),"kind":e.kind})
		cursor += dt
	clock += delta
	for e in encounters: pose(e)

func pose(e: Dictionary) -> void:
	var people: Array = e.people
	if e.kind == "ice_duet":
		var points := danger_points(e)
		for i in range(2):
			var person: Node3D = people[i]
			person.position = e.anchor.transform.affine_inverse()*points[i]
			person.rotation.y = -float(e.clock)*0.75-i*PI
			person.rotation.z = 0.12
			person.get_node("LeftArm").rotation.z = -1.1
			person.get_node("RightArm").rotation.z = 1.1
			person.get_node("LeftLeg").rotation.x = sin(float(e.clock)*2)*0.18
			person.get_node("RightLeg").rotation.x = -sin(float(e.clock)*2)*0.18
		return
	var person: Node3D = people[0]
	person.position = Vector3.ZERO
	person.rotation = Vector3.ZERO
	var right: Node3D = person.get_node("RightArm")
	var left: Node3D = person.get_node("LeftArm")
	right.rotation = Vector3.ZERO
	left.rotation = Vector3.ZERO
	if e.kind == "ambusher":
		var attack: bool = e.state == "attack"
		var u := clampf(float(e.time)/DURATIONS.ambusher[1],0,1)
		if attack: person.position.z = -2.3*sin(u*PI*0.5)
		elif e.state == "recovery": person.position.z = lerpf(-2.3,0,smoothstep(0,1,clampf(float(e.time)/0.5,0,1)))
		right.rotation.x = 1.5 if attack else (-0.65 if e.state == "warning" else 0.0)
		person.rotation.x = -0.18 if attack else (-0.10 if e.state == "warning" else 0.0)
		person.get_node("LeftLeg").rotation.x = sin(float(e.clock)*28)*0.5 if attack else 0.0
		person.get_node("RightLeg").rotation.x = -person.get_node("LeftLeg").rotation.x
	elif e.kind == "purse":
		var data := purse_pose(e)
		person.rotation.y = data.twist
		right.rotation = data.arm
		left.rotation.z = -0.45 if e.state in ["warning","attack"] else -0.1
		person.get_node("LeftLeg").rotation.x = -0.18 if e.state == "attack" else 0.0
		person.get_node("RightLeg").rotation.x = 0.16 if e.state == "attack" else 0.0
	else:
		var toss: bool = e.state == "seed"
		var u := clampf(float(e.time)/BIRD_TIMES[0],0,1) if toss else 1.0
		right.rotation.x = lerpf(-0.5,1.3,sin(u*PI*0.5)) if toss else 0.15
		for i in range(e.seeds.size()):
			var seed: Node3D = e.seeds[i]
			var target := Vector3(sin(i*2.4)*0.70,0.065,-2.7-float(i%4)*0.3)
			seed.visible = e.state in ["seed","swoop","feed"]
			seed.position = Vector3(0.3,0.9,-0.3).lerp(target,u)+Vector3(0,sin(u*PI)*0.7,0) if toss else target
			seed.scale = Vector3(0.12,0.075,0.12)*((1.0-clampf(float(e.time)/BIRD_TIMES[2],0,1)*0.8) if e.state == "feed" else 1.0)
		for i in range(e.birds.size()):
			var bird: Node3D = e.birds[i]
			bird.position = bird_local(e,i)
			var flying: bool = e.state in ["swoop","depart","return"]
			bird.rotation.x = 0.38*maxf(0,sin(float(e.clock)*23+i)) if e.state == "feed" else 0.0
			bird.rotation.y = PI if e.state == "return" else 0.0
			bird.get_node("WingL").rotation.z = sin(float(e.clock)*28+i)*0.9 if flying else 0.0
			bird.get_node("WingR").rotation.z = -bird.get_node("WingL").rotation.z

func hits_player(from: Vector3, to: Vector3) -> String:
	for contact in contacts:
		var a: Vector3 = from.lerp(to,contact.start)-contact.from
		var b: Vector3 = from.lerp(to,contact.end)-contact.to
		if minf(a.y,b.y)>0.95 or maxf(a.y,b.y)<-0.8: continue
		var nearest := Geometry2D.get_closest_point_to_segment(Vector2.ZERO,Vector2(a.x,a.z),Vector2(b.x,b.z))
		if nearest.length()<float(contact.radius)+0.32:
			return {"ambusher":"BUSH AMBUSH!","purse":"PURSE WHACK!","pigeons":"PIGEON PILEUP!","ice_duet":"ICE COLLISION!"}[contact.kind]
	return ""

func get_hint() -> String:
	for e in encounters:
		if e.state == "warning": return "Rustling bush — quick lunge!" if e.kind == "ambusher" else "Purse drawn back — quick swing!"
		if e.kind == "pigeons" and e.state == "seed": return "Seed toss — pigeons are about to crowd that spot!"
	return ""
