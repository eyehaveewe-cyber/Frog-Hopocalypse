extends SceneTree
const Safety=preload("res://scripts/library_safety.gd")
var checks:=0
var failures:Array[String]=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func put(path:String,value:String)->void:
	var f:=FileAccess.open(path,FileAccess.WRITE);f.store_string(value);f.close()
func clear(path:String)->void:
	if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):DirAccess.remove_absolute(path)
func _initialize()->void:call_deferred("run")
func run()->void:
	var old:="user://library.json";var nyc:="user://nyc-library.json"
	clear(old);clear(nyc)
	check(Safety.protect(old,nyc)=="" and not FileAccess.file_exists(nyc),"Empty install creates no phantom NYC library")
	var source:="[\n  {\"id\": \"old\", \"level\": {\"name\": \"café\"}},\n  {\"id\": \"nyc\", \"level\": {\"theme\": \"nyc\"}}\n]\n"
	put(old,source)
	check(Safety.protect(old,nyc)=="" and FileAccess.get_file_as_string(nyc)==source,"First classic entry copies every valid-array byte, including unsupported NYC records")
	check(FileAccess.get_file_as_string(old)==source,"Migration never changes legacy source")
	put(old,"[ {\"id\":\"new legacy\"} ]")
	check(Safety.protect(old,nyc)=="" and FileAccess.get_file_as_string(nyc)==source,"Existing NYC library is never overwritten")
	put(old,"{bad json")
	check(not Safety.protect(old,nyc).is_empty() and FileAccess.get_file_as_string(nyc)==source,"Malformed legacy blocks classic writes even when NYC library exists")
	clear(nyc)
	check(not Safety.protect(old,nyc).is_empty() and not FileAccess.file_exists(nyc),"Malformed legacy cannot produce a migration copy")
	put(old,"{\"not\":\"an array\"}")
	check(not Safety.protect(old,nyc).is_empty(),"Non-array JSON blocks writes")
	put(old,source)
	check(not Safety.protect(old,"user://absent-folder/nyc-library.json").is_empty() and FileAccess.get_file_as_string(old)==source,"Copy failure blocks writes without changing legacy bytes")
	DirAccess.make_dir_absolute(nyc)
	check(not Safety.protect(old,nyc).is_empty(),"A destination directory is treated as a copy failure")
	var g=load("res://main.tscn").instantiate();root.add_child(g);current_scene=g
	await process_frame
	check(not g.library_safety_error.is_empty(),"Actual game exposes the safety error")
	check(not g.save_level() and not g.save_editor_checkpoint(),"Actual game blocks manual and automatic library writes")
	check(FileAccess.get_file_as_string(old)==source,"Blocked actual game saves leave full legacy file unchanged")
	g.queue_free();await process_frame;clear(nyc)
	put(old,"{bad json");put(nyc,source)
	var h=load("res://main.tscn").instantiate();root.add_child(h);current_scene=h
	await process_frame
	check(not h.library_safety_error.is_empty(),"Actual game surfaces malformed legacy even when NYC copy already exists")
	check(not h.save_level() and not h.save_editor_checkpoint(),"Malformed source blocks both write paths")
	check(FileAccess.get_file_as_string(old)=="{bad json" and FileAccess.get_file_as_string(nyc)==source,"Malformed source and existing NYC copy stay byte-identical")
	h.queue_free();await process_frame;clear(nyc);clear(old)
	put(old,source)
	var safe=load("res://main.tscn").instantiate();root.add_child(safe);current_scene=safe
	await process_frame
	check(safe.library_opaque.size()==2,"Classic retains both unsupported legacy records in memory")
	check(safe.save_level(),"Actual manual save succeeds with unsupported records present")
	var after:Variant=JSON.parse_string(FileAccess.get_file_as_string(old))
	check(after is Array and after.size()==3 and after[0].id=="old" and after[1].id=="nyc","Manual save retains all unsupported records")
	var duplicate_candidate:Array=safe.library.duplicate(true);duplicate_candidate.append({"id":"nyc","level":{"name":"duplicate"}})
	var before_duplicate:=FileAccess.get_file_as_string(old)
	check(not safe.commit_library_candidate(duplicate_candidate) and FileAccess.get_file_as_string(old)==before_duplicate,"Actual save refuses duplicate opaque/supported IDs without changing disk")
	safe.library_safety_error=""
	check(safe.save_editor_checkpoint()==false,"Autosave without an editor identity is rejected safely")
	safe.level.editor_autosave_id="test_preservation"
	check(safe.save_editor_checkpoint(),"Actual Classic editor autosave succeeds")
	var after_auto:Variant=JSON.parse_string(FileAccess.get_file_as_string(old))
	check(after_auto is Array and after_auto.size()==4 and after_auto[1].id=="nyc","Autosave retains unsupported NYC record")
	safe.queue_free();await process_frame;clear(nyc);clear(old)
	print(JSON.stringify({"checks":checks,"failures":failures,"scope":"Actual on-disk migration, malformed input, destination failure and game manual/autosave guards; isolated test profile."}));quit(0 if failures.is_empty() else 1)
