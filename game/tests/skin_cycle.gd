extends SceneTree
const Suite = preload("res://tests/integration.gd")
var suite = Suite.new()
var app: Control
func _initialize() -> void:
 app=preload("res://main.tscn").instantiate()
 root.add_child(app)
 call_deferred("run")
func run() -> void:
 await process_frame
 app.set_process(false)
 app.world.set_physics_process(false)
 app.set_sound_enabled(false)
 app.completed_stages=[0,1,2,3]
 app.completed_human_stages=[0,2]
 app.unlocked_hats=["none","pharaoh","baby"]
 app.hat="baby"
 app.skin="green"
 app.show_menu()
 await process_frame
 await process_frame
 var control: Button=app.skin_button
 control.grab_focus()
 await process_frame
 await process_frame
 var scroll: ScrollContainer=app.overlay_layout.get_parent()
 var before_scroll: int=scroll.scroll_vertical
 var stable := true
 var correct := true
 for i in range(32):
  control.pressed.emit()
  await process_frame
  correct = correct and app.skin == ("purple" if i%2==0 else "green") and control.text == "Skin: " + app.skin.capitalize()
  stable = stable and is_instance_valid(control) and app.skin_button==control and control.has_focus() and scroll.scroll_vertical==before_scroll and app.splash_menu and app.overlay.visible
 suite.check(correct,"Repeated activation cycles both colors and updates the visible label")
 suite.check(stable,"Cycling keeps the active menu control, keyboard focus and scroll position alive")
 control.pressed.emit()
 app.load_profile()
 suite.check(app.skin=="purple","Chosen skin survives profile reload")
 suite.check(app.completed_stages==[0,1,2,3] and app.completed_human_stages==[0,2] and app.hat=="baby","Skin selection preserves campaign progress and equipped hat")
 app.show_hop_comparison()
 suite.check(app.skin_button==null,"Leaving the main menu clears its control reference")
 app.show_menu()
 await process_frame
 suite.check(is_instance_valid(app.skin_button) and app.skin_button!=control,"Returning builds a valid fresh skin control")
 app.skin_button.pressed.emit()
 suite.check(app.skin=="green" and app.skin_button.text=="Skin: Green","New menu control still cycles normally")
 app.completed_stages=[0,1,2]
 app.show_menu()
 suite.check(app.skin_button==null,"Locked profiles have no skin selector")
 app.toggle_skin()
 suite.check(app.skin=="green","Locked profiles cannot cycle the skin")
 app.hop_audio.clear();app.voice.clear()
 print("MENU SKIN CYCLE: %d checks, %d failures"%[suite.checks,suite.failures.size()])
 OS.delay_msec(150)
 app.queue_free();await process_frame
 quit(0 if suite.failures.is_empty() else 1)
