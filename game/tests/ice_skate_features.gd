extends SceneTree
const World=preload("res://scripts/world.gd")
const Data=preload("res://scripts/level_data.gd")
var checks:=0
var failures:=0
var world:Node3D
func check(ok:bool,text:String)->void:
	checks+=1
	if ok: print("PASS: "+text)
	else: failures+=1;push_error(text)
func _initialize()->void:call_deferred("run")
func load_world(map:Dictionary)->void:
	if is_instance_valid(world):world.free()
	world=World.new();root.add_child(world);world.load_level(map);world.set_physics_process(false)
	await physics_frame;await physics_frame
func run()->void:
	for file in ["park_motion","bridge_motion","highway_grind"]:
		var fixture_map:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/"+file+".json"))
		check(Data.validate(fixture_map).is_empty(),"Runtime fixture validates: "+file)
	var fixture:=Data.blank("Manual rail","nyc",25,25)
	fixture.spawn=[12,22]
	fixture.city_journey={"movement":"skate","rails":[{"from":[12,20],"to":[12,15],"height":0.75}]}
	await load_world(fixture)
	for i in range(150):
		world.journey.step(1.0/60,Vector2.UP,false,false,false);await physics_frame
	check(world.journey.rails_used==0,"Passing a rail does not latch without Grind")
	await load_world(fixture)
	for i in range(150):
		world.journey.step(1.0/60,Vector2.UP,false,false,true);await physics_frame
	check(world.journey.rails_used==1,"Holding Grind latches the aligned rail once")
	await load_world(fixture)
	for i in range(150):
		world.journey.step(1.0/60,Vector2.UP,false,false,true);await physics_frame
		if world.journey.grind_index>=0 and not world.journey.grind_mount:break
	world.journey.step(1.0/60,Vector2.UP,true,false,false)
	check(world.journey.grind_index<0 and world.journey.airborne,"Jump releases rail into a physical airborne hop")
	fixture.city_journey.rails=[{"from":[12,17],"to":[12,9],"height":2.6,"entry":[12,21],"exit":[12,5]}]
	fixture.traffic=[]
	for row in [15,13]:
		for x in range(1,24):fixture.tiles[row][x]="road"
		fixture.traffic.append({"row":row,"direction":1,"speed":6,"spacing":12,"vehicles":["bus","truck"]})
	await load_world(fixture)
	var saw_high:=false;var hit:=false
	for i in range(430):
		var before:Vector3=world.player.position
		world.journey.step(1.0/60,Vector2.UP,false,false,true);world.traffic.step(1.0/60)
		hit=hit or world.traffic.hits_player(before,world.player.position)
		saw_high=saw_high or (world.journey.grind_index>=0 and world.player.position.y>2.5)
		await physics_frame
	check(saw_high and not hit,"Visible entry ramp and Grind carry frog above actual bus/truck lanes")
	check(world.position_cell(world.player.position).y<9,"Highway grind reaches the far side with swept collision")
	var ice:=Data.load_json("res://levels/city_journey_03_frozen_blocks.json")
	await load_world(ice)
	check(world.critters.size()==6 and world.skaters.size()==4 and world.park_hazards.encounters.size()==3,"Frozen Blocks instantiates roaches, island riders and three duet pairs")
	world.player.position=world.cell_position([20,50])
	world.journey.step(1.0/60,Vector2.ZERO,false,false)
	check(not world.journey.on_ice,"Tan island gives dry footing inside the frozen district")
	world.player.position=world.cell_position([10,55])
	world.journey.step(1.0/60,Vector2.ZERO,false,false)
	check(world.journey.on_ice,"Open district ground uses sliding ice")
	var city:=Data.load_json("res://levels/city_journey_01_blocks_park.json")
	await load_world(city)
	var riders:Array=world.skaters.filter(func(r):return not r.stunt_spec.is_empty())
	check(riders.size()==2,"Both sides of overpass have rail-hopping skaters")
	var first:Node3D=riders[0]
	var launch:Vector3=first.points[1]
	var biggest:=0.0
	for i in range(1800):
		var before:Vector3=first.position
		first.step(1.0/120)
		biggest=maxf(biggest,before.distance_to(first.position))
		if first.stunt_lap>0:break
	check(first.stunt_lap==1 and first.points[1].distance_to(launch)>0.05,"Take-off point changes at the next seeded lap")
	check(biggest<0.4,"Lap seam and rail jumps remain continuous")
	check(first.points.any(func(p):return p.y>3.0) and first.points.any(func(p):return absf(p.y-2.0)<0.01),"Stunt route includes airborne jumps and skating on deck")
	var finals:Array=[]
	for hz in [30,60,120]:
		await load_world(city)
		var r:Node3D=world.skaters.filter(func(c):return not c.stunt_spec.is_empty())[0]
		for i in range(hz*12):r.step(1.0/hz)
		finals.append(r.position)
	check(finals[0].distance_to(finals[2])<0.05,"Seeded rail-hop motion agrees at30/60/120Hz")
	world.free()
	print("ICE/SKATE FEATURES: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
