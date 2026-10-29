extends Node3D
## Optional traversal for the City Journey levels. Ordinary campaigns keep Actor.step.
## Heights are authored game geometry in metres, with the same swept body collision
## as walking: a skateboard only clears a wall when its body is physically above it.
const Art = preload("res://scripts/art.gd")
const Kit = preload("res://scripts/nyc_streetlife_art.gd")
const CELL := 1.8
const GRAVITY := 12.0
const SKATE_SPEED := 7.5
var world: Node3D
var config: Dictionary
var momentum := Vector3.ZERO
var vertical_speed := 0.0
var airborne := false
var on_ice := false
var surface_height := 0.0
var bridge_index := -1
var grind_index := -1
var grind_direction := 1.0
var grind_mount := false
var grind_mount_target := Vector3.ZERO
var grind_armed := false
var jump_held := false
var launch_cooldown := 0.0
var board: Node3D
var facing := Vector3(0,0,-1)
var ramps_used := 0
var rails_used := 0
# Zendelves e351fcb7: procedural kickflip/shove-it, adapted to this frog rig.
const TRICK_DURATION := 0.75
var trick_direction := 0
var trick_elapsed := 0.0
var trick_duration := TRICK_DURATION
var trick_full_turn := true
var trick_amplitude := TAU
var lateral_input := 0
var skate_rest: Dictionary = {}
var rider_pose := "standing"
var board_wheels: Array[Node] = []

func setup(level: Dictionary, owner_world: Node3D) -> void:
	name = "CityJourney"
	world = owner_world
	config = level.get("city_journey", {}).duplicate(true)
	build_geometry()
	Art.batch_static(self, [], CELL*6)
	if is_skating():
		var donor := Kit.skater(0)
		board = donor.get_node("Board")
		donor.remove_child(board)
		donor.free()
		world.player.add_child(board)
		board.scale = Vector3(2.8,1.0,1.4)
		board_wheels = board.find_children("Wheel_*","Node3D",true,false)
		for part in world.player.visual.get_children():
			if part is Node3D: skate_rest[part] = part.transform
		pose(0.0)

func is_skating() -> bool:
	return config.get("movement", "walk") == "skate"

func grid_point(p: Vector3) -> Vector2:
	return Vector2(p.x/CELL+(world.level.width-1)*0.5,p.z/CELL+(world.level.height-1)*0.5)

func rect_has(rect: Array, p: Vector2) -> bool:
	return p.x >= rect[0]-0.5 and p.x <= rect[2]+0.5 and p.y >= rect[1]-0.5 and p.y <= rect[3]+0.5

func bridge_height(bridge: Dictionary, p: Vector2) -> float:
	var axis := 0 if bridge.get("axis", "z") == "x" else 1
	var rect: Array = bridge.rect
	var edge_distance := minf(p[axis]-(float(rect[axis])-0.5),float(rect[axis+2])+0.5-p[axis])
	return float(bridge.height)*clampf(edge_distance/float(bridge.ramp_cells),0,1)

func ramp_sample(ramp: Dictionary, position: Vector3) -> Dictionary:
	var start: Vector3 = world.cell_position(ramp.from)
	var end: Vector3 = world.cell_position(ramp.to)
	var forward := (end-start).normalized()
	var offset := position-start
	var along := offset.dot(forward)
	var width_distance := (offset-forward*along).length()
	return {"start":start,"end":end,"forward":forward,"along":along,"length":start.distance_to(end),"inside":along>=0 and along<=start.distance_to(end) and width_distance<=CELL*0.9}

func support_height(p: Vector3) -> float:
	var grid := grid_point(p)
	var bridges: Array = config.get("bridges", [])
	if bridge_index >= 0 and not rect_has(bridges[bridge_index].rect,grid): bridge_index = -1
	for i in range(bridges.size()):
		if not rect_has(bridges[i].rect,grid): continue
		var height := bridge_height(bridges[i],grid)
		# Enter at a ramp foot; crossing underneath a deck never lifts the frog.
		if i == bridge_index or height <= world.player.position.y+0.35:
			bridge_index = i
			return height
	for rail in config.get("rails",[]):
		for endpoint in ["entry","exit"]:
			if not rail.has(endpoint): continue
			var foot: Vector3 = world.cell_position(rail[endpoint])
			var lip: Vector3 = world.cell_position(rail.from if endpoint == "entry" else rail.to)
			var nearest := Geometry3D.get_closest_point_to_segment(Vector3(p.x,0,p.z),foot,lip)
			if Vector2(nearest.x-p.x,nearest.z-p.z).length()<0.75:
				var fraction := foot.distance_to(nearest)/foot.distance_to(lip)
				var height := float(rail.height)*fraction
				if not airborne or p.y>=height-0.1: return height
	for ramp in config.get("ramps", []):
		var sample := ramp_sample(ramp,p)
		if sample.inside and (not airborne or world.player.position.y >= float(ramp.rise)*sample.along/sample.length-0.1):
			return float(ramp.rise)*sample.along/sample.length
	return 0.0

