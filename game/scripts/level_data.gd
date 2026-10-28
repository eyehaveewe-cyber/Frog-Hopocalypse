extends RefCounted
## The editor, bundled maps and runtime all consume this versioned format.
const Props = preload("res://scripts/streetlife_specs.gd")
const VERSION = 1
const MAX_SIDE = 25
const TILES = ["floor", "wall", "water", "path", "road"]
const CITY_PROPS = ["bench", "trash_can", "dumpster", "pizza_cart", "mailbox", "traffic_cone", "manhole", "newsstand", "skate_rail", "skate_ramp"]
const SKATE_TRICKS = ["cruise", "push", "grind", "ramp"]
const OBJECTS = ["pillar", "tree", "mushroom", "decoration", "critter", "emitter", "roach", "skater", "city_prop"]

static func blank(title: String = "My magnificent maze", theme_name: String = "egypt") -> Dictionary:
	var tiles: Array = []
	for y in range(13):
		var row: Array = []
		for x in range(17):
			row.append("wall" if x == 0 or y == 0 or x == 16 or y == 12 else "floor")
		tiles.append(row)
	return {"version": VERSION, "name": title, "theme": theme_name, "width": 17, "height": 13,
		"tiles": tiles, "spawn": [1, 11], "exit": [15, 1], "objects": []}

static func finite_number(v: Variant) -> bool:
	return (v is int or v is float) and is_finite(float(v))

static func point_valid(p: Variant, w: int, h: int) -> bool:
	return p is Array and p.size() == 2 and finite_number(p[0]) and finite_number(p[1]) and p[0] >= 0 and p[0] < w and p[1] >= 0 and p[1] < h

static func validate(d: Variant) -> String:
	if not d is Dictionary:
		return "Expected a JSON level object."
	if not finite_number(d.get("version")) or float(d.version) != VERSION:
		return "Unsupported map version. This build reads version 1."
	if not d.get("name") is String or d.name.strip_edges().is_empty() or d.name.length() > 80:
		return "Give the level a name of 1–80 characters."
	if d.has("level_set") and not d.level_set is String:
		return "Level set identifiers must be text."
	if d.get("level_set", "") == "nyc_streetlife":
		if not finite_number(d.get("set_index")) or d.set_index != int(d.set_index) or d.set_index < 1 or d.set_index > 6:
			return "NYC Streetlife levels need an index from 1 to 6."
	if d.has("hint") and (not d.hint is String or d.hint.length() > 140):
		return "Level hints must be text up to 140 characters."
	if d.get("theme") not in ["egypt", "swamp", "nyc"]:
		return "Choose Egyptian ruins, Purple Swamp-Woods or New York City."
	if not finite_number(d.get("width")) or not finite_number(d.get("height")):
		return "Map dimensions must be numbers."
	var w: int = int(d.width)
	var h: int = int(d.height)
	if w < 5 or h < 5 or w > MAX_SIDE or h > MAX_SIDE or d.width != w or d.height != h:
		return "Map dimensions must be whole numbers between 5 and 25."
	if not d.get("tiles") is Array or d.tiles.size() != h:
		return "Tile rows do not match the map height."
	for row in d.tiles:
		if not row is Array or row.size() != w:
			return "Tile columns do not match the map width."
		for tile in row:
			if tile not in TILES:
				return "Unknown terrain type."
	for key in ["spawn", "exit"]:
		if not point_valid(d.get(key), w, h):
			return "The %s must be inside the level." % key
		var p: Array = d[key]
		if p[0] != int(p[0]) or p[1] != int(p[1]) or d.tiles[int(p[1])][int(p[0])] in ["wall", "water"]:
			return "The %s must sit on a walkable grid cell." % key
	if d.spawn == d.exit:
		return "Place the exit away from the start."
	if not d.get("objects") is Array or d.objects.size() > 180:
		return "A level supports up to 180 objects."
	var ids: Dictionary = {}
	for obj in d.objects:
		if not obj is Dictionary or obj.get("type") not in OBJECTS or not point_valid(obj.get("pos"), w, h):
			return "Invalid object type or position."
		if not obj.get("id") is String or obj.id.is_empty() or ids.has(obj.id):
			return "Every object needs a unique ID."
		ids[obj.id] = true
		if not finite_number(obj.get("rotation", 0)):
			return "Object rotation must be finite."
		if obj.has("solid") and not obj.solid is bool:
			return "Solid must be true or false."
		if obj.type in ["pillar", "tree", "critter", "emitter", "roach", "skater", "city_prop"] or obj.get("solid", false):
			if d.tiles[int(obj.pos[1])][int(obj.pos[0])] in ["wall", "water"]:
				return "Place solid objects, critters and traps on dry terrain."
		if obj.type in ["critter", "roach"]:
			if obj.get("behavior", "wander") not in ["wander", "patrol"]:
				return "Unknown critter behavior."
			if not finite_number(obj.get("speed", 1.6)) or obj.get("speed", 1.6) < 0.3 or obj.get("speed", 1.6) > 5:
				return "Critter speed must be between 0.3 and 5."
			if not obj.get("waypoints", []) is Array or obj.get("waypoints", []).size() > 64:
				return "A patrol supports up to 64 waypoints."
			for point in obj.get("waypoints", []):
				if not point_valid(point, w, h) or d.tiles[int(point[1])][int(point[0])] in ["wall", "water"]:
					return "Patrol waypoints must be on dry terrain."
		if obj.type == "emitter":
			if not finite_number(obj.get("interval", 2.5)) or obj.get("interval", 2.5) < 0.5 or obj.get("interval", 2.5) > 10:
				return "Firing interval must be between 0.5 and 10 seconds."
	var streetlife_error := validate_streetlife(d)
	return validate_traffic(d) if streetlife_error.is_empty() else streetlife_error

