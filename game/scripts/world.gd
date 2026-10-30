extends Node3D
signal finished(reason: String)
signal checkpoint_reached(point: Array)
signal hop_started(big: bool)
signal hop_landed(big: bool)
var hop_pose_style := "smooth"
signal hint_changed(text: String)
const TileRules = preload("res://scripts/tile_rules.gd")
const Art = preload("res://scripts/art.gd")
const Actor = preload("res://scripts/actor.gd")
const SpikeBalls = preload("res://scripts/spike_balls.gd")
const Crossing = preload("res://scripts/crossing.gd")
const LaneTunnels = preload("res://scripts/lane_tunnels.gd")
const City = preload("res://scripts/nyc_art.gd")
const Streets = preload("res://scripts/city_streets.gd")
const Traffic = preload("res://scripts/traffic.gd")
const Props = preload("res://scripts/streetlife_specs.gd")
const Streetlife = preload("res://scripts/nyc_streetlife_art.gd")
const Roach = preload("res://scripts/roach.gd")
const Skater = preload("res://scripts/skater.gd")
const CityJourney = preload("res://scripts/city_journey.gd")
const ParkHazards = preload("res://scripts/park_hazards.gd")
var traffic: Node3D
var journey: Node3D
var park_hazards: Node3D
var brake_input := false
var grind_input := false
var skaters: Array = []
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
var death_cause := ""
var result_time := 0.0
var touch_mode := false
var camera_target := Vector3.ZERO
var map_view := false
var ocean_material: Material
var intro_active := false
var intro_time := 0.0
const INTRO_DURATION = 4.2
var tile_rules: RefCounted
var long_hop_input := false
var simulation_time := 0.0
var last_hint := ""
var spikes: Node3D
var crossing: Node3D
var lane_tunnel_plans: Array = []
const Landmarks = preload("res://scripts/landmarks.gd")
var landmarks: Node3D
var background_view = false
const Backdrops = preload("res://scripts/backdrops.gd")
var backdrops: Node3D
var claimed_checkpoints: Array = []
var checkpoint_flags: Array = []
var hop_pickups: Array = []

func _ready() -> void:
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	if Art.compatibility_mode:
		settings.background_mode = Environment.BG_COLOR
		settings.background_color = Color("14243a")
	else:
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
	if not Art.compatibility_mode:
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

