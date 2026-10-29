extends SceneTree
## Actual CharacterBody3D sweeps through bridge/ramp/wall/rail geometry.
const World=preload("res://scripts/world.gd")
const Data=preload("res://scripts/level_data.gd")
const Skater=preload("res://scripts/skater.gd")
var checks:=0
var failures:Array[String]=[]
var world:Node3D

func _initialize()->void: call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if ok: print("PASS: "+label)
	else:
		failures.append(label)
		push_error(label)

func setup(config:Dictionary,spawn:Array=[12,22],wall_row:int=-1)->void:
	if is_instance_valid(world):
		world.queue_free()
		await process_frame
	world=World.new()
	root.add_child(world)
	var level:=Data.blank("Traversal test","nyc",25,25)
	level.spawn=spawn
	level.city_journey=config
	if wall_row>=0:
		for x in range(1,24):level.tiles[wall_row][x]="wall"
	world.load_level(level)
	world.set_physics_process(false)
	await physics_frame
	await physics_frame

func tick(input:Vector2,frames:int,jump:bool=false,brake:bool=false,delta:float=1.0/60.0,grind:bool=false)->void:
	for frame in range(frames):
		world.journey.step(delta,input,jump,brake,grind)
		world.elapsed+=delta
		await physics_frame

func run()->void:
	await setup({"movement":"walk","bridges":[{"rect":[10,4,12,20],"axis":"z","ramp_cells":3,"height":2.0}]},[11,22])
	await tick(Vector2(0,-1),230)
	check(absf(world.player.position.y-2.0)<0.02,"Walk up actual overpass ramp onto 2m deck")
	check(world.journey.bridge_index==0,"Bridge support stays attached across deck")
	await tick(Vector2(0,-1),260)
	check(world.player.position.y<0.05,"Walk down opposite ramp to street height")
	check(world.position_cell(world.player.position).y<4,"Cross full overpass without wall bypass or teleport")
	await setup({"movement":"walk","bridges":[{"rect":[10,4,12,20],"axis":"z","ramp_cells":3,"height":2.0}]},[8,12])
	await tick(Vector2(1,0),100)
	check(world.player.position.y<0.05,"Approaching bridge laterally stays underneath instead of snapping upward")
	await setup({"movement":"walk","ice":[{"rect":[3,3,21,21]}]},[12,18])
	await tick(Vector2(0,-1),90)
	var start:Vector3=world.player.position
	await tick(Vector2.ZERO,60)
	check(start.distance_to(world.player.position)>2.5,"Ice retains readable sliding momentum after input release")
	await tick(Vector2.ZERO,30,false,true)
	check(world.journey.momentum.length()<0.01,"Brake stops ice sliding under player control")
	await setup({"movement":"walk"},[12,18])
	await tick(Vector2(0,-1),90)
	start=world.player.position
	await tick(Vector2.ZERO,60)
	check(start.distance_to(world.player.position)<0.001,"Dry walking still stops promptly")
	await setup({"movement":"skate","ramps":[{"from":[12,18],"to":[12,16],"rise":0.8}]},[12,22],14)
	var peak:=0.0
	for frame in range(195):
		await tick(Vector2(0,-1),1)
		peak=maxf(peak,world.player.position.y)
	check(world.journey.ramps_used==1,"Forward ramp traversal launches once at lip")
	check(peak>2.5,"Ramp jump reaches visible clearance over wall")
	check(world.position_cell(world.player.position).y<14,"Actual swept body clears wall after ramp launch")
	check(not world.journey.airborne and world.player.position.y<0.01,"Ramp flight lands back on ground")
	await setup({"movement":"skate"},[12,22],14)
	await tick(Vector2(0,-1),220)
	check(world.position_cell(world.player.position).y>14,"Same wall still blocks skateboard without ramp")
	await tick(Vector2(0,-1),150,true)
	check(world.position_cell(world.player.position).y>14,"Ordinary ollie cannot bypass tall route wall")
	check(not world.journey.airborne,"Holding jump does not cause automatic repeated jumps")
	await setup({"movement":"skate","rails":[{"from":[12,20],"to":[12,15],"height":0.65}]},[12,22])
	var saw_grind:=false
	for frame in range(200):
		await tick(Vector2(0,-1),1,false,false,1.0/60.0,true)
		saw_grind=saw_grind or world.journey.grind_index>=0
	check(saw_grind and world.journey.rails_used==1,"Aligned approach mounts and grinds the authored rail")
	check(world.position_cell(world.player.position).y<15,"Grind exits rail forward into normal riding")
	check(not world.journey.airborne and world.player.position.y<0.01,"Rail exit returns safely to street")
	var finals:Array[Vector3]=[]
	for hz in [30,60,120]:
		await setup({"movement":"skate"},[12,22])
		await tick(Vector2(0,-1),hz*2,false,false,1.0/hz)
		finals.append(world.player.position)
	check(finals[0].distance_to(finals[2])<0.1,"30/60/120Hz acceleration travel agrees within 10cm")
	finals.clear()
	for hz in [30,60,120]:
		await setup({"movement":"skate","ramps":[{"from":[12,18],"to":[12,16],"rise":0.8}]},[12,22],14)
		await tick(Vector2(0,-1),hz*7/2,false,false,1.0/hz)
		check(world.position_cell(world.player.position).y<14 and not world.journey.airborne,"Ramp clears and lands past wall at %dHz"%hz)
		finals.append(world.player.position)
	check(finals[0].distance_to(finals[2])<0.15,"Ramp flight travel stays within 15cm between 30 and 120Hz")
	var skater:=Skater.new()
	skater.sweeps.assign([{"from":Vector3(-1,0,0),"to":Vector3(1,0,0),"t0":0.0,"t1":1.0}])
	check(not skater.hits_player(Vector3(0,2,0),Vector3(0,2,0)),"Ground skater cannot hit frog on overpass")
	check(skater.hits_player(Vector3.ZERO,Vector3.ZERO),"Ground skater remains dangerous at same height")
	skater.sweeps.assign([{"from":Vector3(-1,2,0),"to":Vector3(1,2,0),"t0":0.0,"t1":1.0}])
	check(not skater.hits_player(Vector3.ZERO,Vector3.ZERO),"Overpass skater cannot hit frog underneath")
	skater.free()
	world.queue_free()
	await process_frame
	print("City journey movement: %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
