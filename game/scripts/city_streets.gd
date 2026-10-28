extends RefCounted
## Street markings are geometry, so they stay sharp in the overhead editor.
const Art = preload("res://scripts/art.gd")
const CELL := 1.8

static func road(root: Node3D, p: Vector3, column: int, crossing: bool) -> void:
	if crossing:
		for stripe in range(5):
			Art.box(root, Vector3(0.95, 0.014, 0.15), p + Vector3(0, 0.012, -0.68 + stripe * 0.34), Color("e3dfca"))
	elif column % 2 == 0:
		Art.box(root, Vector3(0.65, 0.012, 0.065), p + Vector3(0, 0.011, -0.82), Color("e7bd58"))
	# Drain grates are flush to the tarmac, outside the crossing envelope.
	if column % 7 == 0:
		Art.box(root, Vector3(0.4, 0.012, 0.3), p + Vector3(0.45, 0.012, 0.52), Color("171f2c"))
		for slot in range(4):
			Art.box(root, Vector3(0.025, 0.016, 0.22), p + Vector3(0.3 + slot * 0.09, 0.014, 0.52), Color("6b7985"))

static func sidewalk_edge(root: Node3D, p: Vector3, side: float, crossing: bool) -> void:
	Art.box(root, Vector3(CELL, 0.12, 0.12), p + Vector3(0, 0.02, side * 0.83), Color("bbc3c5"))
	if crossing:
		# Tactile paving identifies waiting pockets; it never implies cars stop.
		Art.box(root, Vector3(1.05, 0.016, 0.26), p + Vector3(0, 0.025, side * 0.59), Color("d9ab45"))

static func signs(root: Node3D, level: Dictionary) -> void:
	for lane in level.get("traffic", []):
		# Off-map approach decks keep wrapping cars on asphalt. The far ends
		# disappear into tunnel mouths rather than popping over open water.
		var road_z := (float(lane.row) - (float(level.height) - 1) * 0.5) * CELL
		for side in [-1, 1]:
			var map_edge := float(level.width) * CELL * 0.5
			var mouth_x: float = side * (map_edge + 5.6)
			Art.textured(Art.box(root, Vector3(8.0, 0.2, CELL), Vector3(side * (map_edge + 3.7), -0.1, road_z), Color.WHITE), "asphalt")
			for verge in [-1, 1]:
				Art.box(root, Vector3(8.0, 0.20, 0.10), Vector3(side * (map_edge + 3.7), 0.08, road_z + verge * 0.85), Color("647586"))
				Art.box(root, Vector3(3.6, 2.0, 0.15), Vector3(mouth_x, 1.0, road_z + verge * 0.85), Color("3d4659"))
			Art.box(root, Vector3(3.6, 0.25, CELL), Vector3(mouth_x, 2.1, road_z), Color("59677b"))
		# Along the side perimeter only. Poles do not obscure the play corridor.
		var z := (float(lane.row) - (float(level.height) - 1) * 0.5) * CELL
		for side in [-1, 1]:
			var x: float = side * ((float(level.width) - 1) * CELL * 0.5 + 0.15)
			Art.cylinder(root, 0.045, 0.045, 2.4, Vector3(x, 1.2, z), Color("465368"))
			Art.box(root, Vector3(0.3, 0.68, 0.22), Vector3(x, 2.24, z), Color("d5a134"))
			for light in range(3):
				var lamp := Art.orb(root, Vector3(0.15, 0.15, 0.12), Vector3(x, 2.44 - light * 0.2, z + 0.12), Color("244c43") if light != 2 else Color("74efb1"))
				if light == 2:
					lamp.material_override = Art.mat(Color("74efb1"), 0.65)
	# A broad readable arrival placard ties the final map to its skyline.
	var sign := Label3D.new()
	sign.text = level.get("district", "NEW YORK CITY")
	sign.font_size = 54
	sign.pixel_size = 0.014
	sign.position = Vector3(0, 3.0, -float(level.height) * CELL * 0.5 - 1)
	sign.modulate = Color("aee4d9")
	root.add_child(sign)
