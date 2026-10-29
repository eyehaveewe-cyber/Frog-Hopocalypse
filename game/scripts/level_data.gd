extends RefCounted
## The editor, bundled maps and runtime all consume this versioned format.
const BridgeStunts = preload("res://scripts/bridge_stunts.gd")
const Props = preload("res://scripts/streetlife_specs.gd")
const CITY_PROPS = ["bench", "trash_can", "dumpster", "pizza_cart", "mailbox", "traffic_cone", "manhole", "newsstand", "skate_rail", "skate_ramp"]
const SKATE_TRICKS = ["cruise", "push", "grind", "ramp"]
const VERSION = 1
const MAX_SIDE = 64
const THEMES = ["egypt", "swamp", "mexico", "honduras", "nyc"]
const THEME_NAMES = ["Egyptian ruins", "Purple Swamp-Woods", "Mexico · Courtyard gardens", "Honduras · Jungle river", "New York City"]
const NEW_NAMES = ["New Egypt", "New Swamp", "New Mexico", "New Honduras", "New NYC"]
const TILES = ["floor", "wall", "cheese_wall", "water", "path", "road"]
const OBJECTS = ["pillar", "tree", "mushroom", "decoration", "critter", "emitter", "car", "patrol_car", "log", "spike_ball", "landmark", "backdrop", "hop_fragment", "hop_seed", "roach", "skater", "city_prop"]

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
		if key == "exit" and not d.has("exit"):
			return "Exit gate is missing. Add an exit coordinate [x, y] on a walkable tile to the level JSON, then import again."
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
		if obj.type in ["pillar", "tree", "critter", "roach", "skater", "emitter", "city_prop"] or obj.get("solid", false):
			var object_cell := Vector2i(roundi(obj.pos[0]),roundi(obj.pos[1])) if obj.type == "skater" else Vector2i(obj.pos[0],obj.pos[1])
			if object_cell.x<0 or object_cell.y<0 or object_cell.x>=w or object_cell.y>=h: return "Place actors within playable tiles."
			if not editor_snapshot and d.tiles[object_cell.y][object_cell.x] in ["wall", "cheese_wall", "water"]:
				return "Place solid objects, critters and traps on dry terrain."
		if obj.type in ["critter", "roach"]:
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
					if absf(float(obj.pos[0]) - float(anchor[0])) != 0.5 or absf(float(obj.pos[1]) - float(anchor[1])) != 0.5:
						return "A seam worm's placement tile must touch its corner. Move the placement tile beside the worm or remove its seam_anchor field."
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
	if not editor_snapshot and d.get("game_mode") == "tile" and rules.get("long_hop") == "fragments":
		var fragment_count: int = d.objects.filter(func(obj): return obj.type == "hop_fragment").size()
		if reachable(d) and not reachable(d, false):
			if fragment_count < 3:
				return "This crossing needs a long hop, but the level has fewer than three fragments. Place at least three fragments or open a short-hop route."
			var accessible_fragments := 0
			for obj in d.objects:
				if obj.type == "hop_fragment" and reachable(d, false, obj.pos):
					accessible_fragments += 1
					if accessible_fragments == 3: break
			if accessible_fragments < 3:
				return "The first required long hop needs three fragments reachable by short hops before the gap. Move fragments onto the starting side or open a short-hop route."
	var journey_error := validate_city_journey(d)
	if not journey_error.is_empty(): return journey_error
	var streetlife_error := validate_streetlife(d)
	return validate_traffic(d) if streetlife_error.is_empty() else streetlife_error

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

