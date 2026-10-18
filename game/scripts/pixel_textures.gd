extends RefCounted
## Original 32x32 texture kit, authored as deterministic pixels. No borrowed art.
static var cache: Dictionary = {}

static func get_texture(kind: String) -> Texture2D:
	if cache.has(kind):
		return cache[kind]
	var image := Image.create(32, 32, false, Image.FORMAT_RGB8)
	var random := RandomNumberGenerator.new()
	random.seed = hash(kind)
	for y in range(32):
		for x in range(32):
			var n := random.randf()
			var color := Color.WHITE
			match kind:
				"grass":
					color = Color("5e8933").lerp(Color("a0ac48"), n * 0.65)
					if n < 0.16:
						color = Color("3f662d")
					if n > 0.92:
						color = Color("b5bc61")
				"moss":
					color = Color("384d43").lerp(Color("82915e"), n)
				"stone", "swamp_stone":
					var mortar := y % 8 == 0 or (x + (8 if (y / 8) % 2 == 0 else 0)) % 16 == 0
					if kind == "stone":
						color = Color("6a5947") if mortar else Color("a08b65").lerp(Color("ddc397"), n * 0.7)
					else:
						color = Color("403b55") if mortar else Color("70627f").lerp(Color("a99ca6"), n * 0.55)
				"brick":
					var row_id := y / 8
					var mortar := y % 8 == 0 or (x + (8 if row_id % 2 == 0 else 0)) % 16 == 0
					color = Color("bbaa8b") if mortar else Color("854d43").lerp(Color("c58563"), n * 0.65)
					if not mortar and y % 8 == 1:
						color = color.lightened(0.14)
				"water", "swamp_water":
					var wave := sin(float(x) * 0.6 + sin(float(y) * 0.4) * 2.2) + cos(float(y) * 0.67 + sin(float(x) * 0.3))
					var base := Color("187c9d") if kind == "water" else Color("43406e")
					var light := Color("a8e5da") if kind == "water" else Color("a095bd")
					color = base.lerp(light, 0.8 if absf(wave) < 0.18 else (0.35 if absf(wave) < 0.4 else n * 0.14))
				"bark":
					color = Color("68523e").lerp(Color("b6a078"), n * 0.65)
					if y % 5 == 0:
						color = color.darkened(0.3)
				"leaf", "violet_leaf":
					var stripe := (x + y * 2) % 7 < 2
					color = Color("9fb951") if stripe else Color("476a32")
					if kind == "violet_leaf":
						color = Color("bb83c0") if stripe else Color("684b85")
				"frog":
					color = Color("87ae4c").lerp(Color("d1d772"), n * 0.5)
					if n < 0.12:
						color = Color("546e36")
			image.set_pixel(x, y, color)
	var texture := ImageTexture.create_from_image(image)
	cache[kind] = texture
	return texture
