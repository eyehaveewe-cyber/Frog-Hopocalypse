extends RefCounted
## The editor, bundled maps and runtime all consume this versioned format.
const VERSION = 1
const MAX_SIDE = 25
const TILES = ["floor", "wall", "water", "path"]
const OBJECTS = ["pillar", "tree", "mushroom", "decoration", "critter", "emitter"]

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
	if d.get("theme") not in ["egypt", "swamp"]:
		return "Choose the Egyptian ruins or Purple Swamp-Woods theme."
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
		if obj.type in ["pillar", "tree", "critter", "emitter"] or obj.get("solid", false):
			if d.tiles[int(obj.pos[1])][int(obj.pos[0])] in ["wall", "water"]:
				return "Place solid objects, critters and traps on dry terrain."
		if obj.type == "critter":
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
	var start := Vector2i(int(d.spawn[0]), int(d.spawn[1]))
	var goal := Vector2i(int(d.exit[0]), int(d.exit[1]))
	var blocked: Dictionary = {}
	for o in d.objects:
		if o.type in ["pillar", "tree", "emitter"] or o.get("solid", false):
			blocked[Vector2i(int(o.pos[0]), int(o.pos[1]))] = true
	var queue: Array[Vector2i] = [start]
	var visited: Dictionary = {start: true}
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		if p == goal:
			return true
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = p + offset
			if n.x < 0 or n.y < 0 or n.x >= d.width or n.y >= d.height or visited.has(n) or blocked.has(n):
				continue
			if d.tiles[n.y][n.x] in ["wall", "water"]:
				continue
			visited[n] = true
			queue.append(n)
	return false