func load_level(data: Dictionary, edit: bool = false, hat: Variant = "pharaoh", skin: String = "green") -> void:
	active = false
	hop_pickups.clear()
	tile_rules = null
	simulation_time = 0.0
	last_hint = ""
	intro_active = false
	intro_time = 0
	if is_instance_valid(geometry):
		remove_child(geometry)
		geometry.queue_free()
	geometry = Node3D.new()
	add_child(geometry)
	level = data.duplicate(true)
	editing = edit
	map_view = false
	result = ""
	death_cause = ""
	result_time = 0
	halted = false
	elapsed = 0
	input_vector = Vector2.ZERO
	brake_input = false
	grind_input = false
	long_hop_input = false
	journey = null
	park_hazards = null
	claimed_checkpoints.clear()
	checkpoint_flags.clear()
	critters.clear()
	skaters.clear()
	emitters.clear()
	projectiles.clear()
	effects.clear()
	var city: bool = level.theme == "nyc"
	var road_rows: Array = []
	for lane in level.get("traffic", []): road_rows.append(int(lane.row))
	var swamp: bool = level.theme == "swamp"
	var courtyard: bool = level.theme == "mexico"
	var jungle: bool = level.theme == "honduras"
	lane_tunnel_plans = LaneTunnels.plan(level,CELL)
	Art.set_retro(not edit, swamp)
	var floor_color := Color("63744a") if swamp else Color("d7bc7f")
	var wall_color := Color("716582") if swamp else Color("ba9662")
	if courtyard or jungle:
		floor_color = Color.WHITE
		wall_color = Color.WHITE
	var wall_texture := "swamp_stone_wall" if swamp else "brick"
	var cap_texture := "swamp_stone_wall" if swamp else "stone_wall"
	if courtyard:
		wall_texture = "stucco_wall"
		cap_texture = "terracotta_wall"
	elif jungle:
		wall_texture = "jungle_stone_wall"
		cap_texture = "jungle_stone_wall"
	var underlay := Art.box(geometry, Vector3(level.width * CELL + 70, 0.12, level.height * CELL + 70), Vector3(0, -0.48, 0), Color.WHITE)
	ocean_material = Art.retro_mat("swamp_water" if swamp else "water").duplicate()
	if ocean_material is ShaderMaterial:
		ocean_material.set_shader_parameter("uv_tiling", Vector2(40, 40))
	elif ocean_material is StandardMaterial3D:
		ocean_material.uv1_scale = Vector3(40, 40, 1)
	underlay.material_override = ocean_material
	if city:
		floor_color = Color.WHITE
		wall_color = Color("785651")
	for z in range(int(level.height)):
		for x in range(int(level.width)):
			var p := cell_position([x, z])
			var tile: String = level.tiles[z][x]
			var paint_value: Variant = level.get("tile_colors", {}).get("%d,%d" % [x,z], "")
			var painted: bool = paint_value is String and Color.html_is_valid(paint_value)
			var paint_color: Color = Color.from_string(paint_value, Color.WHITE) if painted else Color.WHITE
			var tunnel_terrain := LaneTunnels.border_terrain(lane_tunnel_plans,x,z,int(level.width))
			var tint: float = 0.025 * ((x * 3 + z * 7) % 4)
			if tile == "water" or tunnel_terrain == "water":
				Art.textured(Art.box(geometry, Vector3(CELL, 0.15, CELL), p + Vector3(0, -0.19, 0), Color.WHITE), "swamp_water" if swamp else "water")
				if (x + z) % 3 == 0:
					Art.cylinder(geometry, 0.18, 0.18, 0.025, p + Vector3(0.2, -0.10, 0.2), Color("7eab80"))
			else:
				var color := floor_color.lightened(tint)
				if tile == "path":
					color = Color("b4ad8c") if swamp else Color("ead69b")
				var texture_kind := "road" if tile == "road" else (("swamp_stone" if swamp else "stone") if tile == "path" else ("moss" if swamp else "grass"))
				if courtyard and tile != "road":
					texture_kind = "plaza" if tile == "path" else "terracotta"
					color = Color.WHITE
				elif jungle and tile != "road":
					texture_kind = "jungle_stone" if tile == "path" else "jungle_ground"
					color = Color.WHITE
				if city:
					texture_kind = "asphalt" if tile == "road" else ("city_pavers" if tile == "path" else "concrete")
					color = Color.WHITE
					if tile == "floor":
						for park in level.get("city_journey",{}).get("parks",[]):
							var bounds: Array = park.rect
							if x >= bounds[0] and x <= bounds[2] and z >= bounds[1] and z <= bounds[3]: texture_kind = "grass"
				if tunnel_terrain == "road":
					texture_kind = "road"
					color = Color.WHITE
				Art.textured(Art.box(geometry, Vector3(CELL, 0.2, CELL), p + Vector3(0, -0.1, 0), color), texture_kind, paint_color if painted and tile in ["floor", "path"] else Color.WHITE)
			if city:
				var crosswalk: bool = x in level.get("crossings", [])
				if tile == "road": Streets.road(geometry,p,x,crosswalk)
				elif tile not in ["wall","water"]:
					for side in [-1,1]:
						if z+side >= 0 and z+side < level.height and level.tiles[z+side][x] == "road": Streets.sidewalk_edge(geometry,p,side,crosswalk)
			if tile == "cheese_wall":
				Art.textured(Art.box(geometry, Vector3(CELL, 0.65, CELL), p + Vector3(0, 0.325, 0), Color.WHITE), "cheese", paint_color if painted else Color.WHITE)
				var cheese_body := Art.solid(geometry, Vector3(CELL, 1.4, CELL), p + Vector3(0, 0.5, 0))
				cheese_body.collision_layer = 8
			if tile == "wall":
				var perimeter: bool = x == 0 or z == 0 or x == level.width - 1
				var height := 1.45 if perimeter else (0.3 if z == level.height - 1 else 0.55)
				if city and z in road_rows and x in [0,level.width-1]: height = 0.025
				if tunnel_terrain.is_empty():
					Art.textured(Art.box(geometry, Vector3(CELL, height, CELL), p + Vector3(0, height / 2, 0), wall_color), wall_texture, paint_color if painted else Color.WHITE)
					Art.textured(Art.box(geometry, Vector3(CELL + 0.025, 0.10, CELL + 0.025), p + Vector3(0, height, 0), wall_color.lightened(0.2)), cap_texture, paint_color if painted else Color.WHITE)
				Art.solid(geometry, Vector3(CELL, 1.4, CELL), p + Vector3(0, 0.5, 0))
	if city:
		City.district(geometry,int(level.width),int(level.height),CELL)
		Streets.signs(geometry,level)
	LaneTunnels.build(geometry,lane_tunnel_plans,level.theme)
	# Invisible boundary colliders prevent a painted-out perimeter from escaping the map.
	var w: float = level.width * CELL
	var h: float = level.height * CELL
	for side in [-1, 1]:
		Art.solid(geometry, Vector3(w + 2, 2, 0.2), Vector3(0, 0.5, side * (h / 2 + 0.1)))
		Art.solid(geometry, Vector3(0.2, 2, h + 2), Vector3(side * (w / 2 + 0.1), 0.5, 0))
	for obj in level.objects:
		var p := cell_position(obj.pos)
		if obj.type in ["hop_fragment", "hop_seed"]:
			var pickup := Node3D.new()
			pickup.name = str(obj.id)
			pickup.position = p
			geometry.add_child(pickup)
			var fragment: bool = obj.type == "hop_fragment"
			var color := Color("f9bc65") if fragment else Color("8de8ed")
			Art.cylinder(pickup, 0.48, 0.48, 0.04, Vector3(0,0.03,0), Color("755938") if fragment else Color("326979"))
			for side in ([1] if fragment else [1,-1]):
				var jewel := MeshInstance3D.new()
				var mesh := CylinderMesh.new()
				mesh.top_radius = 0
				mesh.bottom_radius = 0.34 if fragment else 0.4
				mesh.height = 0.65 if fragment else 0.46
				mesh.radial_segments = 3 if fragment else 4
				jewel.mesh = mesh
				jewel.material_override = Art.mat(color)
				jewel.position.y = 0.65 if fragment else 0.85 + side * 0.23
				if side == -1: jewel.rotation.z = PI
				jewel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				pickup.add_child(jewel)
			hop_pickups.append({"obj":obj,"node":pickup})
			continue
		if obj.type in ["car", "patrol_car", "log", "spike_ball", "landmark", "backdrop"]:
			continue
		if obj.type == "skater":
			var rider := Skater.new()
			geometry.add_child(rider)
			rider.setup(obj,self)
			skaters.append(rider)
			continue
		if obj.type in ["critter","roach"]:
			var actor = Roach.new() if obj.type == "roach" else Actor.new()
			actor.setup(false, level.theme, obj)
			actor.position = p
			if level.get("game_mode", "hopan") == "tile": actor.visual.scale = Vector3.ONE * 1.25
			if obj.get("behavior") == "seam_patrol":
				actor.visual.rotation.y = deg_to_rad(float(obj.get("rotation", 0)))
			geometry.add_child(actor)
			for point in obj.get("waypoints", []):
				actor.waypoints.append(cell_position(point))
			critters.append(actor)
		else:
			var model := Streetlife.prop(obj.variant) if obj.type == "city_prop" else (City.scenery(obj.type) if city else Art.scenery(obj.type, level.theme, posmod(hash(obj.pos),5)))
			if obj.type == "city_prop" and obj.variant in ["skate_ramp","skate_rail"]:
				model.scale.z = float(obj.get("length",4.0))/4.0
				if obj.variant == "skate_ramp": model.scale.y = float(obj.get("rise",0.7))/0.7
			model.position = p
			model.rotation.y = deg_to_rad(float(obj.get("rotation", 0)))
			geometry.add_child(model)
			if obj.type in ["pillar", "tree", "emitter"] or obj.get("solid", false):
				var width := 0.55 if obj.type == "tree" else 0.85
				if obj.type == "city_prop":
					var size: Vector2 = Props.footprint(obj)
					var proxy := Art.solid(geometry,Vector3(size.x,1.2,size.y),p+Vector3(0,0.5,0))
					proxy.rotation.y = model.rotation.y
				else: Art.solid(geometry, Vector3(width, 1.2, width), p + Vector3(0, 0.5, 0))
			if obj.type == "emitter":
				var dir := Vector3(0, 0, -1).rotated(Vector3.UP, model.rotation.y)
				emitters.append({"pos": p + Vector3(0, 0.42, 0) + dir * 0.72, "dir": dir, "clock": 0.5, "interval": float(obj.get("interval", 2.5)), "model": model})
	var checkpoint_points: Array = level.get("checkpoints", []).duplicate(true)
	if level.has("checkpoint"):
		checkpoint_points.append(level.checkpoint)
	for point in checkpoint_points:
		var marker := Node3D.new()
		marker.name = "Checkpoint"
		marker.position = cell_position(point)
		geometry.add_child(marker)
		Art.cylinder(marker, 0.55, 0.55, 0.03, Vector3(0,0.025,0), Color("64c9e8"))
		Art.box(marker, Vector3(0.06,0.9,0.06), Vector3(0,0.45,0), Color("eee4c1"))
		var flag := Art.box(marker, Vector3(0.48,0.3,0.06), Vector3(0.24,0.75,0), Color("64c9e8"))
		checkpoint_flags.append({"point":point.duplicate(), "flag":flag})
	traffic = Traffic.new()
	geometry.add_child(traffic)
	traffic.setup(level)
	crossing = Crossing.new()
	geometry.add_child(crossing)
	crossing.setup(level, self)
	spikes = SpikeBalls.new()
	geometry.add_child(spikes)
	spikes.setup(level,self)
	landmarks = Landmarks.new()
	geometry.add_child(landmarks)
	landmarks.setup(level, self)
	backdrops = Backdrops.new()
	geometry.add_child(backdrops)
	backdrops.setup(level,self)
	player = Actor.new()
	player.setup(true, level.theme, {}, true)
	player.set_hat(hat)
	player.set_skin(skin)
	player.visual.scale = Vector3.ONE * (1.5 if level.get("game_mode", "hopan") == "tile" else 1.12)
	player.position = cell_position(level.spawn)
	geometry.add_child(player)
	if not level.get("city_journey", {}).is_empty():
		journey = CityJourney.new()
		geometry.add_child(journey)
		journey.setup(level, self)
	if not level.get("park_encounters", []).is_empty():
		park_hazards = ParkHazards.new()
		geometry.add_child(park_hazards)
		park_hazards.setup(level, self)
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
	underlay.name = "HorizonOcean"
	var excluded: Array = [player, cursor, gate, route_root, crossing, spikes, landmarks, backdrops, underlay, traffic] + critters + skaters
	if is_instance_valid(journey): excluded.append(journey)
	if is_instance_valid(park_hazards): excluded.append(park_hazards)
	for pickup in hop_pickups: excluded.append(pickup.node)
	for emitter in emitters:
		excluded.append(emitter.model)
	for marker in checkpoint_flags:
		excluded.append(marker.flag) # Activation changes its color during play.
	Art.batch_static(geometry, excluded, CELL * 6 if maxi(level.width,level.height) > 25 else 0.0)
	if level.get("game_mode", "hopan") == "tile":
		tile_rules = TileRules.new(self)
		for emitter in emitters: emitter.clock = ceilf(emitter.interval)
	Art.set_simulation_time(0,level.get("move_with_me",false))
	fit_camera()
	active = not edit