func step(delta: float, input: Vector2, jump: bool, brake: bool, grind: bool = false) -> void:
	var actor: CharacterBody3D = world.player
	var desired := Vector3(input.x,0,input.y).limit_length()
	var pressed := jump and not jump_held
	jump_held = jump
	launch_cooldown = maxf(0,launch_cooldown-delta)
	grind_armed = grind
	on_ice = false
	for ice in config.get("ice", []):
		if rect_has(ice.rect,grid_point(actor.position)): on_ice = true
	for island in config.get("islands",[]):
		if rect_has(island.rect,grid_point(actor.position)): on_ice = false
	if desired.length_squared()>0.01: facing=desired
	if grind_index >= 0:
		advance_grind(delta,desired,pressed,brake)
		update_trick(delta,input)
		pose(delta)
		return
	var target_speed := SKATE_SPEED if is_skating() else 4.2
	if brake:
		momentum = momentum.move_toward(Vector3.ZERO,18.0*delta)
	elif is_skating() or on_ice:
		if desired.length_squared()>0.001:
			momentum=momentum.move_toward(desired*target_speed,(2.6 if on_ice else (3.0 if airborne else 10.0))*delta)
		else:
			momentum=momentum.move_toward(Vector3.ZERO,(0.45 if on_ice else 1.15)*delta)
	else:
		momentum=desired*target_speed
	if pressed and is_skating() and not airborne:
		vertical_speed=4.4
		airborne=true
		bridge_index=-1
	if is_skating() and grind and not brake and launch_cooldown<=0 and momentum.length()>1.0:
		for i in range(config.get("rails",[]).size()):
			var rail: Dictionary = config.rails[i]
			var start: Vector3 = world.cell_position(rail.from)+Vector3(0,float(rail.height),0)
			var end: Vector3 = world.cell_position(rail.to)+Vector3(0,float(rail.height),0)
			var forward := (end-start).normalized()
			var nearest := Geometry3D.get_closest_point_to_segment(actor.position,start,end)
			var alignment := momentum.normalized().dot(forward)
			if actor.position.distance_to(nearest)<1.12 and absf(alignment)>0.65:
				grind_index = i
				grind_direction = signf(alignment)
				grind_mount = true
				grind_mount_target = nearest
				rails_used += 1
				airborne = false
				momentum = forward*grind_direction*maxf(4.8,momentum.length())
				pose(delta)
				return
	var before:=actor.position
	var proposed:=before+momentum*delta
	var support:=support_height(proposed)
	if is_skating() and not airborne and launch_cooldown<=0 and momentum.length()>=2.5:
		for ramp in config.get("ramps",[]):
			var old_sample:=ramp_sample(ramp,before)
			var next_sample:=ramp_sample(ramp,proposed)
			if old_sample.inside and next_sample.along>next_sample.length and momentum.dot(next_sample.forward)>2.5:
				airborne=true
				vertical_speed=6.8
				launch_cooldown=0.45
				ramps_used+=1
				break
	if not airborne and support<before.y-0.35:
		airborne=true
		vertical_speed=0.0
	var vertical_motion:=support-before.y
	if airborne:
		vertical_motion=vertical_speed*delta-0.5*GRAVITY*delta*delta
		vertical_speed-=GRAVITY*delta
	sweep_move(momentum*delta+Vector3(0,vertical_motion,0))
	if airborne and actor.position.y<=support and vertical_speed<=0:
		actor.position.y=support
		vertical_speed=0
		airborne=false
	elif not airborne:
		actor.position.y=support_height(actor.position)
	surface_height=support_height(actor.position)
	actor.velocity=momentum+Vector3(0,vertical_speed,0)
	update_trick(delta,input)
	pose(delta)