static func validate_streetlife(d: Dictionary) -> String:
	var area: Variant = d.get("skate_area", {})
	if not area is Dictionary:
		return "Skate area must be an object."
	if not area.is_empty():
		if not point_valid(area.get("center"), d.width, d.height) or not finite_number(area.get("diameter")) or area.diameter < 5 or area.diameter > 18:
			return "Skate areas need an interior center and a diameter between 5 and 18 tiles."
		var radius := float(area.diameter) * 0.5
		if area.center[0] - radius < 0 or area.center[0] + radius >= d.width or area.center[1] - radius < 0 or area.center[1] + radius >= d.height:
			return "The circular skate area must fit inside the map."
	for obj in d.objects:
		if obj.type == "city_prop":
			if obj.get("variant") not in CITY_PROPS:
				return "Unknown NYC street prop."
			if obj.variant in ["skate_ramp", "skate_rail"]:
				if not finite_number(obj.get("length", 4.0)) or obj.get("length", 4.0) < 1 or obj.get("length", 4.0) > 5:
					return "Skate feature length must be between 1 and 5 world units."
			if obj.variant == "skate_ramp":
				if not finite_number(obj.get("rise", 0.7)) or obj.get("rise", 0.7) < 0.2 or obj.get("rise", 0.7) > 1.2:
					return "Ramp rise must be between 0.2 and 1.2 world units."
		if obj.type != "skater":
			continue
		if not finite_number(obj.get("variant", 0)) or obj.get("variant", 0) != int(obj.get("variant", 0)) or obj.get("variant", 0) < 0 or obj.get("variant", 0) > 2:
			return "Choose one of the three skater variants."
		if not finite_number(obj.get("speed", 3.2)) or obj.get("speed", 3.2) < 2 or obj.get("speed", 3.2) > 5.5:
			return "Skater speed must be between 2 and 5.5 world units per second."
		var route: Variant = obj.get("route")
		if not route is Array or route.size() < 4 or route.size() > 32:
			return "A skater needs a closed loop of 4 to 32 route points."
		for node in route:
			if not node is Dictionary or not point_valid(node.get("pos"), d.width, d.height):
				return "Skater route points must be inside the map."
			if not finite_number(node.get("height", 0.0)) or node.get("height", 0.0) < 0 or node.get("height", 0.0) > 1.2:
				return "Skater route heights must be between 0 and 1.2."
			if node.get("trick", "cruise") not in SKATE_TRICKS:
				return "Unknown skateboard action."
			if not area.is_empty() and Vector2(node.pos[0] - area.center[0], node.pos[1] - area.center[1]).length() > float(area.diameter) * 0.5:
				return "Keep skater routes inside the circular skate area."
		if Vector2(obj.pos[0], obj.pos[1]).distance_to(Vector2(route[0].pos[0], route[0].pos[1])) > 0.01:
			return "Place the skater at the first route point."
		for i in range(route.size()):
			var a := Vector2(route[i].pos[0], route[i].pos[1])
			var b := Vector2(route[(i + 1) % route.size()].pos[0], route[(i + 1) % route.size()].pos[1])
			var length := a.distance_to(b)
			if length < 0.1:
				return "Consecutive skate route points must be distinct."
			# Sample every quarter tile so straight segments cannot cut through a wall,
			# pond or ordinary solid prop between valid endpoints.
			for sample_index in range(ceili(length * 4) + 1):
				var point := a.lerp(b, float(sample_index) / maxf(1, ceili(length * 4)))
				var x := roundi(point.x)
				var y := roundi(point.y)
				for obstacle in d.objects:
					if obstacle.type == "city_prop" and obstacle.get("solid", false) and obstacle.get("variant") in CITY_PROPS and obstacle.variant not in ["skate_rail", "skate_ramp"] and Props.covers(obstacle, point, 0.42):
						return "Skater loops must avoid solid street props."
				if x < 0 or y < 0 or x >= d.width or y >= d.height or d.tiles[y][x] in ["wall", "water"]:
					return "Skate loops need dry, open ground along every segment."
	return ""