var editor_zoom:float=1.0
var editor_pan:=Vector3.ZERO

func pan_editor(delta:Vector2)->void:
	if not editing:return
	var center:=get_viewport().get_visible_rect().size*.5
	var plane:=Plane(Vector3.UP,0)
	var a:Variant=plane.intersects_ray(camera.project_ray_origin(center),camera.project_ray_normal(center))
	var b:Variant=plane.intersects_ray(camera.project_ray_origin(center+delta),camera.project_ray_normal(center+delta))
	if a!=null and b!=null:
		editor_pan+=a-b
		fit_camera()


func fit_camera() -> void:
	if level.is_empty() or not is_instance_valid(camera):
		return
	if editing or map_view:
		camera.far = maxf(200, maxf(level.width,level.height) * CELL * 3)
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		var size := get_viewport().get_visible_rect().size
		var aspect := size.x / maxf(1, size.y)
		camera.size = maxf(level.height * CELL * 0.86 + 2.8, (level.width * CELL + 2.5) / maxf(aspect, 0.1))
		if editing and background_view: camera.size = maxf((level.height+32) * CELL * 0.86+2.8, ((level.width+32)*CELL+2.5)/maxf(aspect,0.1))
		if editing:camera.size *= editor_zoom
		camera_target = editor_pan if editing else Vector3.ZERO
	else:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = 63 if touch_mode else 58
		if is_instance_valid(backdrops) and not backdrops.entries.is_empty():
			camera.fov = 70 if touch_mode else 66
		camera.near = 0.15
		camera.far = maxf(float(level.get("draw_distance",18)) * CELL + 12, backdrops.far_limit() if is_instance_valid(backdrops) else 0)
		camera_target = player.position + Vector3(0, 0.25, -2.0)
	update_draw_range()
	update_camera(1.0)
	if is_instance_valid(landmarks): landmarks.update_lod()
	if is_instance_valid(backdrops): backdrops.configure_view()

