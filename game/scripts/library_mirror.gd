extends RefCounted
## Browser mirror protects a full Classic library across immediate navigation.
const KEY := "hopan.classic.library.mirror.v1"
const NYC_KEY := "hopan.nyc.library.mirror.v1"
const SCHEMA := "hopan.classic.library.v1"
const NYC_SCHEMA := "hopan.nyc.library.v1"
const ERROR_TEXT := "Saved levels have conflicting or unreadable backups. Export a backup and check storage before saving."
static func parse_json(text:String)->Variant:
	var j:=JSON.new()
	return j.data if j.parse(text)==OK else null
static func read_web(key:String)->Dictionary:
	var raw:Variant=JavaScriptBridge.eval("(function(){try{return JSON.stringify({ok:true,value:localStorage.getItem("+JSON.stringify(key)+")})}catch(e){return JSON.stringify({ok:false})}})()",true)
	var value:Variant=parse_json(str(raw))
	return value if value is Dictionary else {"ok":false}
static func put_web(key:String,payload:String,expected:Variant)->bool:
	# Compare and set in one synchronous browser call. A changed key indicates
	# another tab wrote a different library since this instance loaded.
	var expression:="(function(){try{const k="+JSON.stringify(key)+",expected="+JSON.stringify(expected)+";if(localStorage.getItem(k)!==expected)return 'conflict';localStorage.setItem(k,"+JSON.stringify(payload)+");return 'ok'}catch(e){return 'unavailable'}})()"
	return str(JavaScriptBridge.eval(expression,true))=="ok"
static func valid_generation(value:Variant,min_value:int=0)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=min_value and float(value)==floorf(float(value)) and float(value)<1000000000.0
static func nyc_decode(text:String)->Dictionary:
	var value:Variant=parse_json(text)
	if value is Array:return {"ok":true,"schema":NYC_SCHEMA,"generation":0,"entries":value}
	if value is Dictionary and value.get("schema")==NYC_SCHEMA and valid_generation(value.get("generation")) and value.get("entries") is Array:return {"ok":true,"schema":NYC_SCHEMA,"generation":value.generation,"entries":value.entries}
	return {"ok":false}
static func valid_classic(value:Variant)->bool:
	if not value is Dictionary or value.get("schema")!=SCHEMA or not value.get("entries") is Array or not valid_generation(value.get("generation"),1) or not value.get("accepted_disk_hashes") is Array:return false
	if value.accepted_disk_hashes.is_empty() or value.accepted_disk_hashes.size()>4096:return false
	for h in value.accepted_disk_hashes:
		if not h is String or (h!="absent" and h.length()!=64):return false
	return true
static func resolve(disk_exists:bool,disk_text:String,mirror_exists:bool,mirror_text:String)->Dictionary:
	var disk:Variant=parse_json(disk_text) if disk_exists else []
	if not disk is Array:return {"ok":false}
	if not mirror_exists:return {"ok":true,"entries":disk,"mirror":null,"used":false}
	var mirror:Variant=parse_json(mirror_text)
	if not valid_classic(mirror):return {"ok":false}
	var disk_hash:String=disk_text.sha256_text() if disk_exists else "absent"
	if disk_hash not in mirror.accepted_disk_hashes:return {"ok":false}
	return {"ok":true,"entries":mirror.entries,"mirror":mirror,"used":true}
static func unique_ids(entries:Array)->bool:
	var ids:Dictionary={}
	for entry in entries:
		if entry is Dictionary and entry.get("id") is String:
			var id:String=entry.id
			if ids.has(id):return false
			ids[id]=true
	return true
static func next_payload(entries:Array,disk_exists:bool,disk_text:String,prior:Variant)->String:
	var hashes:Array=[] if prior==null else prior.accepted_disk_hashes.duplicate()
	var current:String=disk_text.sha256_text() if disk_exists else "absent"
	var target:String=JSON.stringify(entries,"\t").sha256_text()
	for h in [current,target]:
		if h not in hashes:hashes.append(h)
	# Never silently discard old accepted hashes: inability to fit is a safe block.
	if hashes.size()>4096:return ""
	return JSON.stringify({"schema":SCHEMA,"generation":1 if prior==null else prior.generation+1,"entries":entries,"accepted_disk_hashes":hashes})
static func protect_nyc(path:String)->String:
	var lookup:=read_web(NYC_KEY)
	if not lookup.get("ok",false):return ERROR_TEXT
	var existing:Variant=lookup.get("value")
	var file_value:Dictionary={"ok":true}
	if FileAccess.file_exists(path):file_value=nyc_decode(FileAccess.get_file_as_string(path))
	if not file_value.get("ok",false):return ERROR_TEXT
	if existing!=null:
		var current:Dictionary=nyc_decode(str(existing))
		# Mirrors must be envelopes, never bare arrays.
		var parsed:Variant=parse_json(str(existing))
		if not current.get("ok",false) or not parsed is Dictionary:return ERROR_TEXT
		if file_value.has("generation") and current.generation==file_value.generation and current.entries!=file_value.entries:return ERROR_TEXT
		return ""
	if file_value.has("generation"):
		var payload:=JSON.stringify({"schema":NYC_SCHEMA,"generation":file_value.generation,"entries":file_value.entries})
		if not put_web(NYC_KEY,payload,null):return ERROR_TEXT
	return ""
