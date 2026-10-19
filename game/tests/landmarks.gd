extends SceneTree
const Data=preload("res://scripts/level_data.gd")
const Models=preload("res://scripts/landmark_models.gd")
const Suite=preload("res://tests/integration.gd")
var suite=Suite.new()
var app: Control
var metrics: Array=[]
func _initialize() -> void:
 app=preload("res://main.tscn").instantiate()
 app.rule_notices_enabled=false
 root.add_child(app)
 call_deferred("run")
func run() -> void:
 await process_frame
 app.set_process(false)
 app.world.set_physics_process(false)
 app.exit_preview=false
 app.set_sound_enabled(false)
 for kind in Models.KINDS:
  var near:=Models.model(kind,false)
  var far:=Models.model(kind,true)
  var n:int=near.surface_get_array_len(0)/3
  var f:int=far.surface_get_array_len(0)/3
  metrics.append({"kind":kind,"near_triangles":n,"far_triangles":f})
  suite.check(near.get_surface_count()==1 and far.get_surface_count()==1,"Each "+kind+" LOD is one material surface")
  suite.check(f<n and n<1500,"Far "+kind+" uses fewer triangles with a bounded near mesh")
  suite.check(near==Models.model(kind,false),"Repeated "+kind+" shares cached geometry")
  var arrays:=near.surface_get_arrays(0)
  suite.check(arrays[Mesh.ARRAY_VERTEX].size()==arrays[Mesh.ARRAY_NORMAL].size() and arrays[Mesh.ARRAY_VERTEX].size()==arrays[Mesh.ARRAY_COLOR].size(),"Mesh attributes match for "+kind)
 for path in app.SCENERY_DEMOS:
  var level:=Data.load_json(path)
  suite.check(not level.is_empty() and Data.reachable(level),"Shore demo validates and preserves a route: "+path)
 app.level=Data.blank("Backdrop fixture","egypt",17,49)
 app.level.objects=[{"id":"s","type":"landmark","pos":[-4,20],"landmark_kind":"sphinx","landmark_scale":1,"solid":false}]
 suite.check(Data.validate(app.level)=="","Background anchors can be outside the playable rectangle")
 var tiled:Dictionary=app.level.duplicate(true)
 tiled.game_mode="tile"
 suite.check(Data.validate(tiled)=="","Tile mode also accepts whole-cell background landmarks")
 var water:Dictionary=app.level.duplicate(true)
 water.objects[0].pos=[3,20]
 water.tiles[20][3]="water"
 suite.check(Data.validate(water)=="","Non-blocking landmarks can stand directly in water")
 var bad:Dictionary=app.level.duplicate(true)
 bad.objects[0].pos=[-17,20]
 suite.check(Data.validate(bad)!="","Background placement bounds are enforced")
 bad=app.level.duplicate(true);bad.objects[0].solid=true
 suite.check(Data.validate(bad)!="","Background models cannot accidentally become tile blockers")
 bad=app.level.duplicate(true);bad.objects[0].landmark_scale=3
 suite.check(Data.validate(bad)!="","Invalid large scales are rejected")
 bad=app.level.duplicate(true);bad.objects[0].landmark_kind="missing"
 suite.check(Data.validate(bad)!="","Unknown model variants are rejected")
 bad=app.level.duplicate(true);bad.objects=[]
 for i in range(33):bad.objects.append({"id":str(i),"type":"landmark","pos":[1,2],"solid":false})
 suite.check(Data.validate(bad)!="","Landmark scene budget is enforced")
 app.enter_editor()
 suite.check(app.world.landmarks.entries.size()==1,"Runtime creates a background landmark outside the course")
 var entry=app.world.landmarks.entries[0]
 suite.check(entry.body.find_children("*","CollisionObject3D",true,false).is_empty(),"Landmarks have no physics bodies")
 var before:float=app.world.camera.size
 app.world.background_view=true
 app.world.fit_camera()
 suite.check(app.world.camera.size>before,"Background view exposes the surrounding water for placement")
 app.stroke_changed=false
 app.set_tool("landmark_heron")
 app.edit_cell(Vector2i(-2,4))
 suite.check(app.level.objects.size()==2 and app.level.objects[-1].landmark_kind=="heron","Editor places a selected landmark in the outer water")
 app.undo()
 suite.check(app.level.objects.size()==1,"Undo removes a background placement")
 app.redo()
 suite.check(app.level.objects.size()==2,"Redo restores a background placement")
 app.set_tool("select")
 app.edit_cell(Vector2i(-2,4))
 app.change_property("landmark_scale",0.5,false)
 suite.check(app.selected_object().landmark_scale==0.5,"Outside landmark selection and scale editing work")
 var roundtrip:Dictionary=Data.normalize(JSON.parse_string(JSON.stringify(app.level)))
 suite.check(Data.validate(roundtrip)=="" and roundtrip.objects[-1].pos==[-2,4],"Portable JSON preserves outside placement and model settings")
 app.stroke_changed=false
 app.set_tool("erase")
 app.edit_cell(Vector2i(-2,4))
 suite.check(app.level.objects.size()==1,"Erase removes a landmark outside the course without touching terrain")
 app.playtest()
 suite.check(is_equal_approx(app.world.landmark_focus_offset().y,1.7),"Scenery camera leaves headroom while keeping the normal follower position")
 var manager=app.world.landmarks
 entry=manager.entries[0]
 var anchor:Vector3=entry.body.global_position
 app.world.camera.position=anchor+Vector3(0,5,5)
 manager.update_lod()
 suite.check(entry.near.visible and not entry.far.visible,"Close view submits only the near LOD")
 app.world.camera.position=anchor+Vector3(0,5,25)
 manager.update_lod()
 suite.check(not entry.near.visible and entry.far.visible,"Distant view swaps to one cheaper LOD")
 var far_stats:Dictionary=manager.stats()
 suite.check(far_stats.visible_draws==1,"A distant landmark submits one draw, not its individual modeling pieces")
 app.world.camera.position=anchor+Vector3(0,5,50)
 manager.update_lod()
 suite.check(not entry.near.visible and not entry.far.visible and manager.stats().visible_triangles==0,"Beyond the draw range, neither LOD is submitted")
 app.world.camera.position=anchor+Vector3(0,5,32.4)
 manager.update_lod()
 suite.check(entry.state=="hidden","Culling hysteresis prevents threshold chatter")
 app.world.map_view=true
 suite.check(app.world.landmark_focus_offset()==Vector3.ZERO,"Overhead view retains its normal camera framing")
 manager.update_lod()
 suite.check(entry.far.visible and not entry.near.visible,"Overhead inspection reveals all landmarks using cheap geometry")
 app.world.map_view=false
 app.enter_editor()
 app.level.objects[0].pos=[1,1]
 suite.check(Data.reachable(app.level),"Course decoration never becomes a false exit-path blocker")
 app.level.objects=[]
 app.playtest()
 suite.check(app.world.landmark_focus_offset()==Vector3.ZERO,"Levels without landmarks keep their original framing")
 print("LANDMARK METRICS "+JSON.stringify(metrics))
 print("LANDMARKS: %d checks, %d failures" % [suite.checks,suite.failures.size()])
 quit(0 if suite.failures.is_empty() else 1)
