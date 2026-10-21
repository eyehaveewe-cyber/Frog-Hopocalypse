extends SceneTree
## Acceptance replays use ordinary tile requests and real physics. No invincibility,
## teleport, rewind, collision edits or enemy manipulation.
const Data = preload("res://scripts/level_data.gd")
const Suite = preload("res://tests/integration.gd")
var suite = Suite.new()
var app: Control
var keys := ["one_step_ahead", "needle_clock", "shard_switchyard", "stillwater_circuit", "rush_hourglass"]
var route_failures := 0
func _initialize() -> void:
	app = preload("res://main.tscn").instantiate()
	app.rule_notices_enabled = false
	root.add_child(app)
	call_deferred("run")
func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame
		app.world._physics_process(1.0/60)
func frozen_state() -> Array:
	var snapshot: Array = [app.world.elapsed, app.world.tile_rules.beat_count]
	for mover in app.world.crossing.movers: snapshot.append(mover.node.position)
	for ball in app.world.spikes.balls: snapshot.append([ball.node.position,ball.hold,ball.slams])
	for emitter in app.world.emitters: snapshot.append(emitter.clock)
	for shot in app.world.projectiles: snapshot.append(shot.node.position)
	return snapshot
func replay(actions: Array, label: String) -> bool:
	for index in range(actions.size()):
		var a: Dictionary = actions[index]
		if a.wait > 0: await ticks(ceili(a.wait*60))
		if index == 10:
			var frozen := frozen_state()
			await ticks(90)
			suite.check(frozen_state()==frozen, "Active hazards also freeze mid-route: "+label)
		var start: Vector2i = app.world.position_cell(app.world.player.position)
		if not app.world.tile_rules.request(Vector2i(a.direction[0],a.direction[1]),a.big):
			print("MOVE FAILURE " + JSON.stringify({"level":label,"action":index,"start":str(start),"block":app.world.tile_rules.last_block,"result":app.world.result}))
			return false
		await ticks(26)
		if app.world.result not in ["", "LEVEL COMPLETE!"]:
			var cars: Array = []
			for m in app.world.crossing.movers: cars.append(str(app.world.position_cell(m.node.position)))
			print("MOVE FAILURE " + JSON.stringify({"level":label,"action":index,"start":str(start),"position":str(app.world.position_cell(app.world.player.position)),"beat":app.world.tile_rules.beat_count,"result":app.world.result,"movers":cars}))
			return false
	return app.world.result == "LEVEL COMPLETE!"
func run() -> void:
	await process_frame
	app.set_process(false)
	app.world.set_physics_process(false)
	app.exit_preview = false
	app.set_sound_enabled(false)
	app.completed_stages = []
	app.completed_human_stages = []
	app.completed_sync_stages = []
	app.unlocked_hats = ["none", "pharaoh"]
	app.hat = "pharaoh"
	suite.check(not app.load_builtin(0,"sync"), "New set respects the established NAHAIL Tile Hop unlock")
	app.completed_human_stages = [0,1,2,3]
	var library_before: Array = app.library.duplicate(true)
	for index in range(keys.size()):
		var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/routes/your_move_"+keys[index]+".json"))
		var map := Data.load_json(fixture.level)
		suite.check(not map.is_empty() and Data.validate(map)=="" and Data.reachable(map), "Valid, structurally connected map: "+keys[index])
		if map.is_empty(): quit(1); return
		suite.check(map.move_with_me and map.game_mode=="tile" and map.checkpoints.size()==1, "Movement-linked rule and one checkpoint: "+keys[index])
		app.play_builtin(index,"sync")
		app.world.set_physics_process(false)
		await physics_frame
		var before := frozen_state()
		await ticks(120)
		suite.check(frozen_state()==before, "Idle freezes the actual hazard simulation: "+keys[index])
		var okay: bool = await replay(fixture.actions,keys[index])
		suite.check(okay, "Fresh real-physics route completes: "+keys[index])
		if okay:
			suite.check(app.world.tile_rules.beat_count==app.world.tile_rules.hop_count, "One hazard beat per accepted hop: "+keys[index])
			suite.check(app.world.claimed_checkpoints.size()==1, "Route uses its late checkpoint: "+keys[index])
			print("MOVE COMPLETE "+JSON.stringify({"level":keys[index],"hops":app.world.tile_rules.hop_count,"long_hops":app.world.tile_rules.long_hops_used,"pickups":app.world.tile_rules.pickups_collected}))
			var checkpoint_cell: Array = map.checkpoints[0]
			app.retry()
			app.world.set_physics_process(false)
			await physics_frame
			suite.check(app.world.position_cell(app.world.player.position)==Vector2i(checkpoint_cell[0],checkpoint_cell[1]), "Retry starts at its actual checkpoint: "+keys[index])
			var retry_fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/routes/your_move_retry_"+keys[index]+".json"))
			var retry_okay: bool = await replay(retry_fixture.actions, keys[index]+" retry")
			suite.check(retry_okay, "Checkpoint route survives reset hazard phases: "+keys[index])
		else: route_failures += 1
		if index < 4: suite.check("hourglass" not in app.unlocked_hats, "Partial set cannot unlock the reward: "+keys[index])
	if route_failures==0:
		suite.check(app.completed_sync_stages==[0,1,2,3,4] and app.hat=="hourglass" and "hourglass" in app.unlocked_hats, "All five stages unlock and equip the hourglass pyramid hat")
		app.save_profile()
		app.load_profile()
		suite.check(app.completed_sync_stages==[0,1,2,3,4] and app.hat=="hourglass" and app.completed_human_stages==[0,1,2,3], "Set progress, equipped reward and previous clears survive reload")
		suite.check(app.set_start_index("sync")==0, "A completed set starts from stage one")
		app.present_result("LEVEL COMPLETE!",true,true)
		suite.check(not app.overlay_box.find_children("*","Button",true,false).any(func(b):return "Retry" in b.text), "Final set screen has no retry button")
		app.overlay.hide()
		app.world.player.set_hat("hourglass")
		var socket: Node3D = app.world.player.visual.get_node("HatSocket")
		suite.check(socket.get_node("HourglassHat").visible and not socket.get_node("PharaohHat").visible and not socket.get_node("BabyFrogHat").visible, "Only the selected reward hat is visible")
		for i in range(app.unlocked_hats.size()): app.toggle_hat()
		suite.check(app.hat=="hourglass", "Hat button cycles all unlocked hats and returns to the reward")
	if route_failures==0:
		app.play_builtin(4,"sync")
		app.world.set_physics_process(false)
		await physics_frame
		var reckless: Array = []
		for i in range(4): reckless.append(Vector2i.UP)
		for i in range(6): reckless.append(Vector2i.RIGHT)
		for i in range(4): reckless.append(Vector2i.UP)
		for direction in reckless:
			if not app.world.result.is_empty(): break
			app.world.tile_rules.request(direction,false)
			await ticks(26)
		suite.check(app.world.result=="SQUISHED!", "The finale punishes an unplanned double-lane crossing")
	suite.check(app.library==library_before, "Campaign play leaves editor saves unchanged")
	print("YOUR MOVE: %d checks, %d failures" % [suite.checks,suite.failures.size()])
	quit(0 if suite.failures.is_empty() else 1)