func update_draw_range() -> void:
	var limit := 0.0 if editing or map_view else float(level.get("draw_distance",18)) * CELL
	Art.set_draw_distance(limit)
	for mesh in geometry.find_children("*", "GeometryInstance3D", true, false):
		if mesh.name != "HorizonOcean" and (not is_instance_valid(landmarks) or not landmarks.is_ancestor_of(mesh)) and (not is_instance_valid(backdrops) or not backdrops.is_ancestor_of(mesh)):
			mesh.visibility_range_end = limit
			mesh.visibility_range_end_margin = CELL

func update_camera(weight: float) -> void:
	if intro_active:
		preview_camera()
		return
	if not editing and not map_view and is_instance_valid(player):
		var lead := Vector3(0, 0.25, -2.0)
		var offset := Vector3(0,4.6,8.0)
		if is_instance_valid(journey):
			# More overhead coverage and forward lead make the southbound return leg
			# readable without reversing controls or abruptly rotating the camera.
			lead = Vector3(journey.facing.x*2.8,0.25,journey.facing.z*2.8)
			offset = Vector3(0,10.5,8.0)
		camera_target = camera_target.lerp(player.position + lead, weight)
		camera.position = camera_target + offset
	else:
		camera.position = camera_target + Vector3(0, 30, 22)
	camera.look_at(camera_target + landmark_focus_offset())