static func reachable(d: Dictionary, allow_long_hop: bool = true, target: Array = []) -> bool:
	var start := Vector2i(int(d.spawn[0]), int(d.spawn[1]))
	var goal := Vector2i(int(target[0]), int(target[1])) if target.size() == 2 else Vector2i(int(d.exit[0]), int(d.exit[1]))
	var blocked: Dictionary = {}
	for o in d.objects:
		if o.type == "city_prop" and o.get("solid", false):
			for y in range(int(d.height)):
				for x in range(int(d.width)):
					if Props.covers(o,Vector2(x,y)): blocked[Vector2i(x,y)] = true
			continue
		# Trees have narrow trunks; do not reject a structural exit route as a whole blocked tile.
		if o.type in ["pillar", "emitter"] or (o.type != "tree" and o.get("solid", false)):
			blocked[Vector2i(int(o.pos[0]), int(o.pos[1]))] = true
	var queue: Array[Vector2i] = [start]
	var visited: Dictionary = {start: true}
	var ramp_links: Array = []
	if d.get("city_journey", {}) is Dictionary and d.get("city_journey", {}).get("movement", "walk") == "skate" and validate_city_journey(d).is_empty():
		ramp_links = d.city_journey.get("ramps", [])
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		if p == goal:
			return true
		# A declared skateboard launch links two ground regions. This is structural
		# access, not a promise that any approach speed clears the wall at runtime.
		if not ramp_links.is_empty():
			for ramp in ramp_links:
				if not ramp.has("landing") or p != Vector2i(roundi(ramp.from[0]), roundi(ramp.from[1])): continue
				var landing := Vector2i(roundi(ramp.landing[0]), roundi(ramp.landing[1]))
				if not visited.has(landing) and not blocked.has(landing):
					visited[landing] = true
					queue.append(landing)
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			for distance in ([1,2] if d.get("game_mode") == "tile" and allow_long_hop else [1]):
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

static func rect_valid(rect: Variant, w: int, h: int) -> bool:
	if not rect is Array or rect.size() != 4: return false
	for number in rect:
		if not finite_number(number) or number != int(number): return false
	return rect[0] >= 1 and rect[1] >= 1 and rect[2] < w - 1 and rect[3] < h - 1 and rect[0] <= rect[2] and rect[1] <= rect[3]

static func bridge_surface_height(d: Dictionary, point: Vector2) -> float:
	var height := 0.0
	for bridge in d.get("city_journey", {}).get("bridges", []):
		var rect: Array = bridge.rect
		if point.x < rect[0] - 0.5 or point.x > rect[2] + 0.5 or point.y < rect[1] - 0.5 or point.y > rect[3] + 0.5: continue
		var axis := 0 if bridge.axis == "x" else 1
		var along := point.x if axis == 0 else point.y
		var distance: float = minf(along - float(rect[axis]) + 0.5, float(rect[axis + 2]) + 0.5 - along)
		height = maxf(height, float(bridge.height) * clampf(distance / float(bridge.ramp_cells), 0, 1))
	return height

