extends SceneTree
## Continuous ordinary-input route acceptance. Forecasts read hazard state but
## never move/freeze hazards, teleport the player or change collision.
const Data = preload("res://scripts/level_data.gd")
const Traffic = preload("res://scripts/traffic.gd")
const STEP := 1.0/60.0
var checks := 0
var failures := 0
var max_height := 0.0
var ice_frames := 0
var waited_frames := 0
var traveled := 0.0
var world: Node3D
var app: Control
func check(ok: bool, text: String) -> void:
	checks += 1
	if ok: print("PASS: "+text)
	else:
		failures += 1
		push_error(text)
func _initialize() -> void:
	call_deferred("run")
func tick() -> void:
	var before: Vector3=world.player.position
	await physics_frame
	traveled += before.distance_to(world.player.position)
	max_height=maxf(max_height,world.player.position.y)
	if world.journey.on_ice: ice_frames+=1
func horizontal(a: Vector3,b: Vector3) -> float:
	return Vector2(a.x-b.x,a.z-b.z).length()
func forecast_clear(target: Vector3,speed: float) -> bool:
	var from: Vector3=world.player.position
	var duration:=horizontal(from,target)/speed
	var park: Array=[]
	if is_instance_valid(world.park_hazards):
		for encounter in world.park_hazards.encounters: park.append(encounter.duplicate(false))
	for frame in range(ceili(duration/0.04)+1):
		var t:=minf(duration,frame*0.04)
		var p:=from.lerp(target,t/maxf(duration,0.001))
		# Follow the authored deck height while forecasting a bridge traverse.
		for bridge in world.level.get("city_journey",{}).get("bridges",[]):
			var grid: Vector2=world.journey.grid_point(p)
			if world.journey.rect_has(bridge.rect,grid): p.y=world.journey.bridge_height(bridge,grid)
		for e in park:
			var dt:=0.04 if frame>0 else 0.0
			world.park_hazards.advance_state(e,dt,p)
			for danger in world.park_hazards.danger_points(e):
				var radius: float=1.17 if e.kind=="pigeons" else .90
				if p.y<.95 and horizontal(p,danger)<radius: return false
		for v in world.traffic.vehicles:
			var lane: Dictionary=world.traffic.lanes[v.lane]
			if p.y>1.85: continue
			var cx: float=float(v.left)+fposmod(v.node.position.x-float(v.left)+Traffic.lane_travel(lane,world.traffic.clock,t),float(v.span))
			var halfx:=float(v.length)*.5+.42
			if absf(p.z-v.node.position.z)<.98 and absf(p.x-cx)<halfx: return false
		for rider in world.skaters:
			var s: Dictionary=rider.sample_future(t)
			if absf(p.y-s.position.y)<.8 and horizontal(p,s.position)<1.00: return false
	return true
func wait_clear(target: Vector3,speed: float) -> bool:
	world.input_vector=Vector2.ZERO
	world.brake_input=true
	for _i in range(1200):
		if forecast_clear(target,speed):
			world.brake_input=false
			return true
		waited_frames+=1
		await tick()
		if not world.result.is_empty(): return false
	world.brake_input=false
	return false
func drive(target_cell: Array, stop: bool = true, forecast: bool = true) -> bool:
	var target: Vector3=world.cell_position(target_cell)
	var skating: bool=world.journey.is_skating()
	var speed:=7.5 if skating else 4.2
	if forecast and world.journey.grind_index<0 and not await wait_clear(target,speed):
		print("WAIT BLOCKED at ",world.journey.grid_point(world.player.position)," target=",target_cell," y=",world.player.position.y," stats=",world.journey.stats()," result=",world.result)
		return false
	var distance:=horizontal(world.player.position,target)
	var budget:=ceili(distance/speed/STEP)+300
	for _i in range(budget):
		if world.result=="LEVEL COMPLETE!": return true
		if not world.result.is_empty():
			print("HIT at ",world.journey.grid_point(world.player.position)," target=",target_cell," y=",world.player.position.y," stats=",world.journey.stats()," result=",world.result)
			return false
		var offset:=Vector2(target.x-world.player.position.x,target.z-world.player.position.z)
		if offset.length()<(.17 if stop else .4):
			world.input_vector=Vector2.ZERO if stop else offset.normalized()
			world.brake_input=stop
			if stop:
				while world.journey.momentum.length()>.08 and world.result.is_empty(): await tick()
			world.brake_input=false
			return world.result.is_empty() or world.result=="LEVEL COMPLETE!"
		var amount:=1.0
		if stop and skating and not world.journey.airborne and world.journey.grind_index<0:
			amount=clampf(offset.length()/2.0,.10,1.0)
		world.input_vector=offset.normalized()*amount
		world.brake_input=false
		await tick()
	print("MOTION BLOCKED at ",world.journey.grid_point(world.player.position)," y=",world.player.position.y," target=",target_cell," stats=",world.journey.stats())
	return false
