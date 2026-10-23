extends RefCounted
## The editor, bundled maps and runtime all consume this versioned format.
const VERSION = 1
const MAX_SIDE = 64
const THEMES = ["egypt", "swamp", "mexico", "honduras"]
const THEME_NAMES = ["Egyptian ruins", "Purple Swamp-Woods", "Mexico · Courtyard gardens", "Honduras · Jungle river"]
const NEW_NAMES = ["New Egypt", "New Swamp", "New Mexico", "New Honduras"]
const TILES = ["floor", "wall", "cheese_wall", "water", "path", "road"]
const OBJECTS = ["pillar", "tree", "mushroom", "decoration", "critter", "emitter", "car", "patrol_car", "log", "spike_ball", "landmark", "backdrop", "hop_fragment", "hop_seed"]

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

static func landmark_point_valid(p: Variant, w: int, h: int) -> bool:
	return p is Array and p.size() == 2 and finite_number(p[0]) and finite_number(p[1]) and p[0] >= -16 and p[1] >= -16 and p[0] < w+16 and p[1] < h+16

static func validate(d: Variant, editor_snapshot: bool = false) -> String:
	if not d is Dictionary:
		return "Expected a JSON level object."
	if not finite_number(d.get("version")) or float(d.version) != VERSION:
		return "Unsupported map version. This build reads version 1."
	if not d.get("name") is String or d.name.strip_edges().is_empty() or d.name.length() > 80:
		return "Give the level a name of 1–80 characters."
	if d.get("theme") not in THEMES:
		return "Choose Egyptian ruins, Purple Swamp-Woods, Mexico courtyard gardens or Honduras jungle river."
	if not finite_number(d.get("width")) or not finite_number(d.get("height")):
		return "Map dimensions must be numbers."
	if d.get("game_mode", "hopan") not in ["hopan", "tile"]:
		return "Choose Hopán or Tile Hop mode."
	if not d.get("move_with_me", false) is bool:
		return "Move with me must be true or false."
	var rules: Variant = d.get("rules", {})
	if not rules is Dictionary:
		return "Level rules must be an object."
	for key in rules:
		if key not in ["long_hop", "charge_hops"]:
			return "Unknown level rule: " + str(key)
	if rules.get("long_hop", "free") not in ["free", "charged", "fragments", "powerup"]:
		return "Choose free, charged, fragment or power-up long hops."
	var charge: Variant = rules.get("charge_hops", 10)
	if not finite_number(charge) or charge != int(charge) or charge < 1 or charge > 25:
		return "Long-hop recharge must be 1–25 whole hops."
	if not finite_number(d.get("draw_distance",18)) or d.get("draw_distance",18) < 10 or d.get("draw_distance",18) > 30:
		return "Draw distance must be between 10 and 30 tiles."
	var w: int = int(d.width)
	var h: int = int(d.height)
	if w < 5 or h < 5 or w > MAX_SIDE or h > MAX_SIDE or d.width != w or d.height != h:
		return "Map dimensions must be whole numbers between 5 and 64."
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
	if not editor_snapshot and d.tiles[int(d.spawn[1])][int(d.spawn[0])] == "road":
		return "The frog start is on a road. Paint a safe floor or path there, or move the start off the road."
	if d.has("checkpoint"):
		var p: Variant = d.checkpoint
		if not point_valid(p, w, h) or p[0] != int(p[0]) or p[1] != int(p[1]) or d.tiles[int(p[1])][int(p[0])] in ["wall", "cheese_wall", "water", "road"]:
			return "The checkpoint must sit on a whole, safe bank cell."
	if not d.get("objects") is Array or d.objects.size() > 180:
		return "A level supports up to 180 objects."
	var ids: Dictionary = {}
	var landmark_count := 0
	var backdrop_count := 0
	for obj in d.objects:
		if not obj is Dictionary or obj.get("type") not in OBJECTS or not (landmark_point_valid(obj.get("pos"),w,h) if obj.get("type") in ["landmark","backdrop"] else point_valid(obj.get("pos"), w, h)):
			return "Invalid object type or position."
		if not obj.get("id") is String or obj.id.is_empty() or ids.has(obj.id):
			return "Every object needs a unique ID."
		ids[obj.id] = true
		if not finite_number(obj.get("rotation", 0)):
			return "Object rotation must be finite."
		if d.get("game_mode") == "tile" and obj.get("behavior") != "seam_patrol":
			if obj.pos[0] != int(obj.pos[0]) or obj.pos[1] != int(obj.pos[1]):
				return "Tile mode objects need whole tile positions."
			for p in obj.get("waypoints", []) if obj.get("waypoints", []) is Array else []:
				if not point_valid(p,w,h) or p[0] != int(p[0]) or p[1] != int(p[1]):
					return "Tile mode patrols need whole tile waypoints."
			if obj.type == "emitter" and not is_zero_approx(fposmod(float(obj.get("rotation",0)),90)):
				return "Tile-mode darts need a cardinal direction."
		if obj.type in ["hop_fragment", "hop_seed"]:
			if obj.get("solid",false) != false or obj.pos[0] != int(obj.pos[0]) or obj.pos[1] != int(obj.pos[1]): return "Hop pickups need whole cells and cannot block movement."
			if not editor_snapshot and not checkpoint_open(d,obj.pos,obj.type == "hop_fragment"): return "Hop fragments need clear dry ground or road; Hop seeds need a safe bank."
			if d.objects.any(func(other): return other is Dictionary and other.get("id") != obj.id and other.get("type") in ["hop_fragment","hop_seed"] and other.get("pos") == obj.pos): return "Place one hop pickup per tile."
		if obj.type == "landmark":
			landmark_count += 1
			if landmark_count > 32: return "A level supports up to 32 landmarks."
			if obj.get("landmark_kind", "sphinx") not in ["sphinx","osiris","pyramid","moss_tree","heron"]:
				return "Unknown landmark model."
			if not finite_number(obj.get("landmark_scale",1)) or obj.get("landmark_scale",1) < 0.25 or obj.get("landmark_scale",1) > 2:
				return "Landmark scale must be between 0.25 and 2."
			if obj.get("solid",false) != false: return "Landmarks are non-blocking scenery."
		if obj.type == "backdrop":
			backdrop_count += 1
			if backdrop_count > 4: return "A level supports up to four distant backdrops."
			if obj.get("backdrop_kind", "pyramid") not in ["sphinx","osiris","pyramid","moss_tree","heron"]: return "Unknown distant backdrop."
			if not finite_number(obj.get("backdrop_scale",80)) or obj.get("backdrop_scale",80)<1 or obj.get("backdrop_scale",80)>100: return "Backdrop art scale must be between 1 and 100."
			if not finite_number(obj.get("backdrop_distance",480)) or obj.get("backdrop_distance",480)<128 or obj.get("backdrop_distance",480)>2048: return "Backdrop distance must be between 128 and 2048."
			if obj.get("solid",false) != false: return "Distant backdrops are non-blocking art."
		if obj.has("solid") and not obj.solid is bool:
			return "Solid must be true or false."
		if obj.type in ["car", "patrol_car", "log"]:
			if obj.pos[1] != int(obj.pos[1]) or (not editor_snapshot and d.tiles[int(obj.pos[1])][int(obj.pos[0])] != ("water" if obj.type == "log" else "road")):
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
				if not point_valid(route[i], w, h) or route[i][0] != int(route[i][0]) or route[i][1] != int(route[i][1]) or (not editor_snapshot and not road_cell_open(d, Vector2i(route[i][0],route[i][1]))):
					return "Car patrol waypoints need open road tiles."
				if not editor_snapshot and i > 0 and not road_segment_open(d, route[i-1],route[i]):
					return "Car patrol routes must follow connected road tiles with square turns."
		if obj.type in ["pillar", "tree", "critter", "emitter"] or obj.get("solid", false):
			if not editor_snapshot and d.tiles[int(obj.pos[1])][int(obj.pos[0])] in ["wall", "cheese_wall", "water"]:
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
				if not point_valid(point, w, h) or (not editor_snapshot and d.tiles[int(point[1])][int(point[0])] in ["wall", "cheese_wall", "water"]):
					return "Patrol waypoints must be on dry terrain."
			if obj.get("behavior") == "seam_patrol":
				if obj.has("seam_anchor"):
					var anchor: Variant = obj.seam_anchor
					if not point_valid(anchor, w, h) or anchor[0] != int(anchor[0]) or anchor[1] != int(anchor[1]):
						return "Seam worm placement tiles must be whole cells inside the level."
				var route: Array = [obj.pos] + obj.get("waypoints", [])
				if obj.get("patrol_loop", true) and obj.get("waypoints", []).size() > 1:
					route.append(obj.waypoints[0])
				for i in range(route.size()):
					if not editor_snapshot and not seam_point_open(d, route[i]):
						return "Seam worms need open tile corners."
					if not editor_snapshot and i > 0 and not seam_segment_open(d, route[i - 1], route[i]):
						return "Seam worm routes must follow clear horizontal or vertical tile edges. Add a corner before turning."
		if obj.type == "spike_ball":
			if obj.pos[0] != int(obj.pos[0]) or obj.pos[1] != int(obj.pos[1]) or obj.get("behavior","free_shift") not in ["free_shift","slam_patrol"]:
				return "Spike balls need whole cells and free-shift or slam-patrol behavior."
			if obj.get("solid",false): return "Spike balls are moving hazards, not static blockers."
			if not finite_number(obj.get("pause",2)) or obj.get("pause",2)<1 or obj.get("pause",2)>6:
				return "Spike hold must be between 1 and 6 beats/seconds."
			if not finite_number(obj.get("range",3)) or obj.get("range",3)!=int(obj.get("range",3)) or obj.get("range",3)<1 or obj.get("range",3)>5:
				return "Free spike shifts cover 1–5 whole tiles."
			var directions: Variant = obj.get("directions",[0,90,180,270])
			if not directions is Array or directions.is_empty() or directions.size()>4:
				return "Enable one to four cardinal spike directions."
			var seen: Array=[]
			for direction in directions:
				if not finite_number(direction) or direction!=int(direction) or int(direction) not in [0,90,180,270] or int(direction) in seen: return "Spike directions must be distinct cardinal directions."
				seen.append(int(direction))
			if obj.has("patrol_loop") and not obj.patrol_loop is bool: return "Loop route must be true or false."
			if not obj.get("waypoints",[]) is Array or obj.get("waypoints",[]).size()>64: return "Spike patrols support up to 64 points."
			if not editor_snapshot and not spike_cell_open(d,Vector2i(obj.pos[0],obj.pos[1])): return "Spike balls need clear, dry starting cells."
			var route: Array=[obj.pos]+obj.get("waypoints",[])
			if obj.get("patrol_loop",true) and route.size()>1: route.append(obj.pos)
			for i in range(route.size()):
				if not point_valid(route[i],w,h) or route[i][0]!=int(route[i][0]) or route[i][1]!=int(route[i][1]): return "Spike patrol points need whole cells inside the map."
				if not editor_snapshot and obj.get("behavior","free_shift")=="slam_patrol" and (not spike_cell_open(d,Vector2i(route[i][0],route[i][1])) or (i>0 and not spike_segment_open(d,route[i-1],route[i]))):
					return "Spike patrols need clear dry cardinal segments; use corners or disable Loop."
		if obj.type == "emitter":
			if not finite_number(obj.get("interval", 2.5)) or obj.get("interval", 2.5) < 0.5 or obj.get("interval", 2.5) > 10:
				return "Firing interval must be between 0.5 and 10 seconds."
	if not d.get("signs",[]) is Array or d.get("signs",[]).size() > 16:
		return "A level supports up to 16 instruction signs."
	for sign in d.get("signs",[]):
		if not sign is Dictionary or not point_valid(sign.get("pos"),w,h) or not sign.get("text") is String or sign.text.length() > 200:
			return "Invalid instruction sign."
	if not d.get("checkpoints", []) is Array or d.get("checkpoints", []).size() > 16:
		return "A level supports up to 16 editor checkpoints."
	var seen_checkpoints: Array = []
	for p in d.get("checkpoints", []):
		if not point_valid(p, w, h) or p[0] != int(p[0]) or p[1] != int(p[1]) or (not editor_snapshot and not checkpoint_open(d, p)):
			return "Checkpoints need whole cells on clear, safe ground."
		if p in seen_checkpoints or p == d.spawn or p == d.exit or p == d.get("checkpoint", []):
			return "Checkpoints need distinct tiles away from the start and exit."
		seen_checkpoints.append(p)
	return ""

