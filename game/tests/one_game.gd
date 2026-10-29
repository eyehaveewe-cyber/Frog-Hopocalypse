extends SceneTree
const Roach = preload("res://scripts/roach.gd")
var checks := 0
var failures := 0
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(text)
	else: print("PASS: "+text)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.rule_notices_enabled = false
	check(app.SET_TITLES.keys()[0] == "baby", "Baby Mode is the first set")
	check(app.overlay_box.find_children("*","Button",true,false)[0].text == "Play Baby Mode", "First frog-screen action starts Baby Mode")
	app.completed_stages = [0,1,2,3]
	app.completed_human_stages = [0,1,2,3]
	app.city_progress.city_journey = [0] # Returning-player fixture unlocks Skate Escape.
	var count := 0
	for key in app.SET_TITLES:
		for i in range(app.paths_for_set(key).size()):
			check(app.load_builtin(i,key),"Loads "+key+" level "+str(i+1)+" in the shared world")
			check(app.Data.reachable(app.level),"Structural route: "+str(app.level.name))
			count += 1
			await process_frame
	check(count == 36,"All 36 campaign levels are present")
	app.play_builtin(0,"nyc")
	check(app.world.traffic.vehicles.size() > 0,"NYC moving traffic is instantiated")
	var clock: float = app.world.traffic.clock
	await physics_frame
	await physics_frame
	check(app.world.traffic.clock > clock,"NYC traffic advances in the shared physics loop")
	app.play_builtin(0,"streetlife")
	check(app.world.critters.any(func(c): return c is Roach),"Streetlife has its actual animated roaches")
	app.play_builtin(5,"streetlife")
	check(not app.world.skaters.is_empty(),"Streetlife retains its skaters")
	app.world.finish("LEVEL COMPLETE!")
	check(5 in app.city_progress.streetlife,"City clears use common campaign progression")
	app.save_profile()
	app.city_progress = {"nyc":[],"streetlife":[],"city_journey":[]}
	app.load_profile()
	check(5 in app.city_progress.streetlife and app.completed_stages.size()==4,"City and Baby progression survive one profile reload")
	var base: Dictionary = app.Data.blank("Earlier save")
	var city: Dictionary = app.Data.blank("NYC save","nyc")
	var a := [{"id":"same","level":base}]
	var b := [{"id":"same","level":city}]
	var merged: Array = app.LibraryMerge.merge(a,b)
	check(merged.size()==2 and merged[0].level==base and merged[1].level==city,"Conflicting former editor IDs keep both levels")
	check(app.LibraryMerge.merge(merged,b)==merged,"Save import is repeatable without duplicates")
	app.library = merged
	check(app.commit_library_candidate(merged),"Combined library writes with existing durable save mechanism")
	app.library = []
	app.load_library()
	check(app.library.size()==2,"Both former editors' levels reload into the same library")
	app.editor_session_active = false
	app.level = city
	app.enter_editor()
	app.set_tool("roach")
	app.edit_cell(Vector2i(4,4))
	app.set_tool("skater")
	app.edit_cell(Vector2i(9,7))
	check(app.Data.validate(app.level).is_empty() and app.world.skaters.size()==1,"Shared editor creates valid NYC actors")
	print("ONE GAME: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