func sweep_move(motion: Vector3) -> void:
	var actor: CharacterBody3D=world.player
	var hit:=actor.move_and_collide(motion)
	if hit:
		var normal:=hit.get_normal()
		if absf(normal.y)<0.7:
			momentum=momentum.slide(normal)
		elif normal.y<0 and vertical_speed>0: vertical_speed=0
		actor.move_and_collide(hit.get_remainder().slide(normal))

func advance_grind(delta: float, input: Vector3, jump: bool, brake: bool) -> void:
	var rail: Dictionary=config.rails[grind_index]
	var start: Vector3=world.cell_position(rail.from)
	var end: Vector3=world.cell_position(rail.to)
	var forward: Vector3=(end-start).normalized()*grind_direction
	var target: Vector3=(end if grind_direction>0 else start)+Vector3(0,float(rail.height),0)
	if grind_mount:
		var entry: Vector3=grind_mount_target
		var mount_motion: Vector3=entry-world.player.position
		sweep_move(mount_motion.limit_length(6.0*delta))
		if world.player.position.distance_to(entry)<0.02: grind_mount=false
		return
	var remaining: float=(target-world.player.position).dot(forward)
	if jump or brake or input.dot(forward)<-0.4 or remaining<=0.15:
		grind_index=-1
		airborne=true
		vertical_speed=4.4 if jump else 0.0
		launch_cooldown=0.4
		return
	momentum=forward*6.0
	sweep_move(forward*minf(remaining,6.0*delta))
	world.player.position.y=float(rail.height)
	surface_height=float(rail.height)

func update_trick(delta: float, input: Vector2) -> void:
	var lateral := -1 if input.x < -0.55 else (1 if input.x > 0.55 else 0)
	if not is_skating(): return
	if not airborne:
		trick_direction = 0
		trick_elapsed = 0.0
	elif trick_direction == 0 and lateral != 0 and lateral != lateral_input:
		trick_direction = lateral
		trick_elapsed = 0.0
		# Anticipate touchdown using current ballistic state and support. Early
		# inputs complete a full turn; late ones use a smaller return-to-zero
		# flourish rather than visibly snapping an unfinished rotation on landing.
		var above := maxf(0.0,world.player.position.y-surface_height)
		var remaining := maxf(delta,(vertical_speed+sqrt(vertical_speed*vertical_speed+2.0*GRAVITY*above))/GRAVITY)
		trick_duration = minf(TRICK_DURATION,maxf(delta,remaining*0.85))
		trick_full_turn = remaining >= 0.40
		trick_amplitude = TAU if trick_full_turn else TAU*0.22*clampf(remaining/0.40,0.0,1.0)
	if airborne and trick_direction != 0:
		trick_elapsed = minf(trick_duration,trick_elapsed+delta)
	lateral_input = lateral