func landmark_focus_offset() -> Vector3:
	# Keep the existing camera position and follower. Scenery levels need a little
	# more sky above the walking route so tall silhouettes can enter the frame.
	if not editing and not map_view and is_instance_valid(backdrops) and not backdrops.entries.is_empty(): return Vector3(0,2.7,0)
	return Vector3(0,1.7,0) if not editing and not map_view and is_instance_valid(landmarks) and not landmarks.entries.is_empty() else Vector3.ZERO

func begin_exit_preview() -> void:
	if editing or not active:
		return
	intro_time = 0
	intro_active = true
	preview_camera()

func cancel_exit_preview() -> void:
	if not intro_active:
		return
	intro_active = false
	input_vector = Vector2.ZERO
	fit_camera()

func preview_camera() -> void:
	var home := player.position + Vector3(0, 0.25, -2.0)
	var goal := cell_position(level.exit) + Vector3(0, 0.25, 0)
	var blend := 0.0
	if intro_time < 1.7:
		blend = smoothstep(0.0, 1.7, intro_time)
	elif intro_time < 2.5:
		blend = 1.0
	else:
		blend = 1.0 - smoothstep(2.5, INTRO_DURATION, intro_time)
	camera_target = home.lerp(goal, blend)
	var lift := sin(clampf(intro_time / INTRO_DURATION, 0, 1) * PI)
	camera.position = camera_target + Vector3(0, 4.6 + lift * 5.0, 8.0 + lift * 3.0)
	camera.look_at(camera_target + landmark_focus_offset() * (1.0-blend))

