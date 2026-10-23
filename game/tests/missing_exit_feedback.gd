extends SceneTree
const Data = preload("res://scripts/level_data.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var app: Control = preload("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.new_level()
	app.set_tool("path")
	app.edit_cell(Vector2i(3, 3))
	var current: Dictionary = app.level.duplicate(true)
	var imported: Dictionary = Data.blank("Missing exit example")
	imported.erase("exit")
	var error: String = Data.validate(imported)
	assert(error.contains("Exit gate") and error.contains("missing"), "Missing exit needs placement guidance: " + error)
	assert(not app.import_text(JSON.stringify(imported)), "Import must reject a missing exit")
	assert(app.level == current and app.status_label.text == error, "Rejected import must explain the problem and preserve the current edit")
	imported.exit = [15, 1]
	assert(Data.validate(imported).is_empty(), "Adding an exit resolves the error")
	print("PASS: Phase 15 missing-exit feedback and editor preservation")
	quit()