static func validate_traffic(d: Dictionary) -> String:
	var lanes: Variant = d.get("traffic", [])
	if not lanes is Array or lanes.size() > 12:
		return "Traffic supports up to 12 lanes."
	var rows: Dictionary = {}
	for lane in lanes:
		if not lane is Dictionary:
			return "Each traffic lane must be an object."
		var row: Variant = lane.get("row")
		if not finite_number(row) or row != int(row) or row < 1 or row >= d.height - 1 or rows.has(row):
			return "Traffic needs unique interior whole-number rows."
		rows[row] = true
		if not finite_number(lane.get("direction")) or absf(float(lane.direction)) != 1.0:
			return "Traffic direction must be -1 or 1."
		if not finite_number(lane.get("speed")) or lane.speed < 2 or lane.speed > 8:
			return "Traffic speed must be between 2 and 8."
		if not finite_number(lane.get("spacing")) or lane.spacing < 7 or lane.spacing > 20:
			return "Vehicle spacing must be between 7 and 20."
		if not finite_number(lane.get("offset", 0)) or lane.get("offset", 0) < 0 or lane.get("offset", 0) >= lane.spacing:
			return "Traffic offset must be within its spacing."
		if not lane.get("vehicles") is Array or lane.vehicles.is_empty() or lane.vehicles.size() > 8:
			return "Choose one to eight vehicle types per lane."
		for kind in lane.vehicles:
			if kind not in ["taxi", "sedan", "bus", "truck"]:
				return "Unknown traffic vehicle."
		for x in range(1, int(d.width) - 1):
			if d.tiles[int(row)][x] != "road":
				return "A traffic lane needs a complete interior road row."
		for obj in d.objects:
			if absf(float(obj.pos[1]) - float(row)) < 0.85:
				return "Keep traffic lanes clear of scenery and critters."
		if int(d.spawn[1]) == int(row) or int(d.exit[1]) == int(row):
			return "Place the start and exit on a safe sidewalk."
	var crossings: Variant = d.get("crossings", [])
	if not crossings is Array or crossings.size() > 8:
		return "Crossings must be a list of up to eight columns."
	for x in crossings:
		if not finite_number(x) or x != int(x) or x < 1 or x >= d.width - 1:
			return "Crosswalk columns must be interior whole numbers."
	return ""

static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if validate(d) != "":
		return {}
	return normalize(d)

static func normalize(value: Variant) -> Variant:
	# JSON numbers arrive as floats; whole grid coordinates must compare equally
	# with freshly painted integer coordinates after saving and importing.
	if value is float and is_finite(value) and value == floor(value):
		return int(value)
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(normalize(item))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value:
			result[key] = normalize(value[key])
		return result
	return value

static func save_json(path: String, level: Dictionary) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(level, "\t"))
	file.close()
	return OK

static func reachable(d: Dictionary) -> bool:
	return not find_route(d).is_empty()

static func find_route(d: Dictionary) -> Array[Vector2i]:
	var start := Vector2i(int(d.spawn[0]), int(d.spawn[1]))
	var goal := Vector2i(int(d.exit[0]), int(d.exit[1]))
	var blocked: Dictionary = {}
	for o in d.objects:
		if o.type == "city_prop" and o.get("solid", false):
			for y in range(int(d.height)):
				for x in range(int(d.width)):
					if Props.covers(o, Vector2(x, y)):
						blocked[Vector2i(x, y)] = true
		elif o.type in ["pillar", "tree", "emitter"] or o.get("solid", false):
			blocked[Vector2i(int(o.pos[0]), int(o.pos[1]))] = true
	var queue: Array[Vector2i] = [start]
	var visited: Dictionary = {start: start}
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		if p == goal:
			var result: Array[Vector2i] = []
			while p != start:
				result.push_front(p)
				p = visited[p]
			return result
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = p + offset
			if n.x < 0 or n.y < 0 or n.x >= d.width or n.y >= d.height or visited.has(n) or blocked.has(n):
				continue
			if d.tiles[n.y][n.x] in ["wall", "water"]:
				continue
			visited[n] = p
			queue.append(n)
	return []