func run() -> void:
	app=load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.rule_notices_enabled=false
	app.set_process(false)
	var only:=0
	var phases: Array=[0.0]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="): only=int(arg.trim_prefix("--level="))
		if arg=="--both-phases": phases=[0.0,.75]
	for index in ([0,2,1] if only==0 else [only-1]):
		for phase in phases: await run_route(index,phase)
	print("CITY JOURNEY ROUTES: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
func run_route(index: int,phase: float) -> void:
	var map:=Data.load_json(app.JOURNEY_LEVELS[index])
	check(not map.is_empty(),"Route level validates: "+str(index))
	if map.is_empty():
		print("VALIDATION: ",Data.validate(JSON.parse_string(FileAccess.get_file_as_string(app.JOURNEY_LEVELS[index]))))
		return
	app.level=map
	app.mode="test"
	app.checkpoint_history=[]
	app.checkpoint_spawn=[]
	app.pending_result=""
	app.world.load_level(map,false)
	app.overlay.hide()
	world=app.world
	max_height=0;ice_frames=0;waited_frames=0;traveled=0
	await tick();await tick()
	for _i in range(roundi(phase/STEP)): await tick()
	var route: Array=map.journey_route.duplicate(true)
	if index==0:
		route=[[6,55],[6,52],[8,47],[12,46],[12,42],[19,42],[19,44],[20,44],[20,31],[19,30],[12,29],[12,23],[11,23],[11,17],[13,17],[13,12],[19.8,12],[24,12],[29,12],[33,12],[38,12],[38,18],[38,20],[41,20],[41,24],[44,24],[44,35],[41,36],[41,42],[41,48],[41,55]]
	if index==1:
		route=[[10,56],[10,43],[10,41],[10,36],[23,35],[34,36],[34,32],[34,24],[34,20],[39,21],[40,18],[46,18],[53,18],[53,8],[53,5]]
		world.grind_input=true
	if index==2:
		route=[[7,56],[45,56],[45,44],[45,37],[4,37],[4,33],[4.5,33],[4.5,29],[3,29],[3,24],[46,24],[46.5,24],[46.5,8],[46.5,3],[41,3],[41,5]]
	var success:=true
	for i in range(1,route.size()):
		print("LEG ",i," ",route[i]," time=",world.elapsed)
		var stop: bool=not(index==1 and route[i] in [[34,32],[34,24]])
		if not await drive(route[i],stop):
			success=false
			break
	world.input_vector=Vector2.ZERO
	check(success and world.result=="LEVEL COMPLETE!","Full continuous live-hazard route reaches exit: "+map.name+" phase="+str(phase))
	if index==0:
		check(app.checkpoint_history.size()==5,"City continuous route claimed all five retry checkpoints")
		check(max_height>=1.99 and ice_frames>60,"City route traversed raised bridge and sliding rink")
	elif index==2:
		check(ice_frames>600,"Frozen district traversed sliding ice with active roaches and skaters")
	else:
		check(world.journey.ramps_used>=3 and world.journey.rails_used>=1,"Skate route launched three walls and rode a rail")
	print("ROUTE EVIDENCE: level=%d phase=%.2f simulated=%.2fs waited=%.2fs traveled=%.2fm height=%.2fm ice_frames=%d ramps=%d rails=%d result=%s" % [index+1,phase,world.elapsed,waited_frames*STEP,traveled,max_height,ice_frames,world.journey.ramps_used,world.journey.rails_used,world.result])
