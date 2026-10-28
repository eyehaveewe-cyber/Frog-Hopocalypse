extends RefCounted
## Original 32x32 texture kit, authored as deterministic pixels. No borrowed art.
static var cache: Dictionary = {}

static func get_texture(kind: String) -> Texture2D:
	if cache.has(kind):
		return cache[kind]
	var image := Image.create(32, 32, false, Image.FORMAT_RGB8)
	var random := RandomNumberGenerator.new()
	random.seed = hash(kind)
	var base_kind := kind.get_slice("@", 0).trim_suffix("_wall")
	for y in range(32):
		for x in range(32):
			var n := random.randf()
			if base_kind in ["leaf", "violet_leaf", "bark", "jungle_leaf", "jungle_bark", "jungle_ground", "jungle_stone"]:
				# Broad static clusters avoid one-pixel speckle while moving the camera.
				n = float(posmod(hash([kind, x / 4, y / 4]), 1000)) / 1000.0
			var color := Color.WHITE
			match base_kind:
				"asphalt":
					color = Color("263344").lerp(Color("455366"), n * 0.6)
					if n > 0.96:
						color = Color("65727d")
				"concrete", "city_pavers":
					var seam := x % 16 == 0 or y % 16 == 0
					color = Color("637885") if seam else Color("a4b4bd").lerp(Color("d4d5c6"), n * 0.5)
					if kind == "city_pavers":
						color = Color("647971") if x % 8 == 0 or y % 8 == 0 else Color("a3b7a2").lerp(Color("c7c8b3"), n * 0.5)
				"jungle_ground":
					color = Color("50624a").lerp(Color("78805c"),n*0.65)
				"jungle_leaf":
					color = Color("44694e").lerp(Color("819451"),n*0.7)
				"jungle_bark":
					color = Color("737556").lerp(Color("959371"),n*0.5)
				"jungle_stone":
					var seam := y % 16 < 2 or (x + (8 if y >= 16 else 0)) % 16 < 2
					color = Color("777f70") if seam else Color("9fa78c").lerp(Color("b7b7a0"),n*0.35)
					# Wide vine clusters, rather than high-frequency dark speckles.
					if (x / 4 + y / 8) % 7 < 2: color = Color("667b56").lerp(Color("889263"),n*0.45)
				"stucco":
					# Broad, low-contrast patches; no fine dark mortar grid.
					var patch := float(posmod(hash([x / 4,y / 4]),100)) / 100.0
					color = Color("e5b788").lerp(Color("efd6aa"),patch*0.35)
					if y >= 24: color = Color("57959b").lerp(Color("6fa7a7"),patch*0.3)
				"terracotta":
					var seam := x % 16 < 2 or y % 16 < 2
					color = Color("ad775b") if seam else Color("c58b68").lerp(Color("d5a27c"),n*0.25)
				"plaza":
					var seam := x % 16 < 2 or y % 16 < 2
					color = Color("aaa38b") if seam else Color("d1c5a5").lerp(Color("e3d8b8"),n*0.25)
				"cactus":
					color = Color("a3bca0") if x % 8 < 2 else Color("c3d0b6")
				"cheese":
					color = Color("f4c94a").lerp(Color("ffe28b"), n * 0.4)
					for hole in [Vector3(7, 8, 4), Vector3(23, 6, 3), Vector3(18, 23, 5), Vector3(3, 27, 3)]:
						var distance := Vector2(x - hole.x, y - hole.y).length()
						if distance < hole.z:
							color = Color("9b661d") if distance < hole.z - 1 else Color("d49b2d")
				"road":
					color = Color("343d48").lerp(Color("535c64"), n * 0.5)
					if y < 2 and x < 20:
						color = Color("e5dbae")
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
					if base_kind == "stone":
						color = Color("6a5947") if mortar else Color("a08b65").lerp(Color("ddc397"), n * 0.7)
					else:
						color = Color("403b55") if mortar else Color("70627f").lerp(Color("a99ca6"), n * 0.55)
				"brick":
					var row_id := y / 8
					var mortar := y % 8 == 0 or (x + (8 if row_id % 2 == 0 else 0)) % 16 == 0
					# Muted mortar avoids a sharp light/dark grid at grazing angles.
					color = Color("9b786a") if mortar else Color("a57262").lerp(Color("b58170"), n * 0.45)
				"water", "swamp_water":
					var wave := sin(float(x) * 0.6 + sin(float(y) * 0.4) * 2.2) + cos(float(y) * 0.67 + sin(float(x) * 0.3))
					var base := Color("187c9d") if base_kind == "water" else Color("43406e")
					var light := Color("a8e5da") if base_kind == "water" else Color("a095bd")
					color = base.lerp(light, 0.8 if absf(wave) < 0.18 else (0.35 if absf(wave) < 0.4 else n * 0.14))
				"bark":
					color = Color("68523e").lerp(Color("b6a078"), n * 0.65)
					if y % 5 == 0:
						color = color.darkened(0.3)
				"leaf", "violet_leaf":
					var stripe := n > 0.57
					color = Color("8b9e53") if stripe else Color("658346")
					if base_kind == "violet_leaf":
						color = Color("a583ae") if stripe else Color("81658f")
				"frog_purple":
					color = Color("9970bd").lerp(Color("bea0d8"), n * 0.5)
					if n < 0.12:
						color = Color("78558e")
				"frog":
					color = Color("87ae4c").lerp(Color("d1d772"), n * 0.5)
					if n < 0.12:
						color = Color("546e36")
			if kind.ends_with("_wall") and base_kind not in ["stucco", "terracotta", "jungle_stone"]:
				color = color.lerp(Color("b6a080") if base_kind == "stone" else Color("95859b"),0.4)
			image.set_pixel(x, y, color)
	if base_kind == "brick" or kind.ends_with("_wall"):
		image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	cache[kind] = texture
	return texture
