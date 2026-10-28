extends RefCounted
const Kit = preload("res://scripts/nyc_streetlife_art.gd")
const Basic = preload("res://scripts/nyc_art.gd")
func configure(app: Control) -> void:
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	var kind := "roach"
	var angle := "threequarter"
	for candidate in ["roach", "skater0", "skater1", "skater2", "props"]:
		if "--gallery-kind-" + candidate in args:
			kind = candidate
	for candidate in ["front", "side", "threequarter"]:
		if "--gallery-view-" + candidate in args:
			angle = candidate
	app.mode = "edit"
	app.world.geometry.visible = false
	app.world.set_physics_process(false)
	app.set_process(false)
	app.sidebar.hide()
	app.overlay.hide()
	app.joystick.hide()
	app.level_banner.hide()
	app.mode_label.text = "NYC STREETLIFE · " + kind.to_upper() + " · " + angle
	app.status_label.text = "Original low-poly street kit · hand-authored geometry and articulated actors"
	var stage := Node3D.new()
	app.world.add_child(stage)
	Basic.box(stage, "Floor", Vector3(36, 0.1, 36), Vector3(0, -0.07, 0), Color("798b91"))
	var focus := Vector3(0, 0.7, 0)
	var extent := 2.1
	if kind == "props":
		extent = 18.0
		focus = Vector3(0, 0.4, 0)
		for i in range(Kit.PROP_KINDS.size()):
			var model := Kit.prop(Kit.PROP_KINDS[i])
			model.position = Vector3((i % 5 - 2) * 3.4, 0, (i / 5 - 0.5) * 6.0)
			stage.add_child(model)
	else:
		var model := Kit.roach() if kind == "roach" else Kit.skater(int(kind.right(1)))
		stage.add_child(model)
		if kind == "roach":
			extent = 1.6
			focus.y = 0.2
	for child in app.world.get_children():
		if child is WorldEnvironment:
			child.environment.background_mode = Environment.BG_COLOR
			child.environment.background_color = Color("3e4c5d")
			child.environment.ambient_light_energy = 0.8
	app.world.editing = true
	app.configure_view()
	var camera: Camera3D = app.world.camera
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = extent
	if angle == "front":
		camera.position = focus + Vector3(0, 0.3, -20)
	elif angle == "side":
		camera.position = focus + Vector3(20, 0.3, 0)
	else:
		camera.position = focus + Vector3(15, 14, -18)
	camera.look_at(focus)
	await app.get_tree().process_frame
	await app.get_tree().process_frame
	app.configure_view()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.streetlifeGalleryReady = " + JSON.stringify({"kind": kind, "view": angle}), true)
