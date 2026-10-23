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
	var imported: Dictionary = Data.blank("Misplaced seam anchor")
	imported.objects = [{"id": "worm", "type": "critter", "pos": [5.5, 5.5], "behavior": "seam_patrol", "waypoints": [], "seam_anchor": [10, 10], "speed": 1.6}]
	var error: String = Data.validate(imported)
	assert(error.contains("seam") and error.contains("placement tile"), "Distant seam placement reference needs guidance: " + error)
	assert(not app.import_text(JSON.stringify(imported)), "Import must reject a misplaced seam reference")
	assert(app.level == current and app.status_label.text == error, "Rejected import must preserve edits and show the cause")
	imported.objects[0].seam_anchor = [5, 5]
	assert(Data.validate(imported).is_empty(), "Adjacent placement tile is valid")
	imported.objects[0].erase("seam_anchor")
	assert(Data.validate(imported).is_empty(), "Older seam worms without an anchor remain valid")
	print("PASS: Phase 15 seam placement reference and editor preservation")
	quit()
