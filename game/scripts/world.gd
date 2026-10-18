extends Node3D
signal finished(reason: String)
signal checkpoint_reached(point: Array)
const Art = preload("res://scripts/art.gd")
const Actor = preload("res://scripts/actor.gd")
const Crossing = preload("res://scripts/crossing.gd")
const CELL = 1.8
var level: Dictionary = {}
var geometry: Node3D
var player: CharacterBody3D
var critters: Array = []
var emitters: Array = []
var projectiles: Array = []
var effects: Array = []
var camera: Camera3D
var active := false
var editing := false
var halted := false
var elapsed := 0.0
var input_vector := Vector2.ZERO
var cursor: MeshInstance3D
var route_root: Node3D
var result := ""
var result_time := 0.0
var touch_mode := false
var camera_target := Vector3.ZERO
var map_view := false
var ocean_material: ShaderMaterial
var crossing: Node3D

func _ready() -> void:
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ShaderMaterial.new()
	sky_material.shader = preload("res://shaders/night_sky.gdshader")
	sky.sky_material = sky_material
	settings.sky = sky
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("cad4ed")
	settings.ambient_light_energy = 0.55
	settings.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.environment = settings
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_color = Color("eadba8")
	sun.light_energy = 0.8
	# Short maze walls and ambient fill preserve readability on mobile. Avoid the
	# four-cascade shadow pass on each tiny modular mesh in the WebGL build.
	sun.shadow_enabled = false
	sun.directional_shadow_max_distance = 65
	add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	add_child(camera)

func cell_position(p: Array) -> Vector3:
	return Vector3((float(p[0]) - (level.width - 1) * 0.5) * CELL, 0, (float(p[1]) - (level.height - 1) * 0.5) * CELL)

func position_cell(p: Vector3) -> Vector2i:
	return Vector2i(roundi(p.x / CELL + (level.width - 1) * 0.5), roundi(p.z / CELL + (level.height - 1) * 0.5))

