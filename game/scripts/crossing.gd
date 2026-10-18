extends Node3D
## Continuous, slow lane traffic and rideable logs; all motion stops with the world.
const Art = preload("res://scripts/art.gd")
var movers: Array = []
var world: Node3D
var checkpoint_claimed := false

func setup(data: Dictionary, owner_world: Node3D) -> void:
	world = owner_world
	for obj in data.objects:
		if obj.type not in ["car", "log"]:
			continue
		var node := Node3D.new()
		add_child(node)
		node.position = world.cell_position(obj.pos)
		var length: float = float(obj.get("length", 1.5)) * world.CELL
		if obj.type == "log":
			var trunk := Art.textured(Art.cylinder(node, 0.72, 0.72, length, Vector3(0, -0.56, 0), Color.WHITE, 8), "bark")
			trunk.rotation.z = PI / 2
			trunk.name = "RideableLog"
			for end in [-1, 1]:
				var ring := Art.cylinder(node, 0.71, 0.71, 0.04, Vector3(end * (length / 2 - 0.01), -0.56, 0), Color("d1b582"))
				ring.rotation.z = PI / 2
		else:
			var color := Color.from_string(str(obj.get("color", "dc925c")), Color("dc925c"))
			Art.box(node, Vector3(length, 0.45, 1.05), Vector3(0, 0.39, 0), color)
			Art.box(node, Vector3(length * 0.48, 0.38, 0.86), Vector3(0, 0.78, 0), color.lightened(0.2))
			Art.box(node, Vector3(length * 0.50, 0.25, 0.88), Vector3(0, 0.81, 0), Color("9dc5ca"))
			Art.box(node, Vector3(length * 0.38, 0.08, 0.92), Vector3(0, 1.00, 0), color)
			for side in [-1, 1]:
				for end in [-1, 1]:
					var wheel := Art.cylinder(node, 0.24, 0.24, 0.14, Vector3(end * length * 0.31, 0.24, side * 0.54), Color("24302e"))
					wheel.rotation.x = PI / 2
		var limit: float = (data.width - 2) * world.CELL / 2 + length / 2
		movers.append({"node": node, "kind": obj.type, "length": length, "speed": float(obj.get("speed", 1.0)) * float(obj.get("direction", 1)), "limit": limit, "previous": node.position, "wrapped": false})
	if not movers.is_empty():
		for entry in [["TRAFFIC · WAIT FOR A GAP", 19], ["RIDE THE LOGS", 15], ["CHECKPOINT · FINAL TRAFFIC", 10]]:
			if entry[1] >= data.height or not data.has("checkpoint"):
				continue
			var sign := Label3D.new()
			sign.text = entry[0]
			sign.position = world.cell_position([8, entry[1]]) + Vector3(0, 0.55, 0)
			sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			sign.font_size = 34
			sign.pixel_size = 0.008
			sign.modulate = Color("f3ecc8")
			add_child(sign)

func log_at(pos: Vector3, margin: float = 0.16) -> Dictionary:
	for mover in movers:
		if mover.kind == "log" and absf(pos.z - mover.node.position.z) <= world.CELL / 2 + 0.04 and absf(pos.x - mover.node.position.x) <= mover.length / 2 - margin:
			return mover
	return {}

func advance(delta: float, player: CharacterBody3D) -> void:
	var support := log_at(player.position)
	for mover in movers:
		mover.previous = mover.node.position
		mover.node.position.x += mover.speed * delta
		mover.wrapped = absf(mover.node.position.x) > mover.limit
		if mover.wrapped:
			mover.node.position.x = wrapf(mover.node.position.x, -mover.limit, mover.limit)
	if not support.is_empty():
		# Carry by the real displacement, never by the offscreen wrap teleport.
		player.move_and_collide(Vector3(support.speed * delta, 0, 0))

func traffic_hit(from: Vector3, to: Vector3) -> bool:
	for mover in movers:
		if mover.kind != "car":
			continue
		var start: Vector3 = from - (mover.node.position if mover.wrapped else mover.previous)
		var end: Vector3 = to - mover.node.position
		var half := Vector2(mover.length / 2 + 0.28, 0.53 + 0.28)
		if swept_box(Vector2(start.x, start.z), Vector2(end.x, end.z), half):
			return true
	return false

func swept_box(from: Vector2, to: Vector2, half: Vector2) -> bool:
	var first := 0.0
	var last := 1.0
	var motion := to - from
	for axis in range(2):
		if absf(motion[axis]) < 0.00001:
			if absf(from[axis]) > half[axis]:
				return false
		else:
			var a: float = (-half[axis] - from[axis]) / motion[axis]
			var b: float = (half[axis] - from[axis]) / motion[axis]
			first = maxf(first, minf(a, b))
			last = minf(last, maxf(a, b))
			if first > last:
				return false
	return true
