extends RefCounted
## Original modular low-poly primitives. No external asset downloads or licenses.
static var materials: Dictionary = {}
static var meshes: Dictionary = {}
const Pixels = preload("res://scripts/pixel_textures.gd")
const RetroSurface = preload("res://shaders/retro_surface.gdshader")
static var retro_materials: Dictionary = {}
static var retro_enabled := true
static var compatibility_mode := false
static var swamp_haze := false
static var draw_limit := 0.0

static func retro_mat(kind: String, color: Color = Color.WHITE) -> Material:
	if compatibility_mode:
		var safe_key := "pixel:" + kind + str(color)
		if not materials.has(safe_key):
			var safe := StandardMaterial3D.new()
			safe.albedo_color = color
			safe.albedo_texture = Pixels.get_texture(kind)
			safe.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			if kind == "brick" or kind.ends_with("_wall"):
				safe.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			# Android drivers can fail linking the lit GLES3 scene variant even
			# without custom shaders. Keep the fallback free of lighting varyings.
			safe.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			materials[safe_key] = safe
		return materials[safe_key]
	var key := kind + str(color)
	if retro_materials.has(key):
		return retro_materials[key]
	var material := ShaderMaterial.new()
	material.shader = RetroSurface
	material.set_shader_parameter("albedo_color", color)
	material.set_shader_parameter("pixel_texture", Pixels.get_texture(kind))
	material.set_shader_parameter("filtered_wall", kind == "brick" or kind.ends_with("_wall"))
	if kind == "brick" or kind.ends_with("_wall"):
		material.set_shader_parameter("wall_texture", Pixels.get_texture(kind))
	material.set_shader_parameter("animated_water", kind in ["water", "swamp_water"])
	material.set_shader_parameter("distance_limit",draw_limit)
	material.set_shader_parameter("retro_amount", 1.0 if retro_enabled else 0.0)
	material.set_shader_parameter("haze_color", Vector3(0.14, 0.08, 0.22) if swamp_haze else Vector3(0.09, 0.12, 0.22))
	retro_materials[key] = material
	return material

static func set_retro(enabled: bool, swamp: bool) -> void:
	retro_enabled = enabled
	swamp_haze = swamp
	for material in retro_materials.values():
		material.set_shader_parameter("retro_amount", 1.0 if enabled else 0.0)
		material.set_shader_parameter("haze_color", Vector3(0.14, 0.08, 0.22) if swamp else Vector3(0.09, 0.12, 0.22))

static func set_draw_distance(limit: float) -> void:
	draw_limit = limit
	for material in retro_materials.values():
		material.set_shader_parameter("distance_limit",limit)

static func set_simulation_time(time: float, enabled: bool) -> void:
	for material in retro_materials.values():
		material.set_shader_parameter("simulation_time",time)
		material.set_shader_parameter("movement_time",enabled)

static func textured(node: MeshInstance3D, kind: String, color: Color = Color.WHITE) -> MeshInstance3D:
	node.material_override = retro_mat(kind, color)
	return node

