extends RefCounted
## Ground collision envelopes in world units. Art-only trim is excluded.
const FOOTPRINTS = {
	"bench": Vector2(1.45, 0.65), "trash_can": Vector2(0.7, 0.7),
	"dumpster": Vector2(1.35, 1.15), "pizza_cart": Vector2(1.25, 1.1),
	"mailbox": Vector2(0.7, 0.7), "traffic_cone": Vector2(0.48, 0.48),
	"manhole": Vector2(0.85, 0.85), "newsstand": Vector2(1.4, 1.2),
	"skate_rail": Vector2(0.2, 4.0), "skate_ramp": Vector2(1.4, 4.0)
}

static func footprint(obj: Dictionary) -> Vector2:
	var result: Vector2 = FOOTPRINTS[obj.variant]
	if obj.variant in ["skate_rail", "skate_ramp"]:
		result.y = float(obj.get("length", 4.0))
	return result

static func covers(obj: Dictionary, grid_point: Vector2, margin: float = 0.32) -> bool:
	var local := ((grid_point - Vector2(obj.pos[0], obj.pos[1])) * 1.8).rotated(deg_to_rad(float(obj.get("rotation", 0))))
	var half := footprint(obj) * 0.5 + Vector2.ONE * margin
	return absf(local.x) < half.x and absf(local.y) < half.y
