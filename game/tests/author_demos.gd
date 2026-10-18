extends SceneTree
## Reconstruct each handcrafted specification through the real editor operations,
## then serialize the resulting editor document as the bundled playable map.
const Data = preload("res://scripts/level_data.gd")

func _initialize() -> void:
	call_deferred("author")

func author() -> void:
	var app := preload("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	for path in app.BUILTINS:
		var target := Data.load_json(path)
		assert(not target.is_empty())
		app.new_level(target.theme)
		app.name_field.text = target.name
		app.commit_name()
		for z in range(target.height):
			for x in range(target.width):
				if app.level.tiles[z][x] != target.tiles[z][x]:
					app.set_tool(target.tiles[z][x])
					app.edit_cell(Vector2i(x, z))
		for kind in ["spawn", "exit"]:
			app.set_tool(kind)
			app.edit_cell(Vector2i(target[kind][0], target[kind][1]))
		for obj in target.objects:
			app.set_tool(obj.type)
			app.stroke_changed = false
			app.edit_cell(Vector2i(obj.pos[0], obj.pos[1]))
			var placed: Dictionary = app.selected_object()
			assert(not placed.is_empty())
			placed.id = obj.id
			app.selection = obj.id
			for key in obj:
				if key not in ["id", "type", "pos"]:
					app.change_property(key, obj[key])
		assert(Data.validate(app.level) == "")
		assert(Data.reachable(app.level))
		# Use the editor's local save and the same serializer as Export JSON.
		app.save_level()
		assert(Data.save_json(path, app.level) == OK)
		print("Authored and saved through editor: ", path)
	quit()