static func checkpoint_open(d: Dictionary, p: Array, allow_road: bool = false) -> bool:
	if not point_valid(p, int(d.width), int(d.height)) or d.tiles[int(p[1])][int(p[0])] in (["wall", "cheese_wall", "water"] if allow_road else ["wall", "cheese_wall", "water", "road"]):
		return false
	for obj in d.objects:
		if not obj is Dictionary: return false
		if obj.get("pos") == p and (obj.get("type") in ["pillar", "tree", "emitter"] or obj.get("solid", false)):
			return false
	return true

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
			for distance in ([1,2] if d.get("game_mode") == "tile" else [1]):
				var n: Vector2i = p + offset * distance
				if n.x < 0 or n.y < 0 or n.x >= d.width or n.y >= d.height or visited.has(n) or blocked.has(n): continue
				if distance == 2:
					var middle: Vector2i = p + offset
					if d.tiles[middle.y][middle.x] in ["wall","cheese_wall"]: continue
				if d.tiles[n.y][n.x] in ["wall", "cheese_wall"] or (d.tiles[n.y][n.x] == "water" and not has_log_lane(d, n.y)): continue
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

static func spike_cell_open(d: Dictionary, cell: Vector2i) -> bool:
	if cell.x<0 or cell.y<0 or cell.x>=d.width or cell.y>=d.height or d.tiles[cell.y][cell.x] in ["wall","cheese_wall","water"]: return false
	for obj in d.objects:
		if Vector2(obj.pos[0],obj.pos[1])==Vector2(cell) and (obj.type in ["pillar","tree","emitter"] or obj.get("solid",false)): return false
	return true

static func spike_segment_open(d: Dictionary, from: Array, to: Array) -> bool:
	var start:=Vector2i(from[0],from[1])
	var end:=Vector2i(to[0],to[1])
	if start.x!=end.x and start.y!=end.y: return false
	var difference:=end-start
	var direction:=Vector2i(signi(difference.x),signi(difference.y))
	for i in range(maxi(absi(difference.x),absi(difference.y))+1):
		if not spike_cell_open(d,start+direction*i): return false
	return true
