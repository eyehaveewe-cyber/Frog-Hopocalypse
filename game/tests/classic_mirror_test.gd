extends SceneTree
const M=preload("res://scripts/library_mirror.gd")
var n:=0
var failures:Array[String]=[]
func check(ok:bool,label:String)->void:
	n+=1
	if not ok:failures.append(label);push_error(label)
func _initialize()->void:
	var unknown:={"id":"foreign","level":{"theme":"nyc","objects":[{"type":"skater"}]}}
	var original:Array=[unknown,{"id":"legacy","level":{"theme":"swamp"}}]
	var disk:=JSON.stringify(original,"\t")
	var payload:String=M.next_payload(original,true,disk,null)
	var obj:Variant=M.parse_json(payload)
	check(M.valid_classic(obj),"Fresh mirror envelope validates after JSON round trip")
	check(M.resolve(true,disk,true,payload).entries==original,"First mirror retains unsupported full records")
	var newer:Array=original.duplicate(true);newer.append({"id":"new","level":{"theme":"egypt"}})
	var second:=M.next_payload(newer,true,disk,obj);var prior_disk_recovery:=M.resolve(true,disk,true,second)
	check(prior_disk_recovery.get("ok",false) and prior_disk_recovery.entries==newer,"Immediate reload recovers newer synchronous mirror over old disk")
	var updated:=JSON.stringify(newer,"\t")
	check(M.resolve(true,updated,true,second).entries==newer,"Synced disk and mirror agree")
	check(not M.resolve(true,'[{"id":"unrelated"}]',true,second).get("ok",false),"Unrelated disk update is a conflict, never overwritten")
	check(not M.resolve(true,'{broken',true,second).get("ok",false),"Malformed disk is rejected")
	check(not M.resolve(true,disk,true,'{broken').get("ok",false),"Malformed mirror is rejected")
	check(not M.resolve(true,disk,true,JSON.stringify({"schema":M.SCHEMA,"generation":0,"entries":original,"accepted_disk_hashes":[]})).get("ok",false),"Invalid generation and empty lineage rejected")
	var nyc:=M.nyc_decode(JSON.stringify({"schema":M.NYC_SCHEMA,"generation":3,"entries":original}))
	check(nyc.get("ok",false) and nyc.generation==3 and nyc.entries==original,"NYC envelope keeps its full data and generation")
	check(M.nyc_decode(disk).get("ok",false) and M.nyc_decode(disk).generation==0,"NYC plain legacy array has generation zero")
	check(not M.nyc_decode('{broken').get("ok",false),"Invalid NYC source is rejected")
	var many:Dictionary=obj.duplicate(true);many.accepted_disk_hashes=[]
	for i in 4096:many.accepted_disk_hashes.append(("hash_"+str(i)).sha256_text())
	check(M.next_payload(original,true,disk,many).is_empty(),"Lineage overflow blocks writes instead of dropping recovery history")
	check(not M.unique_ids([{"id":"duplicate"},{"id":"duplicate"}]),"Duplicate IDs block overwrite even across supported and opaque rows")
	check(M.unique_ids([{"id":"one"},{"id":"two"},{"unknown":"retained"}]),"Distinct and opaque non-ID rows remain preservable")
	print(JSON.stringify({"checks":n,"failures":failures,"scope":"Pure Classic mirror and NYC envelope resolution with stale, conflict and invalid cases"}));quit(0 if failures.is_empty() else 1)
