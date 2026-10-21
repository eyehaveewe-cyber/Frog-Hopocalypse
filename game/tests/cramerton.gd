extends SceneTree
## Real physics replay: no teleport, state rewind, invincibility or hazard edits.
const Data = preload("res://scripts/level_data.gd")
const Suite = preload("res://tests/integration.gd")
var suite = Suite.new()
var app: Control

func _initialize() -> void:
	app = preload("res://main.tscn").instantiate()
	app.rule_notices_enabled = false
	root.add_child(app)
	call_deferred("run")

func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame
		app.world._physics_process(1.0 / 60.0)

func replay(actions: Array, label: String) -> bool:
	for index in range(actions.size()):
		var action: Dictionary = actions[index]
		if action.wait > 0:
			await ticks(ceili(float(action.wait) * 60))
		if app.world.result != "" or not app.world.tile_rules.request(Vector2i(action.direction[0], action.direction[1]), action.big):
			print("CRAMERTON FAILURE " + JSON.stringify({"pass":label,"action":index,"position":str(app.world.position_cell(app.world.player.position)),"result":app.world.result,"block":app.world.tile_rules.last_block,"elapsed":app.world.elapsed}))
			return false
		await ticks(26)
		if app.world.result not in ["", "LEVEL COMPLETE!"]:
			print("CRAMERTON FAILURE " + JSON.stringify({"pass":label,"action":index,"position":str(app.world.position_cell(app.world.player.position)),"result":app.world.result,"elapsed":app.world.elapsed}))
			return false
	return app.world.result == "LEVEL COMPLETE!"

func run() -> void:
	await process_frame
	app.set_process(false)
	app.world.set_physics_process(false)
	app.exit_preview = false
	app.set_sound_enabled(false)
	var map := Data.load_json("res://levels/bonus/Cramerton.json")
	suite.check(not map.is_empty() and Data.validate(map) == "", "Cramerton loads under the current schema")
	suite.check(map.name == "Cramerton" and map.game_mode == "tile" and map.rules.long_hop == "fragments", "Original tile and fragment rules retained")
	suite.check(map.spawn == [1,47] and map.exit == [31,1] and map.width == 33 and map.height == 49, "Original dimensions, start and exit retained")
	suite.check(map.checkpoints == [[8,16]] and not map.has("editor_autosave_id"), "One late checkpoint and no reuse of the author's local autosave identity")
	suite.check(Data.reachable(map), "Structural route reaches the original exit")
	suite.check(app.BONUS_LEVELS == ["res://levels/bonus/Shelby.json", app.MOVE_DEMO, "res://levels/bonus/Cramerton.json"], "Bonus append preserves the two existing completion indices")
	var library_before: Array = app.library.duplicate(true)
	app.completed_stages = []
	app.completed_human_stages = []
	app.completed_bonus_stages = [0,1]
	app.play_builtin(2, "bonus")
	app.world.set_physics_process(false)
	await physics_frame
	suite.check(app.level.name == "Cramerton" and app.mode == "play" and app.world.tile_rules != null, "Bonus Cramerton plays immediately without campaign unlocks")
	suite.check(app.library == library_before, "Loading the bonus map does not change local editor saves")
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/routes/cramerton.json"))
	var okay: bool = await replay(fixture.actions, "fresh")
	suite.check(okay, "Full resource-aware route completes through active original and added hazards")
	if not okay:
		quit(1)
		return
	suite.check(app.world.tile_rules.long_hops_used == 7 and app.world.tile_rules.pickups_collected == 21, "Route earns and uses seven hops from 21 fragment landings")
	suite.check(app.world.claimed_checkpoints == [[8,16]], "Full route claims exactly the one late checkpoint")
	suite.check(app.completed_bonus_stages == [0,1,2], "Completing Cramerton retains earlier Bonus progress")
	var retry_actions: Array = []
	var cell := Vector2i(map.spawn[0], map.spawn[1])
	var reached := false
	for action in fixture.actions:
		if reached:
			retry_actions.append(action)
		cell += Vector2i(action.direction[0], action.direction[1]) * (2 if action.big else 1)
		if cell == Vector2i(8,16):
			reached = true
	app.retry()
	app.world.set_physics_process(false)
	await physics_frame
	suite.check(app.world.position_cell(app.world.player.position) == Vector2i(8,16) and app.world.tile_rules.fragments == 1, "Retry restores checkpoint position and its one-fragment snapshot")
	var retry_fixture: String = "res://tests/routes/cramerton_retry.json"
	if FileAccess.file_exists(retry_fixture):
		retry_actions = JSON.parse_string(FileAccess.get_file_as_string(retry_fixture)).actions
	var retry_okay: bool = await replay(retry_actions, "checkpoint")
	suite.check(retry_okay, "Checkpoint retry completes with fresh hazard timing and restored pickups")
	print("CRAMERTON: %d checks, %d failures" % [suite.checks, suite.failures.size()])
	quit(0 if suite.failures.is_empty() else 1)