static func mat(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var key := str(color) + str(glow)
	if materials.has(key):
		return materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	m.metallic_specular = 0.0
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if compatibility_mode else BaseMaterial3D.SHADING_MODE_PER_VERTEX
	if glow > 0 and not compatibility_mode:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	materials[key] = m
	return m

static func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var key := "box" + str(size)
	if not meshes.has(key):
		var mesh := BoxMesh.new()
		mesh.size = size
		meshes[key] = mesh
	return piece(parent, meshes[key], pos, color)

static func orb(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var key := "orb" + str(size)
	if not meshes.has(key):
		var mesh := SphereMesh.new()
		mesh.radius = 0.5
		mesh.height = 1.0
		mesh.radial_segments = 10
		mesh.rings = 5
		meshes[key] = mesh
	var node := piece(parent, meshes[key], pos, color)
	node.scale = size
	return node

static func cylinder(parent: Node3D, radius: float, top: float, height: float, pos: Vector3, color: Color, sides: int = 8) -> MeshInstance3D:
	var key := "cyl" + str([radius, top, height, sides])
	if not meshes.has(key):
		var mesh := CylinderMesh.new()
		mesh.bottom_radius = radius
		mesh.top_radius = top
		mesh.height = height
		mesh.radial_segments = sides
		meshes[key] = mesh
	return piece(parent, meshes[key], pos, color)

static func piece(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat(color)
	node.position = pos
	parent.add_child(node)
	return node

static func batch_static(root: Node3D, excluded: Array, chunk_size: float = 0.0) -> void:
	# Collapse repeated floor/wall pieces into instanced draws. Collision bodies
	# remain independent; moving actors, traps, the exit and editor markers do not
	# enter a batch. Shared mesh/material resources are created by the kit above.
	var groups: Dictionary = {}
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var skip := false
		for ancestor in excluded:
			if child == ancestor or ancestor.is_ancestor_of(child):
				skip = true
				break
		if skip:
			continue
		var key := str(child.mesh.get_instance_id()) + ":" + str(child.material_override.get_instance_id())
		if chunk_size > 0:
			var pos := root.to_local(child.global_position)
			key += ":" + str(Vector2i(floori(pos.x/chunk_size),floori(pos.z/chunk_size)))
		if not groups.has(key):
			groups[key] = []
		groups[key].append(child)
	for group in groups.values():
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = group[0].mesh
		multi.instance_count = group.size()
		var origin := Vector3.ZERO
		if chunk_size > 0:
			var p: Vector3 = root.to_local(group[0].global_position)
			origin = Vector3((floorf(p.x/chunk_size)+0.5)*chunk_size,0,(floorf(p.z/chunk_size)+0.5)*chunk_size)
		for i in range(group.size()):
			var transform: Transform3D = root.global_transform.affine_inverse() * group[i].global_transform
			transform.origin -= origin
			multi.set_instance_transform(i, transform)
		var renderer := MultiMeshInstance3D.new()
		renderer.position = origin
		renderer.set_meta("spatial_chunk",chunk_size > 0)
		renderer.multimesh = multi
		renderer.material_override = group[0].material_override
		root.add_child(renderer)
		for child in group:
			child.get_parent().remove_child(child)
			child.queue_free()

static func solid(parent: Node3D, size: Vector3, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	parent.add_child(body)
	return body

static func frog(hat: bool = true) -> Node3D:
	var root := Node3D.new()
	root.name = "FrogVisual"
	var green := Color("9bc952")
	textured(orb(root, Vector3(0.78, 0.46, 0.86), Vector3(0, 0.30, 0.12), green), "frog")
	orb(root, Vector3(0.62, 0.24, 0.66), Vector3(0, 0.17, -0.12), Color("d4d98c"))
	textured(orb(root, Vector3(0.95, 0.40, 0.65), Vector3(0, 0.39, -0.23), green), "frog")
	for side in [-1, 1]:
		var thigh := orb(root, Vector3(0.40, 0.26, 0.52), Vector3(side * 0.36, 0.17, 0.32), green)
		thigh.name = "HindLegL" if side == -1 else "HindLegR"
		var shin := orb(root, Vector3(0.14, 0.13, 0.3), Vector3(side * 0.45, 0.12, 0.4), green)
		shin.name = "HindShinL" if side == -1 else "HindShinR"
		shin.hide()
		orb(root, Vector3(0.14, 0.14, 0.42), Vector3(side * 0.35, 0.12, -0.32), green)
		for toe in range(3):
			var foot := box(root, Vector3(0.06, 0.045, 0.24), Vector3(side * (0.39 + toe * 0.065), 0.045, -0.52 + toe * 0.04), Color("c6b95a"))
			foot.rotation.y = side * (toe - 1) * 0.35
			var back_foot := box(root, Vector3(0.07, 0.05, 0.28), Vector3(side * (0.38 + toe * 0.065), 0.045, 0.43 + toe * 0.02), green)
			back_foot.rotation.y = side * (toe - 1) * 0.3
			back_foot.name = ("HindToeL" if side == -1 else "HindToeR") + str(toe)
		orb(root, Vector3(0.29, 0.29, 0.28), Vector3(side * 0.26, 0.59, -0.29), green)
		orb(root, Vector3(0.20, 0.19, 0.12), Vector3(side * 0.26, 0.61, -0.41), Color("e7b94f"))
		orb(root, Vector3(0.07, 0.145, 0.05), Vector3(side * 0.26, 0.61, -0.47), Color("172b22"))
		orb(root, Vector3(0.04, 0.04, 0.025), Vector3(side * 0.26 - 0.025, 0.66, -0.50), Color("fff3cf"))
	box(root, Vector3(0.42, 0.025, 0.025), Vector3(0, 0.31, -0.55), Color("3d5a2b"))
	for part in root.get_children():
		if part is MeshInstance3D:
			part.set_meta("frog_base_material", part.material_override)
	var socket := Node3D.new()
	socket.name = "HatSocket"
	socket.position.y = 0.65
	root.add_child(socket)
	var crown := Node3D.new()
	crown.name = "PharaohHat"
	socket.add_child(crown)
	box(crown, Vector3(0.65, 0.12, 0.4), Vector3(0, 0.04, 0.08), Color("e9bc58"))
	for side in [-1, 1]:
		box(crown, Vector3(0.17, 0.48, 0.3), Vector3(side * 0.38, -0.12, 0.1), Color("e9bc58"))
		for y in range(3):
			box(crown, Vector3(0.18, 0.055, 0.31), Vector3(side * 0.38, -0.27 + y * 0.13, 0.1), Color("2b707b"))
	cylinder(crown, 0.10, 0.0, 0.24, Vector3(0, 0.21, -0.03), Color("f5d775"))
	crown.visible = hat
	var baby_hat := Node3D.new()
	baby_hat.name = "BabyFrogHat"
	socket.add_child(baby_hat)
	var green_hat := Color("78ac72")
	var face := orb(baby_hat, Vector3(1.04, 0.51, 0.92), Vector3(0, 0.17, 0.08), green_hat)
	face.name = "FrogHead"
	cylinder(baby_hat, 0.49, 0.47, 0.13, Vector3(0, 0.01, 0.08), green_hat.darkened(0.13), 12)
	for side in [-1, 1]:
		orb(baby_hat, Vector3(0.39, 0.36, 0.32), Vector3(side * 0.29, 0.40, -0.08), green_hat)
		var eye := orb(baby_hat, Vector3(0.29, 0.27, 0.10), Vector3(side * 0.29, 0.42, -0.25), Color("f3f1da"))
		eye.name = "FrogEyeLeft" if side == -1 else "FrogEyeRight"
		orb(baby_hat, Vector3(0.15, 0.17, 0.04), Vector3(side * 0.29, 0.42, -0.31), Color("233128"))
		orb(baby_hat, Vector3(0.045, 0.05, 0.02), Vector3(side * 0.27, 0.46, -0.335), Color.WHITE)
		orb(baby_hat, Vector3(0.11, 0.065, 0.025), Vector3(side * 0.27, 0.14, -0.335), Color("d9af89"))
	# A stitched smile makes the soft cap read as a complete little frog head.
	var smile := Node3D.new()
	smile.name = "FrogSmile"
	baby_hat.add_child(smile)
	var mouth := [Vector3(-0.19, 0.17, -0.35), Vector3(-0.12, 0.11, -0.38), Vector3(0, 0.09, -0.39), Vector3(0.12, 0.11, -0.38), Vector3(0.19, 0.17, -0.35)]
	for i in range(mouth.size() - 1):
		var stroke := box(smile, Vector3(0.025, 0.025, mouth[i].distance_to(mouth[i + 1])), (mouth[i] + mouth[i + 1]) / 2, Color("294330"))
		stroke.quaternion = Quaternion(Vector3.FORWARD, (mouth[i + 1] - mouth[i]).normalized())
	for i in range(12):
		var angle := i * TAU / 12
		var stitch := box(baby_hat, Vector3(0.045, 0.15, 0.035), Vector3(sin(angle) * 0.47, 0.16, 0.08 + cos(angle) * 0.40), green_hat.lightened(0.18))
		stitch.rotation.y = angle
	baby_hat.visible = false
	return root

static func critter(theme_name: String, behavior: String) -> Node3D:
	var root := Node3D.new()
	var color := Color("d36f48") if theme_name == "egypt" else Color("dc89de")
	if behavior in ["patrol", "seam_patrol"]:
		if behavior == "seam_patrol":
			color = Color("70b7ce")
		for i in range(4):
			orb(root, Vector3(0.5 - i * 0.05, 0.27, 0.4), Vector3(sin(i * 1.1) * 0.13, 0.22, -0.3 + i * 0.25), color)
			if behavior == "seam_patrol":
				orb(root, Vector3(0.3, 0.12, 0.15), Vector3(sin(i * 1.1) * 0.13, 0.35, -0.3 + i * 0.25), Color("f3d47c"))
	else:
		orb(root, Vector3(0.7, 0.38, 0.85), Vector3(0, 0.25, 0), color)
		box(root, Vector3(0.035, 0.02, 0.6), Vector3(0, 0.44, 0.05), color.darkened(0.35))
		for side in [-1, 1]:
			for i in range(3):
				var leg := box(root, Vector3(0.3, 0.07, 0.08), Vector3(side * 0.4, 0.14, -0.25 + i * 0.24), color.darkened(0.3))
				leg.rotation.y = side * (i - 1) * 0.4
	for side in [-1, 1]:
		orb(root, Vector3(0.13, 0.15, 0.12), Vector3(side * 0.16, 0.36, -0.39), Color("fff2c5"))
		orb(root, Vector3(0.06, 0.08, 0.05), Vector3(side * 0.16, 0.37, -0.45), Color("261d32"))
	return root

static func scenery(kind: String, theme_name: String, variant: int = 0) -> Node3D:
	var root := Node3D.new()
	var sand := Color("c9a66c") if theme_name == "egypt" else Color("736b94")
	match kind:
		"pillar":
			box(root, Vector3(0.9, 0.15, 0.9), Vector3(0, 0.075, 0), sand)
			cylinder(root, 0.30, 0.26, 1.1, Vector3(0, 0.65, 0), sand.lightened(0.12))
			box(root, Vector3(0.8, 0.18, 0.8), Vector3(0, 1.24, 0), sand)
			box(root, Vector3(0.62, 0.09, 0.62), Vector3(0, 0.95, 0), Color("458e89"))
		"tree":
			var tree_variant := posmod(variant,5)
			root.set_meta("tree_variant",tree_variant)
			var height: float = [1.9,1.75,2.05,1.82,1.97][tree_variant]
			var leaves: int = [7,6,8,5,7][tree_variant]
			var trunk := textured(cylinder(root, 0.18, 0.11, height, Vector3(0, height/2, 0), Color.WHITE, 6), "bark@%d" % tree_variant)
			trunk.rotation.z = [-0.06,0.04,0.0,0.08,-0.03][tree_variant]
			for i in range(leaves):
				var leaf := piece(root, palm_leaf_mesh(), Vector3(-0.05, height-0.04, 0), Color.WHITE)
				leaf.material_override = retro_mat(("violet_leaf" if theme_name == "swamp" else "leaf") + "@%d" % tree_variant)
				leaf.rotation.y = i * TAU / leaves + tree_variant * 0.43
				leaf.rotation.x = -0.12 if i % 2 == 0 else 0.12
		"mushroom":
			for i in range(2):
				var offset := Vector3(i * 0.4 - 0.2, 0, i * 0.25)
				cylinder(root, 0.07, 0.05, 0.45, offset + Vector3(0, 0.22, 0), Color("e5d8b5"))
				var cap := orb(root, Vector3(0.5, 0.23, 0.5), offset + Vector3(0, 0.46, 0), Color("dd91c9"))
				cap.material_override = mat(Color("b4e9b2"), 0.3)
		"emitter":
			box(root, Vector3(0.85, 0.45, 0.85), Vector3(0, 0.22, 0), sand.darkened(0.25))
			box(root, Vector3(0.6, 0.65, 0.6), Vector3(0, 0.7, 0), sand)
			cylinder(root, 0.14, 0.14, 0.5, Vector3(0, 0.45, -0.5), Color("384943")).rotation.x = PI / 2
			box(root, Vector3(0.38, 0.10, 0.06), Vector3(0, 0.9, -0.32), Color("ed8959"))
		"decoration":
			cylinder(root, 0.3, 0.16, 0.5, Vector3(0, 0.25, 0), Color("6ca99b"))
			cylinder(root, 0.18, 0.22, 0.1, Vector3(0, 0.52, 0), Color("ead391"))
	return root

static func spike_ball() -> Node3D:
	var root := Node3D.new()
	root.name = "SpikeBall"
	orb(root,Vector3(0.8,0.8,0.8),Vector3(0,0.46,0),Color("55596b"))
	cylinder(root,0.39,0.39,0.10,Vector3(0,0.47,0),Color("b8874d"),10)
	for i in range(8):
		var dir := Vector3(sin(i*TAU/8),0,cos(i*TAU/8))
		var spike := cylinder(root,0.13,0,0.36,Vector3(0,0.46,0)+dir*0.45,Color("d8cfad"),4)
		spike.quaternion = Quaternion(Vector3.UP,dir)
	cylinder(root,0.14,0,0.35,Vector3(0,0.96,0),Color("d8cfad"),4)
	return root

static func palm_leaf_mesh() -> ArrayMesh:
	if meshes.has("palm_leaf"):
		return meshes["palm_leaf"]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := [Vector3(0, 0, 0), Vector3(-0.34, 0.05, 0.8), Vector3(0, 0.20, 0.75), Vector3(0.34, 0.05, 0.8), Vector3(0, -0.45, 1.65)]
	var uv := [Vector2(0.5, 0), Vector2(0, 0.5), Vector2(0.5, 0.5), Vector2(1, 0.5), Vector2(0.5, 1)]
	for index in [0, 2, 1, 0, 3, 2, 1, 2, 4, 2, 3, 4]:
		tool.set_uv(uv[index])
		tool.add_vertex(points[index])
	tool.generate_normals()
	var mesh := tool.commit()
	meshes["palm_leaf"] = mesh
	return mesh

static func exit_gate() -> Node3D:
	var root := Node3D.new()
	for side in [-1, 1]:
		box(root, Vector3(0.16, 1.25, 0.2), Vector3(side * 0.55, 0.625, 0), Color("edcf73"))
	box(root, Vector3(1.3, 0.18, 0.3), Vector3(0, 1.3, 0), Color("edcf73"))
	var portal := box(root, Vector3(0.8, 0.025, 1.0), Vector3(0, 0.04, 0), Color("99dfb6"))
	portal.material_override = mat(Color("99dfb6"), 0.4)
	var label := Label3D.new()
	label.text = "EXIT"
	label.font_size = 44
	label.pixel_size = 0.006
	label.position = Vector3(0, 1.67, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	root.add_child(label)
	return root
