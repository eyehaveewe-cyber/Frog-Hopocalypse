extends SceneTree
const Data = preload("res://scripts/level_data.gd")
const Suite = preload("res://tests/integration.gd")
const HASHES = ["c74d8873c56ff1261caad0488cf4942dc0c020934644289e6c4e498ae3011f4b", "aa9e23efdbd7f203f32c126dcc23ce808005ef35dbf818c8f4458920e6bda65c", "fe18f546be0f45c3e577b3bc5e6271313b9010acfd55aeb4b3ce4fde466d0c5a", "ddc6429215b6da16ae3d84459c07e5ad3050359ad5a2aea8137d7ee089db1b8d"]
var app: Control
var suite = Suite.new()
func _initialize() -> void:
	app = preload("res://main.tscn").instantiate()
	root.add_child(app)
	call_deferred("run")
func visible_buttons() -> Array:
	return app.find_children("*", "Button", true, false).filter(func(b: Button): return b.is_visible_in_tree() and app.overlay.is_ancestor_of(b)).map(func(b: Button): return b.text)
func run() -> void:
	await process_frame
	app.set_process(false)
	for i in range(4):
		var d := Data.load_json(app.HUMAN_LEVELS[i])
		suite.check(FileAccess.get_sha256(app.HUMAN_LEVELS[i]) == HASHES[i] and not d.is_empty() and Data.reachable(d), "Bundled layout hash, valid schema and connected route: " + d.get("name", "missing"))
	app.completed_stages = []
	app.completed_human_stages = []
	app.unlocked_hats = ["none", "pharaoh"]
	app.hat = "pharaoh"
	app.exit_preview = true
	app.save_profile()
	var before: Dictionary = app.level.duplicate(true)
	app.show_menu()
	suite.check(not app.human_set_unlocked() and "Play · Hardbutt" not in visible_buttons(), "Fresh profile keeps the human-made set locked in the menu")
	suite.check(not app.load_builtin(0, "human") and app.level == before, "Locked load is rejected without replacing the current level")
	app.new_level()
	app.level.name = "My saved maze"
	app.save_level()
	var library_hash := FileAccess.get_sha256("user://library.json")
	app.start_play(true)
	app.world.finish("LEVEL COMPLETE!")
	suite.check(app.completed_stages.is_empty() and app.completed_human_stages.is_empty(), "Editor playtests do not unlock either campaign")
	for i in range(3):
		app.load_builtin(i)
		app.start_play(false)
		app.world.finish("LEVEL COMPLETE!")
	app.retry()
	app.world.finish("LEVEL COMPLETE!")
	suite.check(app.completed_stages.size() == 3 and not app.human_set_unlocked(), "Three distinct clears plus a repeated clear leave the set locked")
	app.load_builtin(3)
	app.start_play(false)
	app.world.finish("LEVEL COMPLETE!")
	suite.check(app.human_set_unlocked() and app.hat == "baby", "Fourth Baby Mode clear unlocks the new set and preserves the baby frog hat reward")
	app.world._physics_process(2.21)
	app.update_result_presentation()
	suite.check("Start · " + app.HUMAN_TITLE in visible_buttons(), "Baby completion screen offers the newly unlocked set after the victory hold")
	var legacy := ConfigFile.new()
	legacy.load("user://profile.cfg")
	legacy.erase_section("not_as_hard")
	legacy.save("user://profile.cfg")
	app.load_profile()
	suite.check(app.human_set_unlocked() and app.completed_human_stages.is_empty() and app.exit_preview and app.hat == "baby", "Version-7-style progress, preview setting and earned hat load without reset")
	app.show_menu()
	var human_buttons := visible_buttons().filter(func(t: String): return t in ["Play · Hardbutt", "Play · Gloopbutt", "Play · Treebutt", "Play · Frogbutt"])
	suite.check(human_buttons == ["Play · Hardbutt", "Play · Gloopbutt", "Play · Treebutt", "Play · Frogbutt"], "Unlocked menu preserves attachment order")
	app.exit_preview = false
	for i in range(4):
		app.load_builtin(i, "human")
		app.start_play(false)
		for _j in range(6):
			await physics_frame
		var d: Dictionary = app.level.duplicate(true)
		var expected: int = d.objects.filter(func(o: Dictionary): return o.type == "critter").size()
		suite.check(app.world.critters.size() == expected and app.world.elapsed > 0 and app.compatibility_mode, "Exact critter count and active compatibility simulation: " + d.name)
		# Collision clearance only: freeze hazards, then move the real collider.
		app.world.load_level(d, true, app.hat)
		await physics_frame
		var route: Array = suite.physical_route(d)
		var traversed := not route.is_empty()
		for cell in route:
			var target: Vector3 = app.world.cell_position([cell.x, cell.y])
			var steps := 0
			while app.world.player.position.distance_to(target) > 0.08 and steps < 100:
				var offset: Vector3 = target - app.world.player.position
				app.world.player.step(1.0 / 60, Vector2(offset.x, offset.z).normalized())
				steps += 1
				await physics_frame
			if steps == 100:
				traversed = false
				break
		suite.check(traversed and app.world.player.position.distance_to(app.world.cell_position(d.exit)) < 0.15, "Physical full route with hazards paused: " + d.name)
	app.load_builtin(0, "human")
	app.start_play(false)
	app.world.finish("LEVEL COMPLETE!")
	app.retry()
	app.world.finish("LEVEL COMPLETE!")
	suite.check(app.completed_human_stages == [0] and app.completed_stages == [0, 1, 2, 3], "Human progress is distinct and repeated clears count once")
	app.world._physics_process(2.21)
	app.update_result_presentation()
	var next: Button = app.overlay.find_children("*", "Button", true, false).filter(func(b: Button): return b.text == "Next level →")[0]
	next.pressed.emit()
	suite.check(app.campaign_set == "human" and app.builtin_index == 1 and app.level.name == "Gloopbutt", "Next level stays within the human-made campaign")
	for i in [1, 2, 3]:
		app.load_builtin(i, "human")
		app.start_play(false)
		app.world.finish("LEVEL COMPLETE!")
	app.world._physics_process(2.21)
	app.update_result_presentation()
	suite.check(app.completed_human_stages == [0, 1, 2, 3] and "Next level →" not in visible_buttons(), "Four human-stage clears produce their own completion screen and stop at the finale")
	app.hat = "none"
	app.exit_preview = true
	app.save_profile()
	app.completed_stages = []
	app.completed_human_stages = []
	app.hat = "pharaoh"
	app.exit_preview = false
	app.load_profile()
	app.library.clear()
	app.load_library()
	suite.check(app.completed_human_stages.size() == 4 and app.completed_stages.size() == 4 and app.hat == "none" and app.exit_preview, "Both campaigns, selected hat and preview preference survive reload")
	suite.check(FileAccess.get_sha256("user://library.json") == library_hash and app.library.size() == 1, "Existing custom-level library remains byte-identical")
	print("HUMAN SET: %d checks, %d failures" % [suite.checks, suite.failures.size()])
	quit(0 if suite.failures.is_empty() else 1)
