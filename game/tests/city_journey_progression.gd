extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	else: print("PASS: " + message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.rule_notices_enabled = false
	app.city_progress = {"nyc":[0,2],"streetlife":[1],"city_journey":[]}
	app.completed_stages = [0,1,2,3]
	app.completed_human_stages = [0,1,2,3]
	app.save_profile()
	check(not app.load_builtin(1,"city_journey"),"Fresh journey progress cannot select Skate Escape")
	var city_loaded: bool = app.load_builtin(0,"city_journey")
	check(city_loaded,"Blocks & Park available without clearing other city sets")
	if not city_loaded: quit(1); return
	app.start_play(false)
	await physics_frame
	app.set_process(false)
	check(app.world.journey != null and app.world.journey.stats().movement == "walk","City starts walking with new traversal runtime")
	# Exercise the real win signal and save path; full movement route is a separate acceptance test.
	app.world.finish("LEVEL COMPLETE!")
	check(0 in app.city_progress.city_journey,"City win signal awards unlock")
	app.city_progress = {"nyc":[],"streetlife":[],"city_journey":[]}
	app.load_profile()
	check(app.city_progress.city_journey == [0],"City unlock survives profile save/reload")
	check(app.city_progress.nyc == [0,2] and app.city_progress.streetlife == [1] and app.completed_stages == [0,1,2,3],"Older city and Baby Mode clears survive new unlock")
	var skate_loaded: bool = app.load_builtin(1,"city_journey")
	check(skate_loaded,"Persisted city clear unlocks Skate Escape")
	if not skate_loaded: quit(1); return
	app.start_play(false)
	await physics_frame
	check(app.world.journey.stats().movement == "skate","Skate Escape creates actual board movement")
	check(app.long_hop_button.visible and app.long_hop_button.text == "Jump · Space","Skate controls expose jump instead of tile long-hop")
	app.world.claim_checkpoint(app.level.checkpoints[0])
	var point: Array = app.checkpoint_spawn.duplicate()
	app.world.finish("SKATED OVER!")
	app.retry()
	await physics_frame
	check(app.world.position_cell(app.world.player.position) == Vector2i(point[0],point[1]) and app.world.result.is_empty(),"Retry restores skateboard checkpoint without stale failure state")
	app.load_builtin(0,"baby")
	check(app.world.journey == null,"Returning to Baby Mode leaves ordinary walking unchanged")
	app.queue_free()
	await process_frame
	print("CITY PROGRESSION: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
