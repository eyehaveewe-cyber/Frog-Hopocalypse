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
	var imported: Dictionary = Data.blank("Fragment gap", "egypt", 7, 7)
	imported.game_mode = "tile"
	imported.rules = {"long_hop": "fragments"}
	imported.spawn = [3, 5]
	imported.exit = [3, 1]
	for x in range(1, 6):
		imported.tiles[3][x] = "water"
	assert(Data.reachable(imported), "Long-hop geometry must cross the single water row")
	var error: String = Data.validate(imported)
	assert(error.contains("three fragments") and error.contains("long hop"), "An impossible fragment crossing needs a correction: " + error)
	assert(not app.import_text(JSON.stringify(imported)), "Import must reject the impossible resource requirement")
	assert(app.level == current and app.status_label.text == error, "Rejected import must preserve the editor map and show the error")
	for i in range(3):
		imported.objects.append({"id": "fragment_%d" % i, "type": "hop_fragment", "pos": [i + 2, 5], "solid": false})
	assert(Data.validate(imported).is_empty(), "Three available fragments permit the structurally reachable long hop")
	imported.objects.clear()
	for x in range(1, 6):
		imported.tiles[3][x] = "floor"
	assert(Data.validate(imported).is_empty(), "A dry short-hop route is valid without fragments")
	print("PASS: Phase 15 impossible fragment requirement and edit preservation")
	quit()
