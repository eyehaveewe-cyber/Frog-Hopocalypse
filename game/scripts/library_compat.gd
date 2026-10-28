extends RefCounted
## Separate NYC saves and preserve unknown entries. A web mirror survives an
## immediate navigation while Godot's IndexedDB filesystem is still syncing.
const NYC_PATH := "user://nyc-library.json"
const LEGACY_PATH := "user://library.json"
const MIRROR_KEY := "hopan.nyc.library.mirror.v1"
const SCHEMA := "hopan.nyc.library.v1"

static func _parse(text: String, label: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return {"ok": false, "error": label + " is unreadable. It was left unchanged; export JSON for a backup."}
	var data: Variant = parser.data
	var entries: Array
	var generation := 0
	if data is Array:
		entries = data
	elif data is Dictionary and data.get("schema") == SCHEMA and data.get("entries") is Array and (data.get("generation") is int or data.get("generation") is float) and is_finite(float(data.generation)) and float(data.generation) >= 0 and float(data.generation) == floorf(float(data.generation)) and float(data.generation) <= 9007199254740990.0:
		entries = data.entries;generation = int(data.generation)
	else:
		return {"ok": false, "error": label + " has an unknown format. It was left unchanged; export JSON for a backup."}
	return {"ok": true, "exists": true, "text": text, "entries": entries, "generation": generation}

static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": true, "exists": false, "text": "", "entries": [], "generation": 0}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not read local library; export JSON before changing it."}
	var text := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error != OK and read_error != ERR_FILE_EOF:
		return {"ok": false, "error": "Could not read local library; export JSON before changing it."}
	return _parse(text, "Local library")

static func _mirror_read(reader: Callable) -> Dictionary:
	if reader.is_valid():return reader.call()
	if not OS.has_feature("web"):return {"ok": true, "exists": false, "text": ""}
	var response: Variant = JavaScriptBridge.eval("(function(){try{const s=localStorage.getItem("+JSON.stringify(MIRROR_KEY)+");return JSON.stringify({ok:true,exists:s!==null,text:s||''});}catch(e){return JSON.stringify({ok:false,error:'Browser save storage is unavailable. Export JSON for a backup.'});}})()", true)
	var parsed: Variant = JSON.parse_string(str(response))
	return parsed if parsed is Dictionary else {"ok": false, "error": "Browser save storage is unavailable. Export JSON for a backup."}

static func _mirror_write(text: String, expected: Variant, writer: Callable) -> Dictionary:
	if writer.is_valid():return writer.call(text, expected)
	if not OS.has_feature("web"):return {"ok": true}
	# Synchronous compare-and-set prevents a stale tab overwriting a newer mirror.
	var script := "(function(){try{const k="+JSON.stringify(MIRROR_KEY)+",e="+JSON.stringify(expected)+";if(localStorage.getItem(k)!==e)return 'conflict';localStorage.setItem(k,"+JSON.stringify(text)+");return 'ok';}catch(e){return 'unavailable';}})()"
	var result: Variant = JavaScriptBridge.eval(script, true)
	if result == "ok":return {"ok": true}
	return {"ok": false, "error": "Browser save changed in another tab or storage is unavailable. The library was not changed; export JSON for a backup."}

