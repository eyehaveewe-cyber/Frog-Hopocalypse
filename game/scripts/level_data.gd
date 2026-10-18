extends RefCounted
## The editor, bundled maps and runtime all consume this versioned format.
const VERSION = 1
const MAX_SIDE = 25
const TILES = ["floor", "wall", "cheese_wall", "water", "path", "road"]
const OBJECTS = ["pillar", "tree", "mushroom", "decoration", "critter", "emitter", "car", "patrol_car", "log"]

static func blank(title: String = "My magnificent maze", theme_name: String = "egypt", w: int = 17, h: int = 13) -> Dictionary:
	var tiles: Array = []
	for y in range(h):
		var row: Array = []
		for x in range(w):
			row.append("wall" if x == 0 or y == 0 or x == w - 1 or y == h - 1 else "floor")
		tiles.append(row)
	return {"version": VERSION, "name": title, "theme": theme_name, "width": w, "height": h,
		"tiles": tiles, "spawn": [1, h - 2], "exit": [w - 2, 1], "objects": []}

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
		if p[0] != int(p[0]) or p[1] != int(p[1]) or d.tiles[int(p[1])][int(p[0])] in ["wall", "cheese_wall", "water"]:
			return "The %s must sit on a walkable grid cell." % key
	if d.spawn == d.exit:
		return "Place the exit away from the start."
	if d.has("checkpoint"):
		var p: Variant = d.checkpoint
		if not point_valid(p, w, h) or p[0] != int(p[0]) or p[1] != int(p[1]) or d.tiles[int(p[1])][int(p[0])] in ["wall", "cheese_wall", "water", "road"]:
			return "The checkpoint must sit on a whole, safe bank cell."
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
		if obj.type in ["car", "patrol_car", "log"]:
			if obj.pos[1] != int(obj.pos[1]) or d.tiles[int(obj.pos[1])][int(obj.pos[0])] != ("water" if obj.type == "log" else "road"):
				return "Place logs on water and cars on road lanes."
			if not finite_number(obj.get("speed", 1.0)) or obj.get("speed", 1.0) < 0.3 or obj.get("speed", 1.0) > 4:
				return "Lane speed must be between 0.3 and 4."
			if not finite_number(obj.get("length", 1.5)) or obj.get("length", 1.5) < 1 or obj.get("length", 1.5) > 6:
				return "Cars and logs must be between 1 and 6 cells long."
			if not finite_number(obj.get("direction", 1)) or absf(float(obj.get("direction", 1))) != 1.0:
				return "Lane direction must be -1 or 1."
			if obj.get("solid", false):
				return "Moving cars and logs use lane collisions, not static blockers."
			if obj.has("color") and (not obj.color is String or obj.color.length() > 16):
				return "Car color must be a short color string."
		if obj.type == "patrol_car":
			if obj.pos[0] != int(obj.pos[0]) or obj.get("axis", "east_west") not in ["east_west", "north_south"]:
				return "Patrol cars need whole road cells and a north-south or east-west axis."
			if float(obj.get("length", 1.0)) > 1.0:
				return "Patrol cars must fit within one road tile."
			if not obj.get("waypoints", []) is Array or obj.get("waypoints", []).size() > 64:
				return "A car patrol supports up to 64 road waypoints."
			var route: Array = [obj.pos] + obj.get("waypoints", [])
			if obj.get("waypoints", []).size() > 1:
				route.append(obj.waypoints[0])
			for i in range(route.size()):
				if not point_valid(route[i], w, h) or route[i][0] != int(route[i][0]) or route[i][1] != int(route[i][1]) or not road_cell_open(d, Vector2i(route[i][0],route[i][1])):
					return "Car patrol waypoints need open road tiles."
				if i > 0 and not road_segment_open(d, route[i-1],route[i]):
					return "Car patrol routes must follow connected road tiles with square turns."
		if obj.type in ["pillar", "tree", "critter", "emitter"] or obj.get("solid", false):
			if d.tiles[int(obj.pos[1])][int(obj.pos[0])] in ["wall", "cheese_wall", "water"]:
				return "Place solid objects, critters and traps on dry terrain."
		if obj.type == "critter":
			if obj.has("patrol_loop") and not obj.patrol_loop is bool:
				return "Loop route must be true or false."
			if obj.get("behavior", "wander") not in ["wander", "patrol", "seam_patrol"]:
				return "Unknown critter behavior."
			if not finite_number(obj.get("speed", 1.6)) or obj.get("speed", 1.6) < 0.3 or obj.get("speed", 1.6) > 5:
				return "Critter speed must be between 0.3 and 5."
			if not obj.get("waypoints", []) is Array or obj.get("waypoints", []).size() > 64:
				return "A patrol supports up to 64 waypoints."
			for point in obj.get("waypoints", []):
				if not point_valid(point, w, h) or d.tiles[int(point[1])][int(point[0])] in ["wall", "cheese_wall", "water"]:
					return "Patrol waypoints must be on dry terrain."
			if obj.get("behavior") == "seam_patrol":
				var route: Array = [obj.pos] + obj.get("waypoints", [])
				if obj.get("patrol_loop", true) and obj.get("waypoints", []).size() > 1:
					route.append(obj.waypoints[0])
				for i in range(route.size()):
					if not seam_point_open(d, route[i]):
						return "Seam worms need open tile corners."
					if i > 0 and not seam_segment_open(d, route[i - 1], route[i]):
						return "Seam worm routes must follow clear horizontal or vertical tile edges. Add a corner before turning."
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
		# Trees have narrow trunks; do not reject a structural exit route as a whole blocked tile.
		if o.type in ["pillar", "emitter"] or (o.type != "tree" and o.get("solid", false)):
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
			if d.tiles[n.y][n.x] in ["wall", "cheese_wall"] or (d.tiles[n.y][n.x] == "water" and not has_log_lane(d, n.y)):
				continue
			visited[n] = true
			queue.append(n)
	return false

