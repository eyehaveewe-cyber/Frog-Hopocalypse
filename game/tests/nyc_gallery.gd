extends RefCounted
## Debug-only repeatable native/browser art inspection. Main owns opt-in gating.
const Kit = preload("res://scripts/nyc_art.gd")

func configure(app: Control) -> void:
	var args := OS.get_cmdline_user_args() + OS.get_cmdline_args()
	var kind := "taxi"
	var angle := "threequarter"
	for candidate in ["taxi", "sedan", "bus", "truck"]:
		if "--gallery-kind-" + candidate in args:
			kind = candidate
	for candidate in ["front", "side", "threequarter"]:
		if "--gallery-view-" + candidate in args:
			angle = candidate
	app.mode = "edit"
	app.world.load_level(app.Data.blank("Vehicle art review"), true)
	app.world.geometry.visible = false
	app.set_process(false)
	app.world.set_physics_process(false)
	app.sidebar.hide()
	app.overlay.hide()
	app.joystick.hide()
	app.level_banner.hide()
	app.mode_label.text = "NYC ASSET REVIEW · " + kind.to_upper() + " · " + angle
	app.status_label.text = "Original PS1-style vehicle · +X forward · four Z-axis wheel pivots · length %.1f · width 1.1" % Kit.vehicle_length(kind)
	var stage := Node3D.new()
	stage.name = "NYCVehicleGallery"
	app.world.add_child(stage)
	Kit.box(stage, "NeutralStage", Vector3(15, 0.10, 15), Vector3(0, -0.065, 0), Color("717c84"))
	var model := Kit.vehicle(kind)
	stage.add_child(model)
	# A single wheel pose exposes the modeled spoke independently of symmetry.
	for wheel in model.find_children("Wheel_*", "Node3D", false, false):
		wheel.rotation.z = 0.48
	for child in app.world.get_children():
		if child is WorldEnvironment:
			child.environment.background_mode = Environment.BG_COLOR
			child.environment.background_color = Color("3e4c5d")
			child.environment.ambient_light_energy = 0.75
	var camera: Camera3D = app.world.camera
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.6 if angle == "front" else Kit.vehicle_length(kind) * 0.72 + 0.7
	var focus := Vector3(0, 0.78, 0)
	if angle == "front":
		camera.position = Vector3(7, 1.0, 0)
	elif angle == "side":
		camera.position = Vector3(0, 1.25, 7)
	else:
		camera.position = Vector3(5, 3.6, 5)
	camera.look_at(focus)
	app.configure_view()
	await app.get_tree().process_frame
	await app.get_tree().process_frame
	app.configure_view()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.nycGalleryReady = " + JSON.stringify({"kind": kind, "view": angle}) + ";")
