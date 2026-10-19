extends SceneTree
const Suite = preload("res://tests/integration.gd")
var suite = Suite.new()
var app: Control
func _initialize() -> void:
 app = preload("res://main.tscn").instantiate()
 root.add_child(app)
 call_deferred("run")
func run() -> void:
 await process_frame
 app.set_process(false)
 app.world.set_physics_process(false)
 app.set_sound_enabled(false)
 app.exit_preview=false
 app.show_menu()
 suite.check(app.splash_menu and app.splash_art.visible,"Main menu displays the illustrated splash")
 suite.check(app.splash_art.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Raster art cannot intercept menu input")
 var texts: Array=[]
 for child in app.overlay_box.get_children():
  if child is Label: texts.append(child.text)
 suite.check("Hopán" in texts and "P H A R A O H   F R O G" in texts,"Both title lines are editable real UI labels")
 var buttons=app.overlay_box.find_children("*","Button",true,false)
 suite.check(buttons.any(func(b):return b.text=="Baby Mode") and buttons.any(func(b):return b.text=="Level editor · Create a maze"),"Existing play and editor actions remain real buttons")
 suite.check(buttons.all(func(b):return b.focus_mode==Control.FOCUS_ALL),"Menu buttons retain keyboard focus support")
 app.reset_overlay("PAUSED")
 suite.check(not app.splash_menu and not app.splash_art.visible and app.overlay_shade.color.a>0.8,"Gameplay overlays restore the standard shaded presentation")
 app.mobile_ui=true
 app.get_window().content_scale_size=Vector2i(390,844)
 app.show_menu()
 suite.check(app.splash_art.texture==app.SPLASH_PORTRAIT,"Portrait uses a separately composed illustration")
 suite.check(app.overlay_panel.custom_minimum_size.x<=366,"Portrait panel fits phone width")
 app.get_window().content_scale_size=Vector2i(844,390)
 app.configure_splash_layout()
 suite.check(app.splash_art.texture==app.SPLASH_COMPACT,"Touch landscape uses art with the frog left of the menu")
 suite.check(app.overlay_layout.get_theme_constant("margin_top")==12,"Landscape removes portrait spacing on rotation")
 app.mobile_ui=false
 app.get_window().content_scale_size=Vector2i(1280,800)
 app.configure_splash_layout()
 suite.check(app.splash_art.texture==app.SPLASH_WIDE,"Desktop returns to the wide composition")
 app.enter_editor()
 suite.check(not app.overlay.visible,"Editor remains accessible from the splash")
 app.show_menu()
 var continuation=app.overlay_box.find_children("*","Button",true,false).filter(func(b):return b.text=="Continue editing")
 suite.check(continuation.size()==1,"Menu preserves continue-editing action")
 continuation[0].pressed.emit()
 suite.check(not app.overlay.visible and not app.world.halted,"Continue editing dismisses the splash")
 print("SPLASH UI: %d checks, %d failures" % [suite.checks,suite.failures.size()])
 quit(0 if suite.failures.is_empty() else 1)
