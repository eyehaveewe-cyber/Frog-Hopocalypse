extends SceneTree
## Actual motion/pose checks, using the real CharacterBody controller.
const World=preload("res://scripts/world.gd")
const Data=preload("res://scripts/level_data.gd")
var checks:=0
var failures:=0
var world:Node3D
func check(ok:bool,message:String)->void:
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error(message)
func _initialize()->void:call_deferred("run")
func setup(mode:String="skate",extra:Dictionary={})->void:
	if is_instance_valid(world):world.free()
	world=World.new();root.add_child(world)
	var map:=Data.blank("Trick QA","nyc",25,25)
	map.spawn=[12,20];map.city_journey={"movement":mode}
	for key in extra:map.city_journey[key]=extra[key]
	world.load_level(map,false,"morning","purple_white")
	world.set_physics_process(false)
	await physics_frame;await physics_frame
func tick(delta:float,input:Vector2,jump:bool=false,grind:bool=false)->void:
	world.journey.step(delta,input,jump,false,grind)
	world.elapsed+=delta
	await physics_frame
func run()->void:
	await setup()
	await tick(1.0/60,Vector2.UP)
	check(world.journey.stats().rider_pose=="standing","Skateboard rider uses standing pose on ground")
	check(world.player.visual.get_node("HatSocket/MorningHat").visible,"Equipped outfit remains visible while skating")
	var finishes: Array=[]
	for hz in [30,60,120]:
		for side in [-1,1]:
			await setup()
			var dt:=1.0/float(hz)
			for i in range(hz/3):await tick(dt,Vector2.UP)
			await tick(dt,Vector2.UP,true)
			check(world.journey.airborne,"Jump becomes airborne at %d Hz, side %d"%[hz,side])
			await tick(dt,Vector2(float(side),-1).normalized())
			var initial:Dictionary=world.journey.stats()
			check(initial.trick_direction==side and initial.rider_pose==("trick_left" if side<0 else "trick_right"),"Directional jump picks the correct trick at %d Hz"%hz)
			check(initial.trick_name==("kickflip" if side<0 else "shove-it"),"Zendelves trick identity matches side %d"%side)
			for i in range(hz/10):await tick(dt,Vector2(float(-side),-1).normalized())
			check(world.journey.stats().trick_direction==side,"Opposite steering cannot start a second trick in same jump at %d Hz"%hz)
			var guard:=0
			while world.journey.airborne and guard<hz*3:
				await tick(dt,Vector2.ZERO);guard+=1
			check(not world.journey.airborne and world.journey.stats().rider_pose=="standing" and world.journey.stats().trick_direction==0,"Landing clears trick and restores standing at %d Hz"%hz)
			finishes.append({"hz":hz,"side":side,"position":world.player.position})
	for side in [-1,1]:
		var a:Vector3=finishes.filter(func(v):return v.hz==30 and v.side==side)[0].position
		var b:Vector3=finishes.filter(func(v):return v.hz==120 and v.side==side)[0].position
		check(a.distance_to(b)<0.5,"Trick physics stays consistent across 30–120 Hz for side %d"%side)
	for side in [-1,1]:
		await setup()
		await tick(1.0/60,Vector2.UP,true)
		for i in range(29): await tick(1.0/60,Vector2.UP)
		check(world.journey.airborne,"Late trick test begins while airborne")
		await tick(1.0/60,Vector2(float(side),-1).normalized())
		var last_rotation: Quaternion=world.journey.board.quaternion
		var landing_delta:=0.0
		var guard:=0
		while world.journey.airborne and guard<90:
			await tick(1.0/60,Vector2.ZERO)
			if not world.journey.airborne:
				landing_delta=last_rotation.angle_to(world.journey.board.quaternion)
			else: last_rotation=world.journey.board.quaternion
			guard+=1
		print("Late trick landing rotation delta, side %d: %.3f rad"%[side,landing_delta])
		check(landing_delta<0.5,"Late trick board settles smoothly on touchdown, side %d"%side)
	for kind in ["ramp","rail"]:
		for side in [-1,1]:
			var extra:Dictionary={"ramps":[{"from":[12,18],"to":[12,16],"rise":0.8}]} if kind=="ramp" else {"rails":[{"from":[12,18],"to":[12,12],"height":0.75}]}
			await setup("skate",extra)
			var guard:=0
			while guard<400 and ((world.journey.ramps_used==0) if kind=="ramp" else (world.journey.grind_index<0 or world.journey.grind_mount)):
				await tick(1.0/60,Vector2.UP,false,kind=="rail");guard+=1
			check(guard<400,"Reach %s launch with ordinary movement"%kind)
			if kind=="rail": await tick(1.0/60,Vector2.UP,true)
			guard=0
			while world.journey.airborne and world.journey.vertical_speed > -2.0 and guard<180:
				await tick(1.0/60,Vector2.UP);guard+=1
			check(world.journey.airborne,"%s trick starts late while descending"%kind)
			await tick(1.0/60,Vector2(float(side),-1).normalized())
			var last:Quaternion=world.journey.board.quaternion
			var delta_angle:=0.0
			guard=0
			while world.journey.airborne and guard<180:
				await tick(1.0/60,Vector2.ZERO)
				if not world.journey.airborne:delta_angle=last.angle_to(world.journey.board.quaternion)
				else:last=world.journey.board.quaternion
				guard+=1
			print("Late %s trick landing rotation, side %d: %.3f rad"%[kind,side,delta_angle])
			check(guard<180 and delta_angle<0.5,"Late %s trick lands smoothly, side %d"%[kind,side])
	await setup("walk")
	var before:Vector3=world.player.visual.rotation
	await tick(1.0/60,Vector2.UP)
	check(not world.journey.is_skating() and not world.journey.stats().rider_pose.begins_with("trick"),"Walking levels do not acquire skateboard tricks")
	check(world.player.visual.rotation.distance_to(before)<0.5,"Walking frog retains ordinary pose")
	world.free()
	print("SKATE FROG TRICKS: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
