extends SceneTree
const Data = preload("res://scripts/level_data.gd")
const World = preload("res://scripts/world.gd")
var checks := 0
var failures := 0
var world:Node3D
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok: failures+=1;push_error(message)
	else: print("PASS: "+message)
func _initialize()->void:call_deferred("run")
func reset_world(config:Dictionary={"movement":"skate"},spawn:Array=[1,11])->void:
	if is_instance_valid(world):world.free()
	world=World.new();root.add_child(world)
	var level:=Data.blank("Skate rig test","nyc",25,25)
	level.city_journey=config
	level.spawn=spawn
	world.load_level(level,false,"morning","purple_white")
	world.set_physics_process(false)
	await physics_frame
func tick(input:Vector2,jump:bool=false,dt:float=1.0/60)->void:
	world.journey.step(dt,input,jump,false)
	world.elapsed += dt
	await physics_frame
func run()->void:
	await reset_world()
	var frog:Node3D=world.player.visual
	check(frog.get_node("HatSocket/MorningHat").visible,"Standing rider retains equipped morning hat")
	check(frog.get_node("HatSocket").position.y>1.0,"Head and hat are raised into standing stance")
	check(frog.get_node("HindShinL").visible and frog.get_node("HindShinR").visible,"Both legs support standing frog")
	check(absf(frog.position.y+frog.get_node("HindToeL0").position.y*frog.scale.y-0.185)<0.08,"Rider feet meet skateboard deck")
	await tick(Vector2.UP,true)
	await tick(Vector2.LEFT,false)
	check(world.journey.stats().trick_name=="kickflip" and world.journey.stats().rider_pose=="trick_left","Fresh left while airborne starts kickflip")
	var before:Basis=world.journey.board.basis
	for i in range(12):await tick(Vector2.LEFT)
	check(not world.journey.board.basis.is_equal_approx(before),"Kickflip visibly rotates board")
	await tick(Vector2.RIGHT)
	check(world.journey.stats().trick_name=="kickflip","Second direction cannot retrigger in same jump")
	for i in range(80):await tick(Vector2.ZERO)
	check(not world.journey.airborne and world.journey.stats().rider_pose=="standing" and world.journey.stats().trick_name=="","Landing restores standing rider and resets trick")
	await tick(Vector2.UP,true)
	await tick(Vector2.RIGHT)
	check(world.journey.stats().trick_name=="shove-it" and world.journey.stats().rider_pose=="trick_right","Fresh right while airborne starts shove-it")
	var yaw_before:float=world.journey.board.rotation.y
	for i in range(10):await tick(Vector2.RIGHT)
	check(absf(angle_difference(yaw_before,world.journey.board.rotation.y))>0.1,"Shove-it spins board on vertical axis")
	await reset_world()
	await tick(Vector2.LEFT)
	await tick(Vector2.LEFT,true)
	check(world.journey.airborne and world.journey.trick_direction==0,"Direction held before jump stays ordinary steering")
	await tick(Vector2.ZERO)
	await tick(Vector2.LEFT)
	check(world.journey.trick_direction==-1,"Release and repress during jump triggers trick")
	for launch in ["ramp","rail"]:
		for side in [-1,1]:
			if launch=="ramp":
				await reset_world({"movement":"skate","ramps":[{"from":[12,18],"to":[12,16],"rise":0.8}]},[12,22])
				for i in range(200):
					await tick(Vector2.UP)
					if world.journey.airborne:break
			else:
				await reset_world({"movement":"skate","rails":[{"from":[12,20],"to":[12,15],"height":0.65}]},[12,22])
				for i in range(200):
					world.journey.step(1.0/60,Vector2.UP,false,false,true)
					await physics_frame
					if world.journey.grind_index>=0 and not world.journey.grind_mount:break
				await tick(Vector2.UP,true)
			check(world.journey.airborne,launch+" launches rider into air")
			for i in range(100):
				if not world.journey.airborne:break
				if world.journey.vertical_speed<0 and world.player.position.y-world.journey.surface_height<0.5:break
				await tick(Vector2.UP)
			await tick(Vector2(float(side),-0.3).normalized())
			var last:Quaternion=world.journey.board.quaternion
			var difference:=0.0
			for i in range(100):
				if not world.journey.airborne:break
				await tick(Vector2.ZERO)
				if not world.journey.airborne:difference=last.angle_to(world.journey.board.quaternion)
				else:last=world.journey.board.quaternion
			check(not world.journey.airborne and difference<0.5,launch+" late trick settles on landing for side "+str(side)+" (%.3f rad)"%difference)
	world.free()
	print("SKATE FROG RIG: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