static func validate_city_journey(d: Dictionary) -> String:
	var journey: Variant = d.get("city_journey", {})
	if not journey is Dictionary: return "City journey must be an object."
	if not journey.is_empty():
		if d.get("game_mode", "hopan") != "hopan" or d.theme != "nyc": return "City traversal is available on continuous NYC levels."
		if journey.get("movement", "walk") not in ["walk", "skate"]: return "City movement must be walk or skate."
		for key in journey:
			if key not in ["movement", "ice", "bridges", "ramps", "rails", "buildings", "parks", "islands"]: return "Unknown city journey field: " + str(key)
		for key in ["ice", "bridges", "ramps", "rails", "buildings", "parks", "islands"]:
			if not journey.get(key, []) is Array or journey.get(key, []).size() > 16: return "City traversal supports up to 16 features of each kind."
		for building in journey.get("buildings", []):
			if not building is Dictionary or not rect_valid(building.get("rect"), d.width, d.height): return "City buildings need ordered interior rectangles of whole cells."
			if not finite_number(building.get("height")) or building.height < 1 or building.height > 7: return "City building height must be between 1 and 7 world units."
			for y in range(int(building.rect[1]), int(building.rect[3]) + 1):
				for x in range(int(building.rect[0]), int(building.rect[2]) + 1):
					if d.tiles[y][x] != "wall": return "City buildings must sit entirely on blocked wall footprints."
		for patch in journey.get("ice", []):
			if not patch is Dictionary or not rect_valid(patch.get("rect"), d.width, d.height): return "Ice needs an ordered interior rectangle of whole cells."
		for park in journey.get("parks", []):
			if not park is Dictionary or not rect_valid(park.get("rect"), d.width, d.height): return "Parks need ordered interior rectangles of whole cells."
		for island in journey.get("islands",[]):
			if not island is Dictionary or not rect_valid(island.get("rect"),d.width,d.height): return "Dry islands need ordered interior rectangles."
		for bridge in journey.get("bridges", []):
			if not bridge is Dictionary or not rect_valid(bridge.get("rect"), d.width, d.height): return "Bridges need ordered interior rectangles of whole cells."
			if bridge.get("axis") not in ["x", "z"]: return "Bridge axis must be x or z."
			if not finite_number(bridge.get("height")) or bridge.height < 1.6 or bridge.height > 4: return "Bridge height must be between 1.6 and 4 world units."
			if not finite_number(bridge.get("ramp_cells")) or bridge.ramp_cells != int(bridge.ramp_cells) or bridge.ramp_cells < 1 or bridge.ramp_cells > 8: return "Bridge ramps need 1 to 8 whole cells."
			var axis := 0 if bridge.axis == "x" else 1
			if bridge.rect[axis + 2] - bridge.rect[axis] + 1 < bridge.ramp_cells * 2 + 1: return "Bridge length must include both ramps and a level deck."
		for key in ["ramps", "rails"]:
			for feature in journey.get(key, []):
				if not feature is Dictionary or not point_valid(feature.get("from"), d.width, d.height) or not point_valid(feature.get("to"), d.width, d.height): return "Skate features need two endpoints inside the map."
				var a := Vector2(feature.from[0], feature.from[1])
				var b := Vector2(feature.to[0], feature.to[1])
				if (a.x != b.x and a.y != b.y) or a.distance_to(b) < 0.5 or a.distance_to(b) > 16: return "Skate features need distinct cardinal endpoints 0.5 to 16 cells apart."
				var height_key := "rise" if key == "ramps" else "height"
				if not finite_number(feature.get(height_key)) or feature[height_key] < 0.2 or feature[height_key] > (3.2 if key == "rails" else 1.2): return "Ramps support heights0.2–1.2; rails support0.2–3.2."
				if key == "rails":
					for endpoint in ["entry","exit"]:
						if not feature.has(endpoint): continue
						if not point_valid(feature[endpoint],d.width,d.height): return "Rail approaches must be inside the map."
						var foot := Vector2(feature[endpoint][0],feature[endpoint][1])
						var lip := a if endpoint == "entry" else b
						if absf((lip-foot).cross((b-a).normalized()))>0.001 or foot.distance_to(lip)<1 or foot.distance_to(lip)>6: return "Rail approaches need aligned endpoints 1 to 6 cells long."
					if feature.height>1.2 and (not feature.has("entry") or not feature.has("exit")): return "High rails require visible entry and exit approaches."
				if key == "ramps":
					for step in range(ceili(a.distance_to(b) * 2) + 1):
						var point := a.lerp(b, float(step) / maxf(1, ceili(a.distance_to(b) * 2)))
						if not checkpoint_open(d, [roundi(point.x), roundi(point.y)], true): return "Ramp approaches must stay on clear dry ground up to the lip."
				if key == "ramps" and feature.has("landing"):
					if journey.get("movement", "walk") != "skate" or not point_valid(feature.landing, d.width, d.height): return "Declared ramp landings need skate movement and an interior point."
					var landing := Vector2(feature.landing[0], feature.landing[1])
					var direction := (b - a).normalized()
					var distance := (landing - b).dot(direction)
					if landing.x != floorf(landing.x) or landing.y != floorf(landing.y) or absf((landing - b).cross(direction)) > 0.001 or distance < 2 or distance > 4: return "Ramp landings need whole cells 2 to 4 cells beyond the lip in its launch direction."
					if not checkpoint_open(d, feature.landing, true) or not checkpoint_open(d, feature.from, true): return "Ramp approach and landing need clear dry ground."
	var encounters: Variant = d.get("park_encounters", [])
	if not encounters is Array or encounters.size() > 24: return "Park encounters support up to 24 hazards."
	var ids := {}
	for encounter in encounters:
		if not encounter is Dictionary or not encounter.get("id") is String or encounter.id.is_empty() or ids.has(encounter.id): return "Park encounters need unique IDs."
		ids[encounter.id] = true
		if encounter.get("kind") not in ["ambusher", "pigeons", "purse", "ice_duet"] or not point_valid(encounter.get("pos"), d.width, d.height): return "Park encounters need a known kind and an interior position."
		var direction: Variant = encounter.get("direction", [0, 1])
		if not direction is Array or direction.size() != 2 or not finite_number(direction[0]) or not finite_number(direction[1]) or absf(float(direction[0])) + absf(float(direction[1])) != 1 or (direction[0] != 0 and direction[1] != 0): return "Park hazard direction must be a cardinal unit vector."
		if not finite_number(encounter.get("phase", 0)) or encounter.get("phase", 0) < 0 or encounter.get("phase", 0) > 60: return "Park hazard phase must be between 0 and 60 seconds."
		if not finite_number(encounter.get("radius", 2.0)) or encounter.get("radius", 2.0) < 0.5 or encounter.get("radius", 2.0) > 8: return "Park duet radius must be between 0.5 and 8 world units."
	return ""

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
		var stunts: Variant = obj.get("bridge_stunts",{})
		if not stunts is Dictionary: return "Bridge stunts must be an object."
		var stunt_bridge: Dictionary = {}
		if not stunts.is_empty():
			var bridges: Array = d.get("city_journey",{}).get("bridges",[])
			if not finite_number(stunts.get("bridge")) or stunts.bridge != int(stunts.bridge) or stunts.bridge<0 or stunts.bridge>=bridges.size(): return "Stunt skaters need a valid bridge index."
			if not finite_number(stunts.get("seed")) or stunts.seed!=int(stunts.seed) or stunts.seed<0 or stunts.seed>1000000 or not finite_number(stunts.get("side")) or absf(float(stunts.side)) != 1.0: return "Stunt skaters need a bounded seed and left or right side."
			stunt_bridge = bridges[int(stunts.bridge)]
			var axis: int = 0 if stunt_bridge.axis == "x" else 1
			if stunt_bridge.rect[axis+2]-stunt_bridge.rect[axis]+1-stunt_bridge.ramp_cells*2<5: return "Bridge stunts need at least five cells of level deck."
		var route: Variant = obj.get("route") if stunts.is_empty() else BridgeStunts.route(stunts,stunt_bridge,0)
		if not route is Array or route.size() < 4 or route.size() > 32:
			return "A skater needs a closed loop of 4 to 32 route points."
		for node in route:
			if not node is Dictionary or not point_valid(node.get("pos"), d.width, d.height):
				return "Skater route points must be inside the map."
			var surface := bridge_surface_height(d, Vector2(node.pos[0], node.pos[1]))
			if not finite_number(node.get("height", 0.0)) or node.get("height", 0.0) < 0 or (node.get("height", 0.0) > 1.2 and (absf(float(node.height) - surface) > 0.06 if stunts.is_empty() else (node.height < surface or node.height > surface+1.2))):
				return "Elevated skater routes must match a bridge surface; ground tricks stay below 1.2."
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
				var route_height := lerpf(float(route[i].get("height", 0)), float(route[(i + 1) % route.size()].get("height", 0)), float(sample_index) / maxf(1, ceili(length * 4)))
				if stunts.is_empty() and route_height > 1.2 and absf(route_height - bridge_surface_height(d, point)) > 0.06:
					return "Elevated skater segments must follow the bridge surface."
				var x := roundi(point.x)
				var y := roundi(point.y)
				for obstacle in d.objects:
					if obstacle.type == "city_prop" and obstacle.get("solid", false) and obstacle.get("variant") in CITY_PROPS and obstacle.variant not in ["skate_rail", "skate_ramp"] and Props.covers(obstacle, point, 0.42):
						return "Skater %s crosses solid prop %s." % [obj.id,obstacle.id]
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
		var columns: Variant = lane.get("columns", [1, int(d.width) - 2])
		if not columns is Array or columns.size() != 2 or not finite_number(columns[0]) or not finite_number(columns[1]) or columns[0] != int(columns[0]) or columns[1] != int(columns[1]) or columns[0] < 1 or columns[1] >= d.width - 1 or columns[1] - columns[0] < 3: return "Traffic columns need an ordered interior span of at least four whole cells."
		var jam: Variant = lane.get("jam", {})
		if not jam is Dictionary: return "Traffic jam timing must be an object."
		if not jam.is_empty():
			for key in ["stopped", "moving"]:
				if not finite_number(jam.get(key)) or jam[key] < 0.5 or jam[key] > 15: return "Traffic jam windows must last 0.5 to 15 seconds."
			if not finite_number(jam.get("phase", 0)) or jam.get("phase", 0) < 0 or jam.get("phase", 0) > 60: return "Traffic jam phase must be between 0 and 60 seconds."
		for x in range(int(columns[0]), int(columns[1]) + 1):
			if d.tiles[int(row)][x] != "road":
				return "A traffic lane needs a complete interior road row."
		for obj in d.objects:
			if absf(float(obj.pos[1]) - float(row)) < 0.85 and obj.pos[0] >= columns[0] - 0.5 and obj.pos[0] <= columns[1] + 0.5 and not (obj.type == "skater" and bridge_surface_height(d, Vector2(obj.pos[0], obj.pos[1])) >= 1.6):
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