func inside(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < level.width and p.y < level.height

func load_level(data: Dictionary, edit: bool = false, hat: Variant = "pharaoh") -> void:
	active = false
	if is_instance_valid(geometry):
		remove_child(geometry)
		geometry.queue_free()
	geometry = Node3D.new()
	add_child(geometry)
	level = data.duplicate(true)
	editing = edit
	map_view = false
	result = ""
	result_time = 0
	halted = false
	elapsed = 0
	input_vector = Vector2.ZERO
	critters.clear()
	emitters.clear()
	projectiles.clear()
	effects.clear()
	var swamp: bool = level.theme == "swamp"
	Art.set_retro(not edit, swamp)
	var floor_color := Color("63744a") if swamp else Color("d7bc7f")
	var wall_color := Color("716582") if swamp else Color("ba9662")
	var underlay := Art.box(geometry, Vector3(level.width * CELL + 70, 0.12, level.height * CELL + 70), Vector3(0, -0.48, 0), Color.WHITE)
	ocean_material = Art.retro_mat("swamp_water" if swamp else "water").duplicate() as ShaderMaterial
	ocean_material.set_shader_parameter("uv_tiling", Vector2(40, 40))
	underlay.material_override = ocean_material
	for z in range(int(level.height)):
		for x in range(int(level.width)):
			var p := cell_position([x, z])
			var tile: String = level.tiles[z][x]
			var tint: float = 0.025 * ((x * 3 + z * 7) % 4)
			if tile == "water":
				Art.textured(Art.box(geometry, Vector3(CELL, 0.15, CELL), p + Vector3(0, -0.19, 0), Color.WHITE), "swamp_water" if swamp else "water")
				if (x + z) % 3 == 0:
					Art.cylinder(geometry, 0.18, 0.18, 0.025, p + Vector3(0.2, -0.10, 0.2), Color("7eab80"))
			else:
				var color := floor_color.lightened(tint)
				if tile == "path":
					color = Color("b4ad8c") if swamp else Color("ead69b")
				var texture_kind := "road" if tile == "road" else (("swamp_stone" if swamp else "stone") if tile == "path" else ("moss" if swamp else "grass"))
				Art.textured(Art.box(geometry, Vector3(CELL, 0.2, CELL), p + Vector3(0, -0.1, 0), color), texture_kind)
			if tile == "wall":
				var perimeter: bool = x == 0 or z == 0 or x == level.width - 1
				var height := 1.45 if perimeter else (0.3 if z == level.height - 1 else 0.55)
				Art.textured(Art.box(geometry, Vector3(CELL, height, CELL), p + Vector3(0, height / 2, 0), wall_color), "swamp_stone" if swamp else "brick")
				Art.textured(Art.box(geometry, Vector3(CELL + 0.025, 0.10, CELL + 0.025), p + Vector3(0, height, 0), wall_color.lightened(0.2)), "swamp_stone" if swamp else "stone")
				Art.solid(geometry, Vector3(CELL, 1.4, CELL), p + Vector3(0, 0.5, 0))
	# Invisible boundary colliders prevent a painted-out perimeter from escaping the map.
	var w: float = level.width * CELL
	var h: float = level.height * CELL
	for side in [-1, 1]:
		Art.solid(geometry, Vector3(w + 2, 2, 0.2), Vector3(0, 0.5, side * (h / 2 + 0.1)))
		Art.solid(geometry, Vector3(0.2, 2, h + 2), Vector3(side * (w / 2 + 0.1), 0.5, 0))
	for obj in level.objects:
		var p := cell_position(obj.pos)
		if obj.type in ["car", "log"]:
			continue
		if obj.type == "critter":
			var actor := Actor.new()
			actor.setup(false, level.theme, obj)
			actor.position = p
			geometry.add_child(actor)
			for point in obj.get("waypoints", []):
				actor.waypoints.append(cell_position(point))
			critters.append(actor)
		else:
			var model := Art.scenery(obj.type, level.theme)
			model.position = p
			model.rotation.y = deg_to_rad(float(obj.get("rotation", 0)))
			geometry.add_child(model)
			if obj.type in ["pillar", "tree", "emitter"] or obj.get("solid", false):
				var width := 0.55 if obj.type == "tree" else 0.85
				Art.solid(geometry, Vector3(width, 1.2, width), p + Vector3(0, 0.5, 0))
			if obj.type == "emitter":
				var dir := Vector3(0, 0, -1).rotated(Vector3.UP, model.rotation.y)
				emitters.append({"pos": p + Vector3(0, 0.42, 0) + dir * 0.72, "dir": dir, "clock": 0.5, "interval": float(obj.get("interval", 2.5)), "model": model})
	crossing = Crossing.new()
	geometry.add_child(crossing)
	crossing.setup(level, self)
	player = Actor.new()
	player.setup(true, level.theme, {}, true)
	player.set_hat(hat)
	player.position = cell_position(level.spawn)
	geometry.add_child(player)
	if edit:
		var start := Art.cylinder(geometry, 0.65, 0.65, 0.025, player.position + Vector3(0, 0.015, 0), Color("90b88b"))
		start.name = "StartMarker"
	var gate := Art.exit_gate()
	gate.position = cell_position(level.exit)
	geometry.add_child(gate)
	cursor = Art.box(geometry, Vector3(CELL - 0.04, 0.05, CELL - 0.04), Vector3.ZERO, Color("e5eea0"))
	var cursor_mat := Art.mat(Color(0.85, 1, 0.6, 0.3)).duplicate() as StandardMaterial3D
	cursor_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cursor.material_override = cursor_mat
	cursor.visible = false
	route_root = Node3D.new()
	geometry.add_child(route_root)
	var excluded: Array = [player, cursor, gate, route_root, crossing] + critters
	for emitter in emitters:
		excluded.append(emitter.model)
	Art.batch_static(geometry, excluded)
	fit_camera()
	active = not edit

func fit_camera() -> void:
	if level.is_empty() or not is_instance_valid(camera):
		return
	if editing or map_view:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		var size := get_viewport().get_visible_rect().size
		var aspect := size.x / maxf(1, size.y)
		camera.size = maxf(level.height * CELL * 0.86 + 2.8, (level.width * CELL + 2.5) / maxf(aspect, 0.1))
		camera_target = Vector3.ZERO
	else:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = 63 if touch_mode else 58
		camera.near = 0.15
		camera.far = 90
		camera_target = player.position + Vector3(0, 0.25, -2.5)
	update_camera(1.0)

func update_camera(weight: float) -> void:
	if not editing and not map_view and is_instance_valid(player):
		camera_target = camera_target.lerp(player.position + Vector3(0, 0.25, -2.5), weight)
		camera.position = camera_target + Vector3(0, 5.8, 9.0)
	else:
		camera.position = camera_target + Vector3(0, 30, 22)
	camera.look_at(camera_target)

func set_map_view(enabled: bool) -> void:
	map_view = enabled and not editing
	Art.set_retro(not editing and not map_view, level.theme == "swamp")
	ocean_material.set_shader_parameter("retro_amount", 0.0 if map_view else 1.0)
	fit_camera()

func pick(screen_pos: Vector2) -> Vector2i:
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	var hit: Variant = Plane(Vector3.UP, 0).intersects_ray(from, dir)
	return position_cell(hit) if hit != null else Vector2i(-1, -1)

func show_cursor(cell: Vector2i) -> void:
	if is_instance_valid(cursor):
		cursor.visible = editing and inside(cell)
		if cursor.visible:
			cursor.position = cell_position([cell.x, cell.y]) + Vector3(0, 0.72 if level.tiles[cell.y][cell.x] == "wall" else 0.07, 0)

func show_route(obj: Dictionary) -> void:
	for child in route_root.get_children():
		child.queue_free()
	if obj.is_empty():
		return
	var points: Array = [obj.pos] + obj.get("waypoints", [])
	for i in range(points.size()):
		var p := cell_position(points[i]) + Vector3(0, 0.12, 0)
		Art.cylinder(route_root, 0.14, 0.14, 0.04, p, Color("f4df8d"))
		var label := Label3D.new()
		label.text = "●" if i == 0 else str(i)
		label.position = p + Vector3(0, 0.4, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 48
		label.pixel_size = 0.008
		label.no_depth_test = true
		route_root.add_child(label)
		if i > 0:
			var prev := cell_position(points[i - 1]) + Vector3(0, 0.12, 0)
			var line := Art.box(route_root, Vector3(0.055, 0.035, p.distance_to(prev)), (p + prev) / 2, Color("f4df8d"))
			if p.distance_to(prev) > 0.01:
				line.look_at(p)

func _physics_process(delta: float) -> void:
	if halted or map_view:
		return
	if not result.is_empty():
		result_time += delta
		if result == "SPLASHED!":
			player.visual.position.y -= delta * 0.8
		elif result != "LEVEL COMPLETE!":
			player.visual.rotation.z = lerpf(player.visual.rotation.z, PI / 2, delta * 8)
		else:
			player.visual.rotation.y += delta * 3
			player.visual.position.y = absf(sin(result_time * 7)) * 0.3
		animate_effects(delta)
		return
	if not active or editing:
		return
	elapsed += delta
	var previous_player := player.position
	crossing.advance(delta, player)
	player.step(delta, input_vector)
	update_camera(minf(1, delta * 8))
	var tile := position_cell(player.position)
	if not inside(tile) or (level.tiles[tile.y][tile.x] == "water" and crossing.log_at(player.position).is_empty()):
		finish("SPLASHED!")
		return
	if crossing.traffic_hit(previous_player, player.position):
		finish("SQUISHED!")
		return
	if level.has("checkpoint") and not crossing.checkpoint_claimed and tile.y <= int(level.checkpoint[1]) and level.tiles[tile.y][tile.x] not in ["water", "road"]:
		crossing.checkpoint_claimed = true
		checkpoint_reached.emit(level.checkpoint.duplicate())
	for critter in critters:
		var old: Vector3 = critter.position
		critter.step(delta)
		var cell := position_cell(critter.position)
		if not inside(cell) or level.tiles[cell.y][cell.x] == "water":
			critter.position = old
			critter.direction = -critter.direction
			if critter.behavior == "patrol":
				critter.waypoint_index = (critter.waypoint_index + 1) % maxi(1, critter.waypoints.size())
		if player.position.distance_to(critter.position) < 0.67:
			finish("CROAKED!")
			return
	for emitter in emitters:
		emitter.clock -= delta
		if emitter.clock <= 0:
			emitter.clock += emitter.interval
			spawn_projectile(emitter.pos, emitter.dir)
		# The glowing top warns as the next shot approaches.
		emitter.model.scale.y = 1.0 + 0.05 * maxf(0, 1 - emitter.clock / 0.5)
	for i in range(projectiles.size() - 1, -1, -1):
		var shot: Dictionary = projectiles[i]
		var from: Vector3 = shot.node.position
		var target: Vector3 = from + shot.dir * 7.0 * delta
		var query := PhysicsRayQueryParameters3D.create(from, target, 1)
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			target = hit.position
		var nearest := Geometry3D.get_closest_point_to_segment(player.position + Vector3(0, 0.36, 0), from, target)
		if nearest.distance_to(player.position + Vector3(0, 0.36, 0)) < 0.43:
			finish("HIT!")
			return
		shot.node.position = target
		shot.life -= delta
		if not hit.is_empty() or shot.life <= 0:
			shot.node.queue_free()
			projectiles.remove_at(i)
	if player.position.distance_to(cell_position(level.exit)) < 0.65:
		finish("LEVEL COMPLETE!")

func spawn_projectile(pos: Vector3, dir: Vector3) -> void:
	var node := Art.orb(geometry, Vector3(0.22, 0.22, 0.4), pos, Color("f5a559"))
	node.material_override = Art.mat(Color("f5a559"), 0.7)
	projectiles.append({"node": node, "dir": dir, "life": 7.0})

func finish(reason: String) -> void:
	if not result.is_empty():
		return
	result = reason
	active = false
	var color := Color("9be7d9") if reason == "SPLASHED!" else Color("e9ce77")
	for i in range(14):
		var node := Art.orb(geometry, Vector3.ONE * 0.12, player.position + Vector3(0, 0.3, 0), color)
		var angle := i * TAU / 14
		effects.append({"node": node, "velocity": Vector3(sin(angle) * 1.8, 1.8 + (i % 3) * 0.5, cos(angle) * 1.8)})
	finished.emit(reason)

func animate_effects(delta: float) -> void:
	for effect in effects:
		effect.velocity.y -= delta * 5
		effect.node.position += effect.velocity * delta
		effect.node.scale *= maxf(0, 1 - delta * 0.7)