func pose(delta: float) -> void:
	var actor: CharacterBody3D = world.player
	var direction := momentum.normalized() if momentum.length_squared()>0.01 else facing
	actor.direction = direction
	actor.visual.rotation.y = lerp_angle(actor.visual.rotation.y,atan2(-direction.x,-direction.z),1.0-exp(-14.0*delta))
	if not is_skating():
		actor.visual.position.y = 0.02 if on_ice else absf(sin(world.elapsed*16))*0.10*minf(1,momentum.length())
		actor.visual.rotation.z = 0
		return
	# Move the original authored frog's independent limbs/body instead of
	# replacing its model: HatSocket, materials, skin and suit stay intact.
	for part in skate_rest:
		if not is_instance_valid(part): continue
		part.transform = skate_rest[part]
		var name: String = part.name
		if name.begins_with("HindLeg"):
			var side := -1.0 if name.ends_with("L") else 1.0
			part.position = Vector3(side*0.27,0.30,side*0.25)
			part.scale *= Vector3(0.80,1.5,0.72)
		elif name.begins_with("HindShin"):
			var side := -1.0 if name.ends_with("L") else 1.0
			part.visible = true
			part.position = Vector3(side*0.26,0.15,side*0.30)
			part.scale *= Vector3(1.0,2.1,0.60)
		elif name.begins_with("HindToe"):
			var side := -1.0 if name.contains("L") else 1.0
			var toe := int(name.right(1))
			part.position = Vector3(side*(0.21+toe*0.045),0.015,side*0.32)
			part.rotation.y = side*(toe-1)*0.2
		elif name.begins_with("ForeArm"):
			var side := -1.0 if name.ends_with("L") else 1.0
			part.position = Vector3(side*0.53,0.62,-0.12)
			part.rotation = Vector3(0,side*PI/2,side*0.15)
		elif name.begins_with("ForeToe"):
			var side := -1.0 if name.contains("L") else 1.0
			var toe := int(name.right(1))
			part.position = Vector3(side*(0.72+toe*0.03),0.62,-0.16+toe*0.05)
			part.rotation = Vector3(0,side*PI/2,side*0.15)
		else:
			part.position.y += 0.44
			if part is MeshInstance3D and part.scale.x>0.6 and part.scale.z>0.5:
				part.scale.y *= 1.25
	var progress := clampf(trick_elapsed/trick_duration,0,1)
	var eased := smoothstep(0.0,1.0,progress)
	var hop := sin(progress*PI) if trick_direction != 0 else 0.0
	var rotation_amount := trick_amplitude*(eased if trick_full_turn else hop)
	actor.visual.position.y = 0.20+hop*0.18
	actor.visual.rotation.x = -0.08 if airborne else 0.03*sin(world.elapsed*6.0)*minf(momentum.length()/5.0,1.0)
	actor.visual.rotation.z = (sin(world.elapsed*8)*0.075 if grind_index>=0 else 0.0) + trick_direction*hop*0.12
	rider_pose = "grind" if grind_index>=0 else ("trick_left" if trick_direction<0 else ("trick_right" if trick_direction>0 else ("jump" if airborne else "standing")))
	if is_instance_valid(board):
		board.position.y = -0.08*hop
		board.rotation = Vector3(0,actor.visual.rotation.y,0)
		# Zendelves's kickflip spins around the board's long axis; its shove-it
		# spins around the vertical axis. Both settle back to the same deck pose.
		if trick_direction<0: board.rotate_object_local(Vector3.FORWARD,rotation_amount)
		elif trick_direction>0: board.rotate_object_local(Vector3.UP,rotation_amount)
		elif airborne and vertical_speed>0: board.rotation.x=-0.10
		for wheel in board_wheels: wheel.rotation.x -= momentum.length()*delta/0.065

func stats() -> Dictionary:
	return {"movement":config.get("movement","walk"),"speed":momentum.length(),"airborne":airborne,"grinding":grind_index>=0,"ice":on_ice,"surface_height":surface_height,"ramps_used":ramps_used,"rails_used":rails_used,"grind_armed":grind_armed,"rider_pose":rider_pose,"trick_direction":trick_direction,"trick_name":"kickflip" if trick_direction<0 else ("shove-it" if trick_direction>0 else ""),"trick_progress":clampf(trick_elapsed/trick_duration,0,1)}

