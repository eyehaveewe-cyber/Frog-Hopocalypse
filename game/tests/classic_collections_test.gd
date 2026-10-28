extends SceneTree
var app
var checks:=0
var failures:Array[String]=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func controls()->Array:
	return app.overlay_box.find_children("*","Button",true,false)
func buttons(prefix:String)->Array:
	return controls().filter(func(b):return b.text.begins_with(prefix))
func labels()->String:
	var value:=""
	for item in app.overlay_box.find_children("*","Label",true,false):value+=item.text+"\n"
	return value
func _initialize()->void:call_deferred("run")
func run()->void:
	app=load("res://main.tscn").instantiate();root.add_child(app);current_scene=app
	await process_frame
	check(app.linked_collection=="" and app.splash_menu,"Direct Classic entry keeps original frog menu")
	app.linked_collection="baby";app.show_menu()
	check(buttons("Play · ").size()==app.BUILTINS.size(),"Baby collection lists every original stage")
	check(buttons("Back to level").size()==1 and buttons("Frog outfits").size()==1,"Collection offers return and original home")
	var prior:Dictionary=app.level.duplicate(true);app.linked_collection="human";app.show_menu()
	check(buttons("Play · ").is_empty() and labels().contains("Complete Baby Mode"),"Locked human collection explains the Baby Mode requirement")
	app.play_builtin(0,"human");check(app.level==prior,"Direct human play cannot bypass unlock")
	for set_key in ["tile","sync"]:
		app.linked_collection=set_key;app.show_menu()
		check(buttons("Play · ").is_empty() and labels().contains("Complete "+app.HUMAN_TITLE),set_key+" explains its unlock")
		app.play_builtin(0,set_key);check(app.level==prior,set_key+" play cannot bypass unlock")
	app.completed_stages=[0,1,2,3];app.linked_collection="human";app.show_menu()
	check(buttons("Play · ").size()==app.HUMAN_LEVELS.size(),"Earned Baby clears expose every human stage")
	app.completed_human_stages=[0,1,2,3]
	for set_key in ["bonus","tile","sync"]:
		app.linked_collection=set_key;app.show_menu()
		check(buttons("Play · ").size()==app.paths_for_set(set_key).size(),set_key+" lists all its stages when allowed")
	app.linked_collection="baby";app.show_menu();var first:Button=buttons("Play · ")[0];first.pressed.emit()
	check(app.campaign_set=="baby" and app.builtin_index==0,"Stage button invokes existing campaign loader")
	app.show_menu();check(app.linked_collection=="baby" and buttons("Play · ").size()==app.BUILTINS.size(),"Returning from play retains the selected collection")
	buttons("Frog outfits")[0].pressed.emit()
	check(app.linked_collection=="" and app.splash_menu,"Classic home returns to original menu, editor and outfits")
	print(JSON.stringify({"checks":checks,"failures":failures,"scope":"Actual set menus, stage dispatch and progression gates; web parent messaging verified separately"}));quit(0 if failures.is_empty() else 1)
