extends RefCounted
## Automatic visual portals for full-width continuous lanes. No simulation state.
const Art = preload("res://scripts/art.gd")

static func plan(level: Dictionary, cell: float) -> Array:
	var result: Array = []
	# Grid movers reverse at terrain ends instead of wrapping offscreen.
	if level.get("game_mode", "hopan") == "tile": return result
	var rows: Dictionary = {}
	for obj in level.objects:
		if obj.type not in ["car", "log"]: continue
		var y := int(obj.pos[1])
		var terrain := "water" if obj.type == "log" else "road"
		var clear := true
		for x in range(1, int(level.width)-1):
			if level.tiles[y][x] != terrain: clear = false
		for x in [0, int(level.width)-1]:
			# Never decorate over a deliberately authored playable border cell.
			if level.tiles[y][x] != "wall": clear = false
			if level.objects.any(func(other): return int(other.pos[0]) == x and int(other.pos[1]) == y): clear = false
		if not clear: continue
		var length: float = float(obj.get("length",1.5)) * cell
		if not rows.has(y): rows[y] = {"row":y,"terrain":terrain,"length":length}
		else: rows[y].length = maxf(rows[y].length,length)
	for y in rows:
		var lane: Dictionary = rows[y]
		# Mouth is exactly at the outer edge of the first/last interior cell.
		# Cover the entire wrap seam, including the longest vehicle/log's tail.
		var inner := (float(level.width)-2)*cell/2
		var depth: float = lane.length + cell
		for side in [-1,1]:
			result.append({"row":y,"terrain":lane.terrain,"side":side,"inner":inner,
				"depth":depth,"x":side*(inner+depth/2),"z":(y-(float(level.height)-1)/2)*cell,"cell":cell})
	return result

static func border_terrain(plans: Array, x: int, y: int, width: int) -> String:
	if x != 0 and x != width-1: return ""
	for p in plans:
		if p.row == y: return p.terrain
	return ""

static func build(parent: Node3D, plans: Array, theme_name: String) -> void:
	var texture: String = {"egypt":"stone_wall","swamp":"swamp_stone_wall","mexico":"stucco_wall","honduras":"jungle_stone_wall"}.get(theme_name,"stone_wall")
	for p in plans:
		var root := Node3D.new()
		root.name = "LaneTunnel_%d_%s" % [p.row,"west" if p.side < 0 else "east"]
		root.position = Vector3(p.x,0,p.z)
		root.set_meta("lane_tunnel",p)
		parent.add_child(root)
		var width: float = p.cell
		for side in [-1,1]:
			Art.textured(Art.box(root,Vector3(p.depth,1.40,0.14),Vector3(0,0.70,side*(width/2-0.07)),Color.WHITE),texture)
		Art.textured(Art.box(root,Vector3(p.depth,0.22,width),Vector3(0,1.51,0),Color.WHITE),texture)
		# Thick opening trim establishes depth without a black billboard or back
		# wall that would obscure a mover before it reaches the actual wrap seam.
		var face_x: float = -p.side*(p.depth/2-0.10)
		Art.textured(Art.box(root,Vector3(0.20,0.14,width+0.10),Vector3(face_x,1.39,0),Color.WHITE),texture)
		if p.terrain == "road":
			Art.textured(Art.box(root,Vector3(p.depth,0.18,width-0.28),Vector3(0,-0.06,0),Color.WHITE),"road")
