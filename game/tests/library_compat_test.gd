extends SceneTree
const Compat = preload("res://scripts/library_compat.gd")
const Data = preload("res://scripts/level_data.gd")
var checks := 0
var failures: Array[String] = []
var mirror: Variant = null
var allow_mirror := true
var fail_read := false
func mock_read() -> Dictionary:
	if fail_read:return {"ok":false,"error":"Browser save storage is unavailable."}
	return {"ok":true,"exists":mirror != null,"text":mirror if mirror != null else ""}
func mock_write(text: String, expected: Variant) -> Dictionary:
	if not allow_mirror or mirror != expected:return {"ok":false,"error":"Browser mirror unavailable or changed."}
	mirror=text;return {"ok":true}
func check(ok: bool, name: String) -> void:
	checks += 1
	if not ok:
		failures.append(name);push_error(name)
func put(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE);f.store_string(text);f.close()
func read(path: String) -> String:
	return FileAccess.get_file_as_string(path)
func _initialize() -> void:
	var primary := "user://nyc-library-test.json"
	var legacy := "user://classic-library-test.json"
	for p in [primary,legacy,primary+".pending"]:
		if FileAccess.file_exists(p):DirAccess.remove_absolute(p)
	var old_map := Data.blank("Earlier level");old_map.theme = "mexico"
	var nyc_map := Data.blank("NYC saved level", "nyc")
	var legacy_rows: Array = [{"id":"old","level":old_map,"extra":{"keep":true}},{"id":"nyc","level":nyc_map},"opaque",{"odd":1}]
	var source := JSON.stringify(legacy_rows)
	put(legacy, source)
	var loaded := Compat.load_library(Data.validate, Data.normalize, primary, legacy)
	check(loaded.writable and loaded.items.size() == 1 and loaded.items[0].id == "nyc", "Only compatible levels shown")
	check(read(legacy) == source and read(primary) == source, "Migration copies original bytes and never edits legacy")
	var edited: Array = loaded.items.duplicate(true);edited[0].level.name="Edited NYC"
	edited.append({"id":"fresh","level":Data.blank("New NYC", "nyc")})
	var saved := Compat.save_library(edited, Data.validate, Data.normalize, primary, legacy)
	var after: Array = JSON.parse_string(read(primary)).entries
	check(saved.ok and after.size() == 5, "Update and new save preserve every unknown record")
	check(JSON.stringify(after[0]) == JSON.stringify(JSON.parse_string(source)[0]) and after[2] == "opaque" and JSON.stringify(after[3]) == JSON.stringify(JSON.parse_string(source)[3]), "Unsupported legacy entries remain semantically exact")
	check(after[1].level.name == "Edited NYC" and after[4].id == "fresh", "Compatible edits persist")
	check(read(legacy) == source, "NYC saves never overwrite classic source")
	put(legacy, "[broken legacy]")
	check(Compat.load_library(Data.validate, Data.normalize, primary, legacy).items.size() == 2, "Existing NYC file remains usable independently of legacy")
	var baseline := read(primary)
	var conflict: Array = edited.duplicate(true);conflict.append({"id":"old","level":nyc_map})
	check(not Compat.save_library(conflict, Data.validate, Data.normalize, primary, legacy).ok and read(primary)==baseline, "Conflicting unsupported ID refuses overwrite")
	var duplicate: Array = edited.duplicate(true);duplicate.append(edited[0])
	check(not Compat.save_library(duplicate, Data.validate, Data.normalize, primary, legacy).ok and read(primary)==baseline, "Duplicate editor IDs refuse overwrite")
	put(primary, "{broken")
	var malformed := read(primary)
	check(not Compat.load_library(Data.validate, Data.normalize, primary, legacy).writable, "Malformed NYC file blocks writes")
	check(not Compat.save_library(edited, Data.validate, Data.normalize, primary, legacy).ok and read(primary)==malformed, "Malformed NYC file stays untouched")
	DirAccess.remove_absolute(primary)
	check(not Compat.load_library(Data.validate, Data.normalize, primary, legacy).writable and not FileAccess.file_exists(primary), "Malformed legacy is never migrated or replaced")
	# Simulate web localStorage synchronously; IndexedDB can lag behind it.
	for p in [primary, legacy, primary+".pending"]:
		if FileAccess.file_exists(p):DirAccess.remove_absolute(p)
	mirror=null;put(legacy,source)
	var browser := Compat.load_library(Data.validate, Data.normalize, primary, legacy, mock_read, mock_write)
	var base_file := read(primary);var first_mirror: Dictionary = JSON.parse_string(mirror)
	check(browser.writable and first_mirror.schema == Compat.SCHEMA and first_mirror.generation == 0 and first_mirror.entries.size() == 4, "First-entry mirror protects the complete legacy library")
	var newer: Array = browser.items.duplicate(true);newer.append({"id":"newer","level":Data.blank("Later NYC", "nyc")})
	check(Compat.save_library(newer, Data.validate, Data.normalize, primary, legacy, mock_read, mock_write).ok, "Synchronous mirror and isolated file accept a save")
	var newest_mirror: String = mirror
	check(JSON.parse_string(mirror).generation == 1 and JSON.parse_string(mirror).entries.size() == 5, "Mirror has monotonically newer complete records")
	put(primary,base_file) # Model a reload before IndexedDB has flushed the rename.
	var recovered := Compat.load_library(Data.validate, Data.normalize, primary, legacy, mock_read, mock_write)
	check(recovered.writable and recovered.source == Compat.MIRROR_KEY and recovered.items.size() == 2 and recovered.entries.size() == 5, "Newer mirror recovers full data over stale IndexedDB")
	check(Compat.save_library(recovered.items, Data.validate, Data.normalize, primary, legacy, mock_read, mock_write).ok and JSON.parse_string(mirror).generation == 2, "Recovery save advances generation without dropping unknown records")
	var stable_disk := read(primary);var stable_mirror: String = mirror
	allow_mirror=false
	check(not Compat.save_library(recovered.items, Data.validate, Data.normalize, primary, legacy, mock_read, mock_write).ok and read(primary) == stable_disk and mirror == stable_mirror, "Quota/access failure refuses to claim a save or alter disk")
	allow_mirror=true
	mirror=JSON.stringify({"schema":Compat.SCHEMA,"generation":3,"entries":[{"id":"other","level":nyc_map}]})
	var newer_remote := Compat.load_library(Data.validate, Data.normalize, primary, legacy, mock_read, mock_write)
	check(newer_remote.writable and newer_remote.source == Compat.MIRROR_KEY and newer_remote.generation == 3, "Higher-generation mirror wins over older file")
	put(primary,JSON.stringify({"schema":Compat.SCHEMA,"generation":4,"entries":[{"id":"disk","level":nyc_map}]}))
	var newer_disk := Compat.load_library(Data.validate, Data.normalize, primary, legacy, mock_read, mock_write)
	check(newer_disk.writable and newer_disk.source == primary and newer_disk.generation == 4, "Higher-generation disk wins over older mirror")
	mirror=JSON.stringify({"schema":Compat.SCHEMA,"generation":4,"entries":[{"id":"conflict","level":nyc_map}]})
	var conflict_disk := read(primary);var conflict_mirror: String = mirror
	check(not Compat.load_library(Data.validate, Data.normalize, primary, legacy, mock_read, mock_write).writable and read(primary)==conflict_disk and mirror==conflict_mirror, "Equal-generation divergent stores are blocked unchanged")
	mirror="not JSON"
	check(not Compat.load_library(Data.validate, Data.normalize, primary, legacy, mock_read, mock_write).writable and read(primary)==conflict_disk and mirror=="not JSON", "Corrupt mirror blocks writes without replacement")
	mirror=newest_mirror;put(primary,"bad JSON")
	check(not Compat.load_library(Data.validate, Data.normalize, primary, legacy, mock_read, mock_write).writable and read(primary)=="bad JSON" and mirror==newest_mirror, "Corrupt primary is not silently repaired by mirror")
	DirAccess.remove_absolute(primary)
	var missing := Compat.load_library(Data.validate, Data.normalize, primary, legacy, mock_read, mock_write)
	check(missing.writable and missing.source == Compat.MIRROR_KEY and missing.items.size() == 2, "Valid mirror recovers when IndexedDB primary is missing")
	fail_read=true
	check(not Compat.load_library(Data.validate, Data.normalize, primary, legacy, mock_read, mock_write).writable, "Unavailable browser storage blocks unsafe save")
	fail_read=false
	for p in [primary,legacy,primary+".pending"]:
		if FileAccess.file_exists(p):DirAccess.remove_absolute(p)
	print(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
