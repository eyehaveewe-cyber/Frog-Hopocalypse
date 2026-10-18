extends RefCounted
const Data = preload("res://scripts/level_data.gd")

func run(app: Control, suite: RefCounted) -> void:
	app.size_picker.select(1)
	app.new_level("swamp")
	var large: Dictionary = app.level.duplicate(true)
	suite.check(large.width == 21 and large.height == 16 and Data.validate(large).is_empty() and Data.reachable(large), "Large editor maze has 52% more area and a playable route")
	app.set_tool("wall")
	app.stroke_changed = false
	app.edit_cell(Vector2i(19, 14))
	app.undo()
	suite.check(app.level.tiles[14][19] == "floor", "Large maze far-edge painting supports undo")
	app.redo()
	suite.check(app.level.tiles[14][19] == "wall", "Large maze far-edge painting supports redo")
	app.undo()
	var serialized := JSON.stringify(app.level)
	app.size_picker.select(0)
	app.new_level()
	suite.check(app.level.width == 17 and app.level.height == 13, "Standard editor size remains available")
	suite.check(app.import_text(serialized) and app.level.width == 21 and app.level.height == 16, "Large maze survives export/import through the shared serializer")
	app.set_exit_preview(true)
	app.exit_preview = false
	app.load_profile()
	suite.check(app.exit_preview, "Exit Preview preference survives profile reload")
	app.world.set_physics_process(false)
	app.start_play(true)
	var origin: Vector3 = app.world.player.position
	app.world.input_vector = Vector2.UP
	for _i in range(126):
		app.world._physics_process(1.0 / 60)
	var goal: Vector3 = app.world.cell_position(app.level.exit) + Vector3(0, 0.25, 0)
	suite.check(app.world.intro_active and app.world.elapsed == 0 and app.world.player.position == origin and app.world.camera_target.distance_to(goal) < 0.01, "Exit Preview reaches the exit while holding frog and game clock")
	var clock: float = app.world.intro_time
	app.world.halted = true
	app.world._physics_process(0.5)
	suite.check(app.world.intro_time == clock, "Pausing freezes the exit sweep")
	app.world.halted = false
	for _i in range(127):
		app.world._physics_process(1.0 / 60)
	suite.check(not app.world.intro_active and app.world.camera_target.distance_to(origin + Vector3(0, 0.25, -2.5)) < 0.01, "Exit sweep returns to the frog before releasing play")
	app.world.begin_exit_preview()
	app.world.set_map_view(true)
	suite.check(not app.world.intro_active and app.world.map_view, "Opening the overhead map safely skips the preview")
	app.world.set_map_view(false)
	app.world.begin_exit_preview()
	app.set_exit_preview(false)
	suite.check(not app.world.intro_active, "Turning Exit Preview off cancels an active sweep")
	for fps in [30, 120]:
		app.start_play(true)
		app.world.begin_exit_preview()
		for _i in range(ceili(app.world.INTRO_DURATION * fps)):
			app.world._physics_process(1.0 / fps)
		# Float accumulation can finish one tick after the exact boundary.
		app.world._physics_process(1.0 / fps)
		suite.check(not app.world.intro_active and app.world.player.position == app.world.cell_position(app.level.spawn), "Preview timing and frozen player at %d Hz" % fps)
	for reason in ["SPLASHED!", "SQUISHED!", "LEVEL COMPLETE!"]:
		app.start_play(true)
		app.world.finish(reason)
		app.world._physics_process(0.6)
		app.update_result_presentation()
		var posing: bool = app.world.player.visual.position.y != 0 or app.world.player.visual.rotation.z != 0
		suite.check(not app.overlay.visible and posing and not app.world.active, "Result animation stays visible before the screen: " + reason)
		app.world._physics_process(1.0 if reason != "LEVEL COMPLETE!" else 1.61)
		app.update_result_presentation()
		suite.check(app.overlay.visible, "Result screen appears after the animation hold: " + reason)
	app.start_play(true)
	app.world.finish("HIT!")
	app.world._physics_process(0.3)
	app.retry()
	app.update_result_presentation()
	suite.check(not app.overlay.visible and app.pending_result.is_empty() and app.world.result.is_empty(), "Early retry cancels the pending result screen")
	app.world.set_physics_process(true)
	app.size_picker.select(0)