func set_map_view(enabled: bool) -> void:
	if intro_active:
		cancel_exit_preview()
	map_view = enabled and not editing
	Art.set_retro(not editing and not map_view, level.theme == "swamp")
	if ocean_material is ShaderMaterial:
		ocean_material.set_shader_parameter("retro_amount", 0.0 if map_view else 1.0)
	fit_camera()

func pick(screen_pos: Vector2) -> Vector2i:
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	var hit: Variant = Plane(Vector3.UP, 0).intersects_ray(from, dir)
	return position_cell(hit) if hit != null else Vector2i(-1, -1)

func show_cursor(cell: Vector2i, backdrop: bool = false) -> void:
	if is_instance_valid(cursor):
		cursor.visible = editing and (inside(cell) or (backdrop and cell.x >= -16 and cell.y >= -16 and cell.x < level.width+16 and cell.y < level.height+16))
		if cursor.visible:
			cursor.position = cell_position([cell.x, cell.y]) + Vector3(0, 0.72 if inside(cell) and level.tiles[cell.y][cell.x] in ["wall", "cheese_wall"] else 0.07, 0)

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
			show_route_segment(points[i - 1], points[i])
	# Close the actual loop without adding a duplicate numbered waypoint.
	if obj.get("patrol_loop", true) and obj.get("waypoints", []).size() > 1:
		show_route_segment(obj.waypoints[-1], obj.waypoints[0])

func show_route_segment(a: Array, b: Array) -> void:
	var from := cell_position(a) + Vector3(0, 0.12, 0)
	var to := cell_position(b) + Vector3(0, 0.12, 0)
	if from.distance_to(to) > 0.01:
		var line := Art.box(route_root, Vector3(0.055, 0.035, from.distance_to(to)), (from + to) / 2, Color("f4df8d"))
		line.look_at(to)