func build_geometry() -> void:
	for ice in config.get("ice",[]):
		var rect: Array = ice.rect
		for y in range(int(rect[1]),int(rect[3])+1):
			for x in range(int(rect[0]),int(rect[2])+1):
				if world.level.tiles[y][x] in ["wall","water"]: continue
				var island_cell := false
				for island in config.get("islands",[]):
					if rect_has(island.rect,Vector2(x,y)): island_cell = true
				if island_cell: continue
				var center: Vector3 = world.cell_position([x,y])
				Art.box(self,Vector3(CELL,0.025,CELL),center+Vector3(0,0.018,0),Color("a9d9e5"))
				if (x+y*3)%7 == 0:
					var crack := Art.box(self,Vector3(0.025,0.006,CELL*0.6),center+Vector3(0,0.035,0),Color("d8f4f1"))
					crack.rotation.y = 0.55
	for island in config.get("islands",[]):
		var r: Array = island.rect
		var a: Vector3 = world.cell_position([r[0],r[1]])
		var b: Vector3 = world.cell_position([r[2],r[3]])
		Art.box(self,Vector3(b.x-a.x+CELL,0.025,b.z-a.z+CELL),(a+b)*0.5+Vector3(0,0.018,0),Color("d1b887"))
	for bridge in config.get("bridges",[]): build_bridge(bridge)
	for ramp in config.get("ramps",[]):
		var a: Vector3=world.cell_position(ramp.from)
		var b: Vector3=world.cell_position(ramp.to)+Vector3(0,float(ramp.rise),0)
		slope_panel(a,b,CELL*1.8,Color("d6ad68"))
		Kit.bar(self,"RampLip",b+Vector3(-0.1,0.04,0),b+Vector3(0.1,0.04,0),0.09,Color("ffe59c"))
	for rail in config.get("rails",[]):
		var a: Vector3=world.cell_position(rail.from)+Vector3(0,float(rail.height),0)
		var b: Vector3=world.cell_position(rail.to)+Vector3(0,float(rail.height),0)
		Kit.bar(self,"RideableRail",a,b,0.20,Color("e8c674"))
		for point in [a,a.lerp(b,0.5),b]:
			Art.box(self,Vector3(0.08,point.y,0.08),Vector3(point.x,point.y*0.5,point.z),Color("637d85"))
		var direction: Vector3=(b-a).normalized()
		var entry: Vector3 = world.cell_position(rail.entry) if rail.has("entry") else a-direction*0.9-Vector3(0,a.y,0)
		var exit: Vector3 = world.cell_position(rail.exit) if rail.has("exit") else b+direction*0.9-Vector3(0,b.y,0)
		slope_panel(entry,a,1.1,Color("738e91"))
		slope_panel(b,exit,1.1,Color("738e91"))
		Art.cylinder(self,0.28,0.28,0.06,entry+Vector3(0,0.06,0),Color("6fe0db"))
	for building in config.get("buildings",[]):
		var rect: Array=building.rect
		var a: Vector3=world.cell_position([rect[0],rect[1]])
		var b: Vector3=world.cell_position([rect[2],rect[3]])
		var height: float=building.get("height",4.0)
		var center: Vector3=(a+b)*0.5
		var size:=Vector3(b.x-a.x+CELL,height,b.z-a.z+CELL)
		Art.textured(Art.box(self,size,center+Vector3(0,height*0.5,0),Color("80777a")),"brick")
		Art.box(self,size*Vector3(1.02,0,1.02)+Vector3(0,0.18,0),center+Vector3(0,height,0),Color("b6b8ae"))
		for side in [-1,1]:
			for floor_index in range(1,int(height)):
				for x in range(int(rect[0]),int(rect[2])+1,2):
					var p: Vector3=world.cell_position([x,rect[1]])
					p.z=center.z+side*(size.z*0.5+0.02)
					p.y=floor_index+0.3
					Art.box(self,Vector3(0.65,0.55,0.03),p,Color("d6ce9a"))

func slope_panel(a: Vector3,b: Vector3,width: float,color: Color) -> void:
	var length:=a.distance_to(b)
	var panel:=Art.box(self,Vector3(width,0.12,length),(a+b)*0.5-Vector3(0,0.06,0),color)
	panel.look_at(b)

func build_bridge(bridge: Dictionary) -> void:
	var rect: Array=bridge.rect
	var axis:=0 if bridge.get("axis","z")=="x" else 1
	var other:=1-axis
	var center:=Vector2((rect[0]+rect[2])*0.5,(rect[1]+rect[3])*0.5)
	var stations: Array=[float(rect[axis])-0.5,float(rect[axis])-0.5+float(bridge.ramp_cells),float(rect[axis+2])+0.5-float(bridge.ramp_cells),float(rect[axis+2])+0.5]
	var heights: Array=[0.0,float(bridge.height),float(bridge.height),0.0]
	var width: float=(float(rect[other+2])-float(rect[other])+1)*CELL
	for i in range(3):
		var ag:=center;ag[axis]=stations[i]
		var bg:=center;bg[axis]=stations[i+1]
		var a: Vector3=world.cell_position([ag.x,ag.y])+Vector3(0,heights[i],0)
		var b: Vector3=world.cell_position([bg.x,bg.y])+Vector3(0,heights[i+1],0)
		slope_panel(a,b,width,Color("929d99"))
		for side in [-1,1]:
			var lateral:=Vector3.ZERO;lateral[0 if other==0 else 2]=side*width*0.5
			Kit.bar(self,"BridgeGuardrail",a+lateral+Vector3(0,0.65,0),b+lateral+Vector3(0,0.65,0),0.10,Color("e5cd87"))
			var body:=Art.solid(self,Vector3(0.10,0.8,a.distance_to(b)),(a+b)*0.5+lateral+Vector3(0,0.4,0))
			body.look_at(b+lateral+Vector3(0,0.4,0))
			for point in [a,b]:
				Art.box(self,Vector3(0.09,0.75,0.09),point+lateral+Vector3(0,0.375,0),Color("657b7b"))
