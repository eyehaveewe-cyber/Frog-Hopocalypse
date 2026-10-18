extends SceneTree
const Suite=preload("res://tests/integration.gd")
const Art=preload("res://scripts/art.gd")
var suite=Suite.new()
var app: Control
func _initialize() -> void:
 root.size=Vector2i(1280,1000)
 app=preload("res://main.tscn").instantiate()
 root.add_child(app)
 call_deferred("run")
func run() -> void:
 await process_frame
 app.set_process(false)
 app.world.set_physics_process(false)
 app.enter_editor()
 app.new_level("egypt")
 app.library=[]
 suite.check(app.level.name=="New Egypt" and app.level.has("editor_autosave_id"),"New tileset creation starts a recovery-enabled map")
 for i in range(39):
  app.change_property("unused",0) # No selection must not count as an edit.
  app.record_undo()
  app.level.name="New Egypt %d"%i
  await process_frame
 suite.check(not app.editor_autosave_due and app.library.is_empty(),"39 actual edits have not created an early checkpoint")
 app.record_undo()
 app.level.name="New Egypt Forty"
 await process_frame
 suite.check(app.editor_autosave_due,"The fortieth completed edit schedules an autosave")
 app.stroke=true
 app._process(0.0)
 suite.check(app.editor_autosave_due and app.library.is_empty(),"Checkpoint waits for a paint stroke to finish")
 app.stroke=false
 app._process(0.0)
 suite.check(app.library.size()==1 and app.library[0].autosave and app.library[0].original_name=="New Egypt Forty","Checkpoint stores the fortieth edit after the stroke")
 var automatic_id=app.library[0].id
 for i in range(40):
  app.record_undo()
  app.level.name="New Egypt More %d"%i
  await process_frame
 app._process(0.0)
 suite.check(app.library.size()==1 and app.library[0].id==automatic_id and app.library[0].original_name=="New Egypt More 39","The next forty edits update this map's recovery slot")
 app.library=[]
 app.load_library()
 suite.check(app.library.size()==1,"Recovery checkpoint survives reloading local storage")
 app.load_library_entry(0)
 suite.check(app.level.name=="New Egypt More 39" and app.slot_id.is_empty(),"Recovery restores the original map name and does not occupy its manual save slot")
 app.save_level()
 suite.check(app.library.size()==2 and app.slot_id!=automatic_id,"Manual saving a recovered map preserves its recovery copy")
 app.new_level("swamp")
 suite.check(app.level.name=="New Swamp" and not app.editor_autosave_due,"New Swamp starts its own recovery counter")
 app.level.objects=[{"id":"unfinished","type":"critter","pos":[3,3],"behavior":"patrol","waypoints":[[4,3]],"speed":1.6}]
 app.level.tiles[3][4]="wall"
 suite.check(app.Data.validate(app.level)!="" and app.save_editor_checkpoint(),"Recovery saves an unfinished patrol blocked by an editor wall")
 app.load_library_entry(app.library.size()-1)
 suite.check(app.level.objects[0].waypoints==[[4,3]] and app.level.tiles[3][4]=="wall","Recovery restores unfinished edits exactly")
 var malformed=app.level.duplicate(true)
 malformed.objects[0].waypoints=[[9999,3]]
 suite.check(app.Data.validate(malformed,true)!="","Recovery still rejects malformed out-of-bounds data")
 app.level.game_mode="tile"
 app.level.objects=[{"id":"turret","type":"emitter","pos":[3,3],"interval":0,"rotation":0,"solid":true}]
 app.selection="turret"
 app.rebuild()
 await process_frame
 await process_frame
 var spinner: SpinBox
 for child in app.inspector.get_children():
  if child is SpinBox and child.suffix=="beats / shot": spinner=child
 suite.check(spinner!=null and spinner.min_value==1 and spinner.value==1,"Legacy zero interval displays at least one whole beat")
 var control_id=spinner.get_instance_id()
 spinner.value=2
 suite.check(is_instance_valid(spinner) and spinner.is_inside_tree() and spinner.get_instance_id()==control_id and app.selected_object().interval==2,"Spinner stays in the scene tree throughout its value callback")
 spinner.value=3
 suite.check(app.selected_object().interval==3 and spinner.is_inside_tree(),"Repeated spinner edits remain responsive")
 app.change_property("interval",0,false)
 suite.check(app.selected_object().interval==1,"Tile firing interval rejects zero")
 app.undo()
 suite.check(app.selected_object().is_empty() and app.level.objects[0].interval==3,"Undo restores the prior turret interval")
 suite.check(Art.Pixels.get_texture("brick").get_image().has_mipmaps(),"Brick texture has filtered distance levels")
 suite.check(Art.Pixels.get_texture("stone_wall").get_image().has_mipmaps() and not Art.Pixels.get_texture("stone").get_image().has_mipmaps(),"Wall caps receive filtering without changing ground textures")
 Art.compatibility_mode=true
 var wall=Art.retro_mat("brick")
 suite.check(wall is StandardMaterial3D and wall.texture_filter==BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS,"Compatibility renderer filters brick walls too")
 print("EDITOR RECOVERY: %d checks, %d failures"%[suite.checks,suite.failures.size()])
 quit(0 if suite.failures.is_empty() else 1)
