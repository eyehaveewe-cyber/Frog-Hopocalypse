extends SceneTree
const Suite = preload("res://tests/integration.gd")
var suite = Suite.new()
var app: Control

func _initialize() -> void:
	app = preload("res://main.tscn").instantiate()
	root.add_child(app)
	call_deferred("run")

func drain_voice() -> void:
	while app.voice.busy():
		app.voice.player.stop()
		app.voice.play_next()

func run() -> void:
	await process_frame
	app.set_process(false)
	app.world.set_physics_process(false)
	var voice: Node = app.voice
	suite.check(voice.clips.size() == 17, "All and only the 17 approved recordings load")
	voice.say("begin")
	suite.check(not voice.busy() and voice.history.is_empty(), "No audio before an input gesture")
	voice.unlock()
	app.exit_preview = true
	app.play_builtin(3)
	suite.check(voice.history == ["baby_mode"] and voice.queue == ["traffic_start"], "Baby Mode and traffic warning serialize at stage-four start")
	drain_voice()
	app.update_announcements(5.0)
	suite.check("begin" not in voice.history and app.begin_pending, "Begin waits for exit preview")
	app.world.cancel_exit_preview()
	app.update_announcements(0.01)
	suite.check(voice.history.back() == "begin" and not app.begin_pending, "Begin follows stage display and completed preview")
	drain_voice()
	app.world.player.position = app.world.cell_position([8, 9])
	app.update_announcements(0.01)
	app.world.player.position = app.world.cell_position([8, 10])
	app.update_announcements(0.01)
	for i in range(20):
		app.update_announcements(0.01)
	suite.check(voice.history.count("traffic_return") == 1, "Return warning fires once when leaving the final street toward the start")
	drain_voice()
	app.world.player.position = app.world.cell_position([8, 9])
	app.update_announcements(0.01)
	app.world.player.position = app.world.cell_position([8, 10])
	app.update_announcements(0.01)
	suite.check(voice.history.count("traffic_return") == 2, "Another visit to the final street rearms its return warning")
	app.retry()
	suite.check(not app.return_warning_armed and voice.queue.is_empty(), "Retry cancels stale announcements and traversal state")
	voice.rng.seed = 123456
	var counts := {}
	var drown: Array = []
	var patrol: Array = []
	for i in range(100):
		for pair in [["SQUISHED!", ""], ["HIT!", ""], ["SPLASHED!", ""], ["CROAKED!", "wander"], ["CROAKED!", "patrol"]]:
			var cue: String = voice.death_cue(pair[0], pair[1])
			counts[cue] = int(counts.get(cue, 0)) + 1
			if pair[0] == "SPLASHED!" and cue in ["sunken_frog", "frog_sunk"]:
				drown.append(cue)
			if pair[1] == "patrol" and cue != "busted":
				patrol.append(cue)
	suite.check(counts.has_all(["splatted", "dartsploded", "watersploded", "bugsploded", "wormed", "wormsploded", "busted"]), "Specific deaths, occasional water line and rare general line are reachable")
	var alternating := true
	for sequence in [drown, patrol]:
		for i in range(1, sequence.size()):
			alternating = alternating and sequence[i] != sequence[i - 1]
	suite.check(alternating and counts.busted < 60, "Primary drowning/patrol lines alternate and general death line stays rare")
	app.completed_stages = [0, 1, 2]
	app.unlocked_hats = ["none", "pharaoh"]
	app.start_play(false)
	app.world.finish("LEVEL COMPLETE!")
	suite.check(voice.history.back() == "baby_win" and voice.queue == ["baby_frog"] and app.hat == "baby", "Fourth clear plays set victory then earned baby-frog hat announcement")
	var history_size: int = voice.history.size()
	app.world.finish("SQUISHED!")
	suite.check(voice.history.size() == history_size and app.deaths == 0, "World result guard rejects duplicate death after victory")
	app.play_builtin(1, "human")
	suite.check(voice.history.back() == "gloopbutt", "Gloopbutt gets its authored level name")
	app.play_builtin(3, "human")
	suite.check(voice.history.back() == "frogbutt", "Frogbutt gets its authored level name")
	app.play_builtin(0, "baby")
	drain_voice()
	voice.history.clear()
	voice.rng.seed = 123456
	app.world.death_cause = "wander"
	app.world.finish("CROAKED!")
	app.world.finish("CROAKED!")
	suite.check(voice.history == ["bugsploded"] and app.deaths == 1, "Bug collision triggers one bugsploded cue and one death")
	app.world.result_time = 1.7
	app.update_result_presentation()
	drain_voice()
	app.update_result_presentation()
	suite.check(voice.history == ["bugsploded"] and voice.queue.is_empty() and app.overlay.visible, "Death screen does not replay or queue the bug cue")
	suite.check(voice.clips["bugsploded"].get_length() < 1.5, "Bug cue contains only the first take before the repeated speech section")
	voice.set_enabled(false)
	voice.say("begin")
	suite.check(not voice.busy(), "Mute immediately clears playback and pending voices")
	app.sound_enabled = false
	app.save_profile()
	app.sound_enabled = true
	app.load_profile()
	suite.check(not app.sound_enabled and app.completed_stages == [0, 1, 2, 3], "Mute setting and campaign progress survive profile reload")
	print("VOICE CHECKS: %d passed, %d failed" % [suite.checks - suite.failures.size(), suite.failures.size()])
	app.queue_free()
	await process_frame
	await process_frame
	quit(0 if suite.failures.is_empty() else 1)
