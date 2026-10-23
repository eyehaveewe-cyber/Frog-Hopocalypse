extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	# Fields and stage indices match save_profile() in the v47 source, 0e6f93f.
	var old := ConfigFile.new()
	old.set_value("baby_mode", "completed", [0, 1, 2, 3])
	old.set_value("not_as_hard", "completed", [0, 1])
	old.set_value("bonus", "completed", [0, 1, 2])
	old.set_value("tile_hop", "completed", [0])
	old.set_value("hats", "baby_unlocked", true)
	old.set_value("hats", "equipped", "baby")
	old.set_value("skins", "equipped", "purple")
	old.set_value("sets", "last_cleared", {"baby": 3, "human": 1, "bonus": 2, "tile": 0})
	assert(old.save("user://profile.cfg") == OK, "Cannot write isolated v47 fixture")
	var app: Control = preload("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	assert(app.completed_stages == [0, 1, 2, 3], "Baby Mode clears lost")
	assert(app.completed_human_stages == [0, 1], "Not as Hard clears lost")
	assert(app.completed_bonus_stages == [0, 1, 2], "Bonus clears lost")
	assert(app.completed_tile_stages == [0], "Tile Hop clear lost")
	assert(app.completed_sync_stages.is_empty(), "New set should start empty")
	assert("baby" in app.unlocked_hats and app.hat == "baby", "Earned baby hat or selection lost")
	assert(app.skin == "purple", "Earned purple skin lost")
	assert(app.last_cleared_stages == {"baby": 3, "human": 1, "bonus": 2, "tile": 0}, "Set replay positions lost")
	app.save_profile()
	app.load_profile()
	assert(app.completed_stages == [0, 1, 2, 3] and app.completed_human_stages == [0, 1] and app.completed_bonus_stages == [0, 1, 2] and app.completed_tile_stages == [0], "Legacy clears lost after current-version save")
	assert(app.hat == "baby" and app.skin == "purple", "Legacy cosmetic selection lost after current-version save")
	print("PASS: v47 native profile retains completed maps, replay positions, hat, and skin through v48 load/save")
	quit()
