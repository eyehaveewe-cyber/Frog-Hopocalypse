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
	app.new_level("honduras")
	check(app.level.name == "New Honduras" and Data.validate(app.level) == "", "New Honduras creates a valid level")
	check(app.level.has("editor_autosave_id") and app.theme_picker.selected == 3, "New jungle maps retain recovery identity and correct theme selection")
	check(app.themed_tool_buttons.tree.text == "Jungle tree" and app.themed_tool_buttons.pillar.text == "Stepped column", "The palette identifies the jungle objects")
	var empty: Dictionary = app.level.duplicate(true)
	app.change_theme(2)
	check(app.level.theme == "mexico" and app.themed_tool_buttons.tree.text == "Cactus", "Existing Mexico theme and palette remain available")
	app.undo()
	check(app.level == empty and app.theme_picker.selected == 3, "Undo restores the entire Honduras document and theme selection")
	app.redo()
	check(app.level.theme == "mexico", "Redo restores Mexico without changing layout")
	app.open_scenery_demo(5)
	var authored: Dictionary = app.level.duplicate(true)
	check(Data.validate(authored) == "" and Data.reachable(authored), "Jungle River validates with a structural log crossing")
	check(app.save_level(), "Jungle River saves through the normal library")
	var slot: int = app.saved_picker.item_count - 1
	app.new_level("egypt")
	app.load_saved(slot)
	check(app.level == authored and not app.editor_has_unsaved_changes(), "Reload restores the full jungle map with a clean saved baseline")
	var portable: Dictionary = Data.normalize(JSON.parse_string(JSON.stringify(authored)))
	check(portable == authored and Data.validate(portable) == "", "Portable JSON retains the jungle theme and moving log settings")
	for kind in ["tree", "pillar", "decoration"]:
		var visual := Art.scenery(kind,"honduras",3)
		check(visual.get_meta("jungle_kind") == kind and visual.find_children("*","MeshInstance3D",true,false).size() > 0, "Distinct jungle geometry exists for " + kind)
		check(visual.find_children("*","CollisionObject3D",true,false).is_empty(), "Jungle " + kind + " visuals leave collision to the established world rules")
		visual.free()
	for variant in range(5):
		var tree := Art.scenery("tree","honduras",variant)
		check(tree.get_meta("tree_variant") == variant, "Deterministic broadleaf variation %d is available" % variant)
		tree.free()
	check(Art.Pixels.get_texture("jungle_stone_wall").get_image().has_mipmaps(), "Vine-covered walls use the filtered mipmapped path")
	app.playtest()
	app.world.set_physics_process(false)
	await physics_frame
	var log_start: Vector3 = app.world.crossing.movers[0].node.position
	var supported := false
	# Actual continuous movement, collisions, water and moving-platform carrying.
	# No teleports, invulnerability or changed controller/obstacle timing.
	for target in [[2,8],[8,8],[8,4],[14,4],[14,2]]:
		var destination: Vector3 = app.world.cell_position(target)
		var frames := 0
		while app.world.player.position.distance_to(destination) > 0.16 and frames < 1000 and app.world.result.is_empty():
			var delta: Vector3 = destination-app.world.player.position
			app.world.input_vector = Vector2(delta.x,delta.z).normalized()
			await physics_frame
			app.world._physics_process(1.0/60)
			if app.world.position_cell(app.world.player.position).y == 6 and not app.world.crossing.log_at(app.world.player.position).is_empty(): supported = true
			frames += 1
	app.world.input_vector = Vector2.ZERO
	check(supported and app.world.crossing.movers[0].node.position.distance_to(log_start) > 0.5, "Actual route rides the moving log with water and carrying active")
	check(app.world.result == "LEVEL COMPLETE!", "The real frog crosses the river and reaches the exit")
	app.enter_editor()
	check(app.level == authored, "Returning from river playtest preserves the authored map")
	app.start_play(true)
	app.world.set_physics_process(false)
	app.world.input_vector = Vector2.LEFT
	for i in range(80):
		await physics_frame
		app.world._physics_process(1.0/60)
	check(app.world.position_cell(app.world.player.position).x == 1 and app.world.result.is_empty(), "Vine-covered perimeter walls physically block the frog")
	app.hop_audio.clear()
	app.voice.clear()
	print("HONDURAS KIT: %d checks, %d failures" % [checks,failures.size()])
	OS.delay_msec(150)
	app.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
