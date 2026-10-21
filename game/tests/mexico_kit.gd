extends SceneTree
const Data = preload("res://scripts/level_data.gd")
const Art = preload("res://scripts/art.gd")
var app: Control
var failures: Array = []
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok: failures.append(message)
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
	app.editor_navigation_bypass = true
	app.new_level("mexico")
	check(app.level.name == "New Mexico" and Data.validate(app.level) == "", "New Mexico creates a valid editable map")
	check(app.level.has("editor_autosave_id"), "New theme participates in the existing recovery checkpoint system")
	check(app.theme_picker.selected == 2 and app.themed_tool_buttons.tree.text == "Cactus", "Theme picker and palette identify the cactus kit")
	app.change_theme(1)
	check(app.level.theme == "swamp" and app.themed_tool_buttons.tree.text == "Tree", "Switching to Swamp restores its palette")
	app.undo()
	check(app.level.theme == "mexico" and app.theme_picker.selected == 2, "Undo restores Mexico and its picker")
	app.redo()
	check(app.level.theme == "swamp", "Redo restores the previous theme change")
	app.open_scenery_demo(4)
	var authored: Dictionary = app.level.duplicate(true)
	check(Data.validate(authored) == "" and Data.reachable(authored), "Courtyard Gardens validates and has a structural exit route")
	check(app.save_level(), "Mexico showcase saves through the normal local library")
	var slot: int = app.saved_picker.item_count - 1
	app.new_level("egypt")
	app.load_saved(slot)
	check(app.level == authored and not app.editor_has_unsaved_changes(), "Local reload retains the entire Mexico map and a clean saved baseline")
	var portable: Dictionary = Data.normalize(JSON.parse_string(JSON.stringify(authored)))
	check(portable == authored and Data.validate(portable) == "", "Portable JSON round-trip retains theme, terrain and modular objects")
	for theme_name in ["egypt", "swamp"]:
		check(Data.validate(Data.blank("Legacy fixture",theme_name)) == "", "Existing " + theme_name + " maps remain accepted")
	var bad: Dictionary = authored.duplicate(true)
	bad.theme = "unknown"
	check(Data.validate(bad) != "", "Unknown themes are still rejected")
	for kind in ["tree", "pillar", "decoration"]:
		var visual := Art.scenery(kind,"mexico",3)
		check(visual.get_meta("courtyard_kind") == kind and visual.find_children("*","MeshInstance3D",true,false).size() > 0, "Mexico " + kind + " builds its distinct modular model")
		check(visual.find_children("*","CollisionObject3D",true,false).is_empty(), "Theme visuals add no hidden physics for " + kind)
		visual.free()
	for variant in range(5):
		var cactus := Art.scenery("tree","mexico",variant)
		check(cactus.get_meta("tree_variant") == variant, "Cactus variation %d is deterministic" % variant)
		cactus.free()
	check(Art.Pixels.get_texture("stucco_wall").get_image().has_mipmaps(), "Stucco walls retain the filtered mipmapped material path")
	app.playtest()
	app.world.set_physics_process(false)
	await physics_frame
	# Drive the actual continuous controller from spawn around the water court.
	# No player teleport, altered speed, invulnerability or disabled collision.
	for target in [[2,2],[14,2]]:
		var destination: Vector3 = app.world.cell_position(target)
		var frames := 0
		while app.world.player.position.distance_to(destination) > 0.16 and frames < 1000 and app.world.result.is_empty():
			var delta: Vector3 = destination-app.world.player.position
			app.world.input_vector = Vector2(delta.x,delta.z).normalized()
			await physics_frame
			app.world._physics_process(1.0/60)
			frames += 1
	app.world.input_vector = Vector2.ZERO
	check(app.world.result == "LEVEL COMPLETE!", "Actual frog controller reaches the exit around the courtyard with collisions active")
	app.enter_editor()
	check(app.level == authored, "Returning from the showcase playtest preserves every authored setting")
	# Same wall collision contract in the new theme, exercised independently.
	app.start_play(true)
	app.world.set_physics_process(false)
	app.world.input_vector = Vector2.LEFT
	for i in range(80):
		await physics_frame
		app.world._physics_process(1.0/60)
	check(app.world.position_cell(app.world.player.position).x == 1 and app.world.result.is_empty(), "Courtyard perimeter walls physically stop the frog")
	app.hop_audio.clear()
	app.voice.clear()
	print("MEXICO KIT: %d checks, %d failures" % [checks,failures.size()])
	OS.delay_msec(150)
	app.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
