extends SceneTree
const Data = preload("res://scripts/level_data.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var app: Control = preload("res://main.tscn").instantiate()
	app.rule_notices_enabled = false
	root.add_child(app)
	await process_frame
	app.level = Data.blank("Blocked hop", "egypt", 7, 7)
	app.level.game_mode = "tile"
	app.level.move_with_me = true
	app.level.spawn = [2, 4]
	app.level.exit = [4, 1]
	app.level.tiles[3][2] = "wall"
	app.enter_editor()
	app.playtest()
	var beats: int = app.world.tile_rules.beat_count
	var hops: int = app.world.tile_rules.hop_count
	assert(not app.world.tile_rules.request(Vector2i.UP, false), "Wall must reject the hop")
	assert(app.status_label.text.contains("blocked landing") and app.world.tile_rules.hop_count == hops and app.world.tile_rules.beat_count == beats,
		"Rejected hop must explain the obstacle without spending a move or hazard beat")
	assert(app.world.tile_rules.request(Vector2i.RIGHT, false), "An open hop still works after feedback")
	print("PASS: Phase 03 blocked-hop feedback and unchanged movement timing")
	quit()
