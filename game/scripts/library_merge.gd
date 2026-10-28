extends RefCounted
## Import both former editors into one library without overwriting either version.
static func merge(existing: Array, incoming: Array) -> Array:
	var result := existing.duplicate(true)
	for item in incoming:
		var same := result.filter(func(other): return other.id == item.id)
		if same.is_empty():
			result.append(item.duplicate(true))
		elif same[0].level != item.level:
			var copy: Dictionary = item.duplicate(true)
			copy.id = "nyc_import_" + str(item.id).sha256_text().left(20)
			if not result.any(func(other): return other.id == copy.id):
				result.append(copy)
	return result