func _physics_process(delta: float) -> void:
	if is_instance_valid(player):
		player.idle_dance(delta,not (is_instance_valid(journey) and journey.is_skating()) and active and not halted and not map_view and not intro_active and result.is_empty() and not editing and input_vector.length_squared()<.001 and not long_hop_input and (tile_rules==null or not tile_rules.jumping))
	if halted or map_view:
		return
	if intro_active:
		intro_time += delta
		if intro_time >= INTRO_DURATION:
			cancel_exit_preview()
		else:
			preview_camera()
		return
	if not result.is_empty():
		result_time += delta
		if result == "SPLASHED!":
			player.visual.position.y = -minf(result_time * 0.8, 1.4)
		elif result != "LEVEL COMPLETE!":
			player.visual.rotation.z = lerpf(player.visual.rotation.z, PI / 2, minf(1.0, delta * 8))
			player.visual.position.y = sin(minf(result_time / 0.65, 1.0) * PI) * 0.4
		else:
			player.visual.rotation.y += delta * 3
			player.visual.position.y = absf(sin(result_time * 7)) * 0.3
		animate_effects(delta)
		return
	if not active or editing:
		return
	update_level_hint()
	if tile_rules != null:
		tile_rules.advance(delta, input_vector, long_hop_input)
		Art.set_simulation_time(elapsed, level.get("move_with_me",false))
		update_camera(minf(1,delta*10))
		return
	var previous_player := player.position
	if level.get("move_with_me",false):
		player.step(delta,input_vector)
		update_camera(minf(1,delta*8))
		if previous_player.distance_to(player.position) < 0.00001:
			return
		crossing.advance(delta,player)
	else:
		crossing.advance(delta, player)
		if is_instance_valid(journey): journey.step(delta,input_vector,long_hop_input,brake_input,grind_input)
		else: player.step(delta, input_vector)
		update_camera(minf(1, delta * 8))
	traffic.step(delta)
	if traffic.hits_player(previous_player,player.position):
		finish("SQUISHED!")
		return
	if is_instance_valid(park_hazards):
		park_hazards.step(delta)
		var park_hit: String = park_hazards.hits_player(previous_player,player.position)
		if not park_hit.is_empty():
			finish(park_hit)
			return
	for rider in skaters:
		rider.step(delta)
		if rider.hits_player(previous_player,player.position):
			finish("SKATED OVER!")
			return
	spikes.advance(delta,previous_player,player.position,false)
	if not result.is_empty(): return
	elapsed += delta
	Art.set_simulation_time(elapsed, level.get("move_with_me",false))
	var tile := position_cell(player.position)
	if not inside(tile) or (level.tiles[tile.y][tile.x] == "water" and crossing.log_at(player.position).is_empty()):
		finish("SPLASHED!")
		return
	if crossing.traffic_hit(previous_player, player.position):
		finish("SQUISHED!")
		return
	if level.has("checkpoint") and not crossing.checkpoint_claimed and tile.y <= int(level.checkpoint[1]) and level.tiles[tile.y][tile.x] not in ["water", "road"]:
		crossing.checkpoint_claimed = true
		claim_checkpoint(level.checkpoint)
	for point in level.get("checkpoints", []):
		if tile == Vector2i(point[0], point[1]) and point not in claimed_checkpoints:
			claim_checkpoint(point)
	for critter in critters:
		var old: Vector3 = critter.position
		critter.step(delta)
		var cell := position_cell(critter.position)
		if not inside(cell) or level.tiles[cell.y][cell.x] == "water":
			critter.position = old
			critter.direction = -critter.direction
			if critter.behavior in ["patrol", "seam_patrol"]:
				critter.advance_waypoint()
		if player.position.distance_to(critter.position) < 0.67:
			death_cause = critter.behavior
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

func update_level_hint() -> void:
	var closest := CELL * 3.5
	var text := ""
	for entry in level.get("signs",[]):
		var distance := player.position.distance_to(cell_position(entry.pos))
		if distance < closest:
			closest = distance
			text = entry.text.replace("\n", " · ")
	if is_instance_valid(park_hazards):
		var warning: String = park_hazards.get_hint()
		if not warning.is_empty(): text = warning
	if not text.is_empty() and text != last_hint:
		last_hint = text
		hint_changed.emit(text)

func restore_checkpoints(points: Array) -> void:
	claimed_checkpoints = points.duplicate(true)
	for marker in checkpoint_flags:
		marker.flag.material_override = Art.mat(Color("d5ec8d") if marker.point in claimed_checkpoints else Color("64c9e8"))

func claim_checkpoint(point: Array) -> void:
	if point in claimed_checkpoints:
		return
	claimed_checkpoints.append(point.duplicate())
	restore_checkpoints(claimed_checkpoints)
	checkpoint_reached.emit(point.duplicate())

func spawn_projectile(pos: Vector3, dir: Vector3) -> void:
	var node := Art.orb(geometry, Vector3(0.22, 0.22, 0.4), pos, Color("f5a559"))
	node.material_override = Art.mat(Color("f5a559"), 0.7)
	node.visibility_range_end = 0 if editing or map_view else float(level.get("draw_distance",18)) * CELL
	projectiles.append({"node": node, "dir": dir, "life": 7.0})

func finish(reason: String) -> void:
	if not result.is_empty():
		return
	intro_active = false
	if tile_rules != null: player.reset_tile_pose()
	result = reason
	result_time = 0
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
