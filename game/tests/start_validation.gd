extends SceneTree
const Data = preload("res://scripts/level_data.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var app: Control = preload("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.new_level()
	var start: Array = app.level.spawn.duplicate()
	app.set_tool("road")
	app.edit_cell(Vector2i(start[0], start[1]))
	var draft: Dictionary = app.level.duplicate(true)
	assert(draft.tiles[start[1]][start[0]] == "road", "Editor must reproduce a road under the start")
	var error: String = Data.validate(draft)
	assert(error.contains("frog start") and error.contains("road"), "Unsafe start needs a specific correction: " + error)
	assert(not app.save_level(), "An unsafe start must not be saved as a playable level")
	assert(app.level == draft and app.status_label.text == error, "Failed save must explain the issue and keep the edit")
	app.set_tool("path")
	app.edit_cell(Vector2i(start[0], start[1]))
	assert(Data.validate(app.level).is_empty(), "Painting a safe bank resolves the error")
	print("PASS: Phase 15 unsafe start feedback and edit preservation")
	quit()
