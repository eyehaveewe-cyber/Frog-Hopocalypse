extends SceneTree
var failures:=0
func check(ok:bool,what:String)->void:
	if ok: print("PASS: "+what)
	else: failures+=1;push_error(what)
func _initialize()->void: call_deferred("run")
func run()->void:
	var app=load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.rule_notices_enabled=false
	app.city_progress.city_journey=[0]
	for i in [0,2,1]:
		check(app.load_builtin(i,"city_journey"),"Load City Journey stage "+str(i))
		app.start_play(false)
		await process_frame
		app.configure_view()
		await process_frame
		check(app.view.msaa_3d==Viewport.MSAA_2X and app.view_container.stretch_shrink==1 and app.view_container.texture_filter==CanvasItem.TEXTURE_FILTER_LINEAR and app.view_container.material==null,"Native resolution and 2x MSAA in City Journey stage "+str(i))
		app.world.set_map_view(true);app.configure_view()
		check(app.view.msaa_3d==Viewport.MSAA_2X and app.view_container.stretch_shrink==1,"Overhead City Journey map retains smoothing")
	app.world.set_map_view(false)
	app.compatibility_mode=true;app.configure_view()
	check(app.view.msaa_3d==Viewport.MSAA_2X and app.view_container.material==null,"Compatibility mode retains city smoothing")
	app.compatibility_mode=false
	var old_size:Vector2=app.view_container.size
	app.view_container.size=Vector2(3840,2160);app.configure_view()
	check(app.view_container.stretch_shrink==2,"Very large viewports use the bounded render size")
	app.view_container.size=old_size
	check(app.load_builtin(0,"baby"),"Load Baby Mode after city")
	app.start_play(false);await process_frame;app.configure_view()
	check(app.view.msaa_3d==Viewport.MSAA_DISABLED and app.view_container.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST and app.view_container.material!=null,"Earlier game retains nearest-neighbor retro view")
	app.queue_free();await process_frame
	print("CITY JOURNEY ANTI-ALIAS: %d failures"%failures)
	quit(1 if failures else 0)
