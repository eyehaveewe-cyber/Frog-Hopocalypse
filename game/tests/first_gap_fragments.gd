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
	var imported: Dictionary = Data.blank("Fragments beyond first gap", "egypt", 7, 7)
	imported.game_mode = "tile"
	imported.rules = {"long_hop": "fragments"}
	imported.spawn = [3, 5]
	imported.exit = [3, 1]
	for x in range(1, 6): imported.tiles[3][x] = "water"
	for i in range(3):
		imported.objects.append({"id": "fragment_%d" % i, "type": "hop_fragment", "pos": [i + 2, 2], "solid": false})
	assert(Data.reachable(imported) and not Data.reachable(imported, false), "The water row must require a long hop")
	var error: String = Data.validate(imported)
	assert(error.contains("three fragments") and error.contains("before"), "Fragments across the first gap need an actionable error: " + error)
	assert(not app.import_text(JSON.stringify(imported)), "Impossible first-gap map must not replace the editor map")
	assert(app.level == current and app.status_label.text == error, "Rejected import must preserve the current edit")
	for i in range(3): imported.objects[i].pos = [i + 2, 4]
	assert(Data.validate(imported).is_empty(), "Three reachable fragments allow the first required long hop")
	for i in range(3): imported.objects[i].pos = [i + 2, 2]
	imported.tiles[3][1] = "floor"
	assert(Data.validate(imported).is_empty(), "A dry short-hop route needs no pre-gap fragments")
	print("PASS: Phase 17 first-gap fragment reachability and editor preservation")
	quit()
