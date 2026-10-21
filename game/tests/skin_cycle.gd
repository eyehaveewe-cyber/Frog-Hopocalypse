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
 await process_frame
 await process_frame
 var animation: Button=app.hop_animation_button
 var palette: Button=app.hop_palette_button
 var volume: HSlider=app.hop_volume_slider
 volume.value=45
 var child_count: int=app.overlay_box.get_child_count()
 var panel_height: float=app.overlay_panel.size.y
 var advanced_stable := true
 var advanced_values := true
 for active in [animation,palette]:
  active.grab_focus()
  await process_frame
  var advanced_scroll: int=scroll.scroll_vertical
  for i in range(40):
   active.pressed.emit()
   await process_frame
   advanced_stable = advanced_stable and is_instance_valid(active) and active.has_focus() and scroll.scroll_vertical==advanced_scroll and app.overlay_box.get_child_count()==child_count and app.overlay_panel.size.y<=panel_height+1 and app.hop_volume_slider==volume
  advanced_values = advanced_values and is_equal_approx(app.hop_audio.gain,0.45) and volume.value==45
 suite.check(advanced_stable,"Eighty animation/sound changes keep the populated panel, focus, scroll, height and slider alive")
 suite.check(advanced_values,"Animation and sound cycling retain the selected volume")
 animation.pressed.emit()
 suite.check(app.world.hop_pose_style=="stepped" and animation.text.contains("Stepped"),"Animation label follows the selected leg style")
 palette.pressed.emit()
 suite.check(app.hop_audio.palette=="retro" and palette.text.contains("Retro"),"Sound label follows the selected palette")
 app.hop_audio.unlocked=true
 app.set_sound_enabled(true)
 app.preview_hop_sound()
 var generation: int=app.hop_audio.generation
 palette.pressed.emit()
 suite.check(app.hop_audio.generation>generation,"Changing palette cancels the previous audition generation")
 app.set_sound_enabled(false)
 app.show_menu()
 await process_frame
 suite.check(is_instance_valid(app.skin_button) and app.skin_button!=control and app.hop_animation_button==null and app.hop_palette_button==null and app.hop_volume_slider==null,"Returning builds a fresh skin control and clears advanced references")
 app.skin_button.pressed.emit()
 suite.check(app.skin=="green" and app.skin_button.text=="Skin: Green","New menu control still cycles normally")
 app.completed_stages=[0,1,2]
 app.show_menu()
 suite.check(app.skin_button==null,"Locked profiles have no skin selector")
 app.toggle_skin()
 suite.check(app.skin=="green","Locked profiles cannot cycle the skin")
 app.completed_stages=[0,1,2,3]
 app.start_play(false)
 app.toggle_pause()
 app.show_hop_comparison()
 app.hop_palette_button.pressed.emit()
 app.hop_animation_button.pressed.emit()
 suite.check(app.paused and app.world.halted and app.overlay.visible and app.hop_volume_slider!=null,"Comparison controls also stay usable from Pause without unpausing the game")
 app.hop_audio.clear();app.voice.clear()
 print("MENU SKIN CYCLE: %d checks, %d failures"%[suite.checks,suite.failures.size()])
 OS.delay_msec(150)
 app.queue_free();await process_frame
 quit(0 if suite.failures.is_empty() else 1)
