extends SceneTree
var app: Control
var suite = preload("res://tests/integration.gd").new()
func _initialize() -> void:
	app = preload("res://main.tscn").instantiate()
	app.rule_notices_enabled = false
	root.add_child(app)
	call_deferred("run")
func run() -> void:
	await process_frame
	app.set_process(false)
	app.set_sound_enabled(false)
	app.exit_preview = false
	await preload("res://tests/baby_mode.gd").new().run(app,suite)
	print("LANE CROSSING REGRESSION: %d checks, %d failures" % [suite.checks,suite.failures.size()])
	app.hop_audio.clear()
	app.voice.clear()
	OS.delay_msec(150)
	app.queue_free()
	await process_frame
	quit(0 if suite.failures.is_empty() else 1)