static func _write(path: String, text: String) -> Dictionary:
	var pending := path + ".pending"
	var file := FileAccess.open(pending, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Local save failed. Export JSON to keep a portable copy."}
	file.store_string(text)
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(pending)
		return {"ok": false, "error": "Could not write local save. Export JSON for a backup."}
	if DirAccess.rename_absolute(pending, path) != OK:
		DirAccess.remove_absolute(pending)
		return {"ok": false, "error": "Could not finish local save. Export JSON for a backup."}
	return {"ok": true, "error": ""}

static func _valid_item(item: Variant, validate: Callable) -> bool:
	return item is Dictionary and item.get("id") is String and not item.id.is_empty() and validate.call(item.get("level")) == ""

static func _envelope(entries: Array, generation: int) -> String:
	return JSON.stringify({"schema": SCHEMA, "generation": generation, "entries": entries}, "\t")

static func load_library(validate: Callable, normalize: Callable, primary: String = NYC_PATH, legacy: String = LEGACY_PATH, mirror_reader: Callable = Callable(), mirror_writer: Callable = Callable()) -> Dictionary:
	var disk := _read(primary)
	if not disk.ok:return {"items": [], "writable": false, "error": disk.error, "source": primary}
	var raw_mirror := _mirror_read(mirror_reader)
	if not raw_mirror.ok:return {"items": [], "writable": false, "error": raw_mirror.error, "source": MIRROR_KEY}
	var mirror := {"ok": true, "exists": false, "text": "", "entries": [], "generation": 0}
	if raw_mirror.exists:
		mirror = _parse(raw_mirror.text, "Browser save mirror")
		# Mirror must always be an envelope; raw arrays are for legacy disk only.
		if not mirror.ok or not raw_mirror.text.strip_edges().begins_with("{"):
			return {"items": [], "writable": false, "error": mirror.get("error", "Browser save mirror has an unknown format."), "source": MIRROR_KEY}
	var chosen: Dictionary = disk
	var source := primary
	if mirror.exists and (not disk.exists or mirror.generation > disk.generation):
		chosen = mirror;source = MIRROR_KEY
	elif disk.exists and mirror.exists and disk.generation == mirror.generation and JSON.stringify(disk.entries) != JSON.stringify(mirror.entries):
		return {"items": [], "writable": false, "error": "Local saves disagree at the same generation. Neither copy was changed; export JSON for a backup.", "source": primary}
	if not chosen.exists:
		chosen = _read(legacy);source = legacy
		if not chosen.ok:return {"items": [], "writable": false, "error": chosen.error, "source": legacy}
		if chosen.exists:
			# Synchronous durable copy exists before the classic runtime can
			# subsequently change its own library. Legacy stays byte-identical.
			var mirrored := _mirror_write(_envelope(chosen.entries, chosen.generation), null, mirror_writer)
			if not mirrored.ok:return {"items": [], "writable": false, "error": mirrored.error, "source": legacy}
			if FileAccess.file_exists(primary):return load_library(validate, normalize, primary, legacy, mirror_reader, mirror_writer)
			var copied := _write(primary, chosen.text)
			if not copied.ok:return {"items": [], "writable": false, "error": copied.error, "source": legacy}
			raw_mirror = _mirror_read(mirror_reader)
			if not raw_mirror.ok:return {"items": [], "writable": false, "error": raw_mirror.error, "source": MIRROR_KEY}
	var items: Array = []
	for item in chosen.entries:
		if _valid_item(item, validate):items.append(normalize.call(item))
	return {"items": items, "entries": chosen.entries, "generation": chosen.generation, "mirror_expected": raw_mirror.text if raw_mirror.exists else null, "writable": true, "error": "", "source": source}

static func save_library(items: Array, validate: Callable, normalize: Callable, primary: String = NYC_PATH, legacy: String = LEGACY_PATH, mirror_reader: Callable = Callable(), mirror_writer: Callable = Callable()) -> Dictionary:
	var state := load_library(validate, normalize, primary, legacy, mirror_reader, mirror_writer)
	if not state.writable:return {"ok": false, "error": state.error}
	var edits := {}
	for item in items:
		if not _valid_item(item, validate) or edits.has(item.id):return {"ok": false, "error": "Duplicate or invalid local level; the library was not changed. Export JSON for a backup."}
		edits[item.id] = item
	var seen := {}
	var merged: Array = []
	for item in state.entries:
		if item is Dictionary and item.get("id") is String:
			if seen.has(item.id):return {"ok": false, "error": "Duplicate local level IDs; the library was not changed. Export JSON for a backup."}
			seen[item.id] = true
			if edits.has(item.id):
				if not _valid_item(item, validate):return {"ok": false, "error": "A saved level ID conflicts with older data. The library was not changed."}
				merged.append(edits[item.id]);edits.erase(item.id);continue
		merged.append(item)
	for id in edits:merged.append(edits[id])
	var text := _envelope(merged, state.generation + 1)
	var mirrored := _mirror_write(text, state.mirror_expected, mirror_writer)
	if not mirrored.ok:return mirrored
	return _write(primary, text)
