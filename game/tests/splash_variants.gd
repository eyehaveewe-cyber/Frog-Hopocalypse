extends SceneTree
const Main = preload("res://scripts/main.gd")
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
	suite.check(Main.splash_variant_for(0.0) == "layered" and Main.splash_variant_for(0.149999) == "layered", "Lower 15 percent selects #4")
	suite.check(Main.splash_variant_for(0.15) == "wrapped" and Main.splash_variant_for(0.999999) == "wrapped", "Remaining 85 percent selects #6 including exact boundary")
	suite.check(Main.splash_variant_for(0.99, "4") == "layered" and Main.splash_variant_for(0.0, "6") == "wrapped", "Explicit preview overrides either random outcome")
	suite.check(Main.splash_variant_for(0.9, "invalid") == "wrapped", "Invalid preview choice falls back to normal selection")
	var profile_before: Array = [app.completed_stages.duplicate(), app.completed_human_stages.duplicate(), app.hat, app.skin, app.sound_enabled]
	for style in ["wrapped", "layered"]:
		app.splash_variant = style
		for layout in ["wide", "compact", "portrait"]:
			app.mobile_ui = layout != "wide"
			root.content_scale_size = Vector2i(480, 800) if layout == "portrait" else Vector2i(1280, 800)
			app.configure_splash_layout()
			var expected: String = "res://art/splash/hopan-" + ("layered-" if style == "layered" else "") + layout + ".png"
			suite.check(app.splash_art.texture.resource_path == expected and app.splash_variant == style, style + " keeps its selected hat through " + layout + " layout")
		app.show_menu()
		suite.check(app.splash_variant == style, style + " does not reroll when returning to Menu")
		app.play_builtin(0, "baby")
		suite.check(not app.splash_art.is_visible_in_tree() and app.mode == "play", style + " title artwork leaves the playable route unobstructed")
		app.show_menu()
		suite.check(app.splash_variant == style and app.splash_art.visible, style + " remains selected after gameplay")
	suite.check(profile_before == [app.completed_stages, app.completed_human_stages, app.hat, app.skin, app.sound_enabled], "Cosmetic title choices retain profile progress, equipment and sound")
	print("SPLASH VARIANTS: %d checks, %d failures" % [suite.checks, suite.failures.size()])
	app.queue_free()
	await process_frame
	quit(0 if suite.failures.is_empty() else 1)