static func has_log_lane(d: Dictionary, row: int) -> bool:
	# Structural access only. Moving-log timing is checked in the real runtime.
	for obj in d.objects:
		if obj.type == "log" and int(obj.pos[1]) == row:
			return true
	return false

static func seam_point_open(d: Dictionary, p: Array) -> bool:
	if p.size() != 2 or not finite_number(p[0]) or not finite_number(p[1]):
		return false
	if not is_equal_approx(fposmod(float(p[0]), 1), 0.5) or not is_equal_approx(fposmod(float(p[1]), 1), 0.5):
		return false
	var x := floori(float(p[0]))
	var y := floori(float(p[1]))
	for z in [y, y + 1]:
		for col in [x, x + 1]:
			if col < 0 or z < 0 or col >= int(d.width) or z >= int(d.height) or d.tiles[z][col] in ["wall", "cheese_wall", "water"]:
				return false
			for obj in d.objects:
				if obj.pos == [col, z] and (obj.type in ["pillar", "tree", "emitter"] or obj.get("solid", false)):
					return false
	return true

static func seam_segment_open(d: Dictionary, a: Array, b: Array) -> bool:
	if a[0] != b[0] and a[1] != b[1]:
		return false
	var from := Vector2(a[0], a[1])
	var to := Vector2(b[0], b[1])
	var steps := ceili(from.distance_to(to))
	for i in range(steps + 1):
		var point := from.lerp(to, float(i) / maxf(1, steps))
		if not seam_point_open(d, [point.x, point.y]):
			return false
	return true

static func road_cell_open(d: Dictionary, cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= int(d.width) or cell.y >= int(d.height) or d.tiles[cell.y][cell.x] != "road":
		return false
	for obj in d.objects:
		if obj.pos == [cell.x, cell.y] and (obj.type in ["pillar", "tree", "emitter"] or obj.get("solid", false)):
			return false
	return true

static func road_segment_open(d: Dictionary, a: Array, b: Array) -> bool:
	if a[0] != b[0] and a[1] != b[1]:
		return false
	var from := Vector2(a[0], a[1])
	var to := Vector2(b[0], b[1])
	var steps := ceili(from.distance_to(to))
	for i in range(steps + 1):
		var point := from.lerp(to, float(i) / maxf(1, steps))
		if not road_cell_open(d, Vector2i(roundi(point.x),roundi(point.y))):
			return false
	return true
