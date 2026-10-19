extends SceneTree
const Data=preload("res://scripts/level_data.gd")
const Backdrops=preload("res://scripts/backdrops.gd")
const Suite=preload("res://tests/integration.gd")
var suite=Suite.new()
var app:Control
func _initialize()->void:
 app=preload("res://main.tscn").instantiate()
 app.rule_notices_enabled=false
 root.add_child(app)
 call_deferred("run")
func run()->void:
 await process_frame
 app.set_process(false)
 app.world.set_physics_process(false)
 app.exit_preview=false
 app.set_sound_enabled(false)
 for path in app.SCENERY_DEMOS.slice(2):
  var demo:=Data.load_json(path)
  suite.check(not demo.is_empty() and Data.reachable(demo),"Horizon comparison demo validates: "+path)
 app.level=Data.load_json(app.SCENERY_DEMOS[3])
 app.enter_editor()
 suite.check(app.world.backdrops.entries.size()==2 and app.world.landmarks.entries.size()==6,"Distant layer and original course landmarks remain separate")
 var entry=app.world.backdrops.entries[0]
 suite.check(not entry.card.visible and entry.thumbnail.visible,"Editor shows a small ground thumbnail rather than giant virtual geometry")
 app.playtest()
 var manager=app.world.backdrops
 entry=manager.entries[0]
 suite.check(entry.card.visible and not entry.thumbnail.visible,"Gameplay renders the distant card instead of the map icon")
 suite.check(entry.height==120,"80x art scale gives a 120-unit portrait without changing course size")
 suite.check(entry.card.mesh.get_faces().size()/3==2,"Giant backdrop remains two triangles")
 var mat:StandardMaterial3D=entry.card.material_override
 suite.check(mat.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR and not mat.no_depth_test,"Cutout edges keep normal depth occlusion, without alpha blending")
 suite.check(mat.shading_mode==BaseMaterial3D.SHADING_MODE_UNSHADED and entry.card.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"Backdrops add no dynamic lighting or shadow pass")
 suite.check(manager.find_children("*","CollisionObject3D",true,false).is_empty(),"Distant art adds no course collision")
 var transform:Transform3D=entry.card.global_transform
 var ordinary_far:float=float(app.level.draw_distance)*app.world.CELL+12
 suite.check(app.world.camera.far>entry.distance and app.world.camera.far>ordinary_far,"Only scenery camera far clipping extends beyond normal landmark vision")
 suite.check(entry.card.visibility_range_end==0,"Ordinary landmark range does not hide giant backdrops")
 app.world.camera.position+=Vector3(20,0,10)
 app.world.backdrops.configure_view()
 suite.check(entry.card.global_transform==transform,"World anchor and orientation never follow the moving camera")
 suite.check(is_equal_approx(entry.card.position.y-entry.height/2,-0.6),"The bottom of the art is anchored at the distant sea surface")
 app.world.map_view=true
 app.world.fit_camera()
 suite.check(entry.thumbnail.visible and not entry.card.visible and not manager.sea.visible,"Map inspection restores small icons and removes the distant horizon plane")
 app.world.map_view=false
 app.enter_editor()
 app.stroke_changed=false
 app.set_tool("backdrop")
 app.edit_cell(Vector2i(-2,8))
 suite.check(app.level.objects[-1].type=="backdrop" and app.level.objects[-1].backdrop_scale==80,"Editor places the independent distant layer in outside water")
 app.change_property("backdrop_scale",40,false)
 suite.check(app.selected_object().backdrop_scale==40,"Editor changes art scale without touching landmark_scale")
 app.change_property("backdrop_distance",640,false)
 suite.check(app.selected_object().backdrop_distance==640,"Editor changes virtual distance independently")
 app.undo()
 suite.check(app.level.objects[-1].backdrop_distance==480,"Backdrop edits participate in Undo")
 var roundtrip:Dictionary=Data.normalize(JSON.parse_string(JSON.stringify(app.level)))
 suite.check(Data.validate(roundtrip)=="" and roundtrip.objects[-1].pos==[-2,8],"Portable JSON preserves backdrop settings and anchors")
 for patch in [{"backdrop_scale":0},{"backdrop_scale":101},{"backdrop_distance":127},{"backdrop_distance":2049},{"solid":true},{"backdrop_kind":"missing"}]:
  var bad:Dictionary=roundtrip.duplicate(true)
  bad.objects[-1].merge(patch,true)
  suite.check(Data.validate(bad)!="","Backdrop schema rejects invalid setting: "+str(patch))
 var crowded:Dictionary=roundtrip.duplicate(true)
 for i in range(3):
  var obj:Dictionary=crowded.objects[-1].duplicate(true)
  obj.id="excess_"+str(i)
  crowded.objects.append(obj)
 suite.check(Data.validate(crowded)!="","A four-card budget bounds worst-case overdraw")
 var a:Dictionary=Data.load_json(app.SCENERY_DEMOS[2])
 var b:Dictionary=Data.load_json(app.SCENERY_DEMOS[3])
 suite.check(a.tiles==b.tiles and a.spawn==b.spawn and a.exit==b.exit,"Scale comparison has identical physical course geometry")
 app.level=a
 app.playtest()
 var camera_a:Transform3D=app.world.camera.global_transform
 var far_a:float=app.world.camera.far
 var small:Dictionary=app.world.backdrops.stats()
 app.level=b
 app.playtest()
 var large:Dictionary=app.world.backdrops.stats()
 suite.check(camera_a==app.world.camera.global_transform and is_equal_approx(far_a,app.world.camera.far),"Comparison uses the identical camera and clipping planes")
 suite.check(small.card_triangles==large.card_triangles and large.quad_rect_pixels>small.quad_rect_pixels,"Magnification changes fill area, not geometry; diagnostics expose the cost")
 print("BACKDROP COMPARISON "+JSON.stringify({"one_x":small,"eighty_x":large}))
 print("BACKDROPS: %d checks, %d failures" % [suite.checks,suite.failures.size()])
 quit(0 if suite.failures.is_empty() else 1)
