extends SceneTree
const Data=preload("res://scripts/level_data.gd")
var app:Control
var checks:=0
var failures:Array=[]
func check(ok:bool,message:String)->void:
 checks+=1
 if not ok:failures.append(message);push_error(message)
func _initialize()->void:
 app=preload("res://main.tscn").instantiate();app.rule_notices_enabled=false
 root.add_child(app);call_deferred("run")
func button(text:String)->Button:
 for b in app.overlay_box.find_children("*","Button",true,false):
  if b.text==text:return b
 return null
func edit(tool:String,point:Vector2i)->void:
 app.stroke_changed=false;app.set_tool(tool);app.edit_cell(point)
func fresh()->void:
 app.level=Data.blank("Road fragments","egypt",9,9);app.level.game_mode="tile";app.level.move_with_me=true;app.level.rules={"long_hop":"fragments"};app.level.spawn=[3,7]
 app.editor_saved_snapshot=app.level.duplicate(true);app.enter_editor()
func run()->void:
 await process_frame
 app.set_process(false);app.world.set_physics_process(false);app.exit_preview=false;app.set_sound_enabled(false)
 app.enter_editor()
 check(not app.editor_has_unsaved_changes(),"Untouched bundled map starts clean")
 edit("wall",Vector2i(3,3));var changed=app.level.duplicate(true)
 app.show_menu()
 check(app.editor_leave_open and button("Yes · Save and leave")!=null and button("No · Leave without saving")!=null and button("Continue editing")!=null,"Leaving changed editor offers all three requested choices")
 var event:=InputEventKey.new();event.pressed=true;event.keycode=KEY_ESCAPE;app._input(event)
 check(not app.editor_leave_open and app.level==changed and not app.overlay.visible,"Escape continues here with all edits intact")
 app.show_menu();button("Yes · Save and leave").pressed.emit()
 check(not app.editor_leave_open and app.splash_menu and not app.editor_session_active,"Successful Save and leave reaches the menu")
 var saved=JSON.parse_string(FileAccess.get_file_as_string("user://library.json"))
 check(saved.any(func(item):return Data.normalize(item.level)==changed),"Save and leave writes the exact edited map")
 app.enter_editor();check(not app.editor_has_unsaved_changes(),"Saved snapshot marks the editor clean")
 edit("wall",Vector2i(4,3));app.undo()
 check(not app.editor_has_unsaved_changes(),"Undo back to the saved state clears dirty status")
 app.name_field.text="Renamed map";app.show_menu()
 check(app.editor_leave_open and app.level.name=="Renamed map","Unsubmitted name edits are included in the leave guard")
 button("Continue editing").pressed.emit()
 check(app.name_field.text=="Renamed map" and app.editor_has_unsaved_changes(),"Continue editing keeps the new name and dirty state")
 app.new_level("swamp")
 check(app.editor_leave_open and app.level.name=="Renamed map","Replacing a map also protects pending work")
 button("No · Leave without saving").pressed.emit()
 check(app.level.theme=="swamp" and app.level.name=="New Swamp" and app.editor_has_unsaved_changes(),"No replaces the old map with the requested unsaved map")
 app.level.objects=[{"id":"bad","type":"unknown","pos":[3,3],"solid":false}]
 var count=app.library.size();app.show_menu();button("Yes · Save and leave").pressed.emit()
 check(app.editor_leave_open and app.editor_session_active and app.library.size()==count,"Failed save keeps the guard, editor and saved library intact")
 button("Continue editing").pressed.emit();app.level.objects=[]
 var persisted=FileAccess.get_file_as_string("user://library.json")
 var previous_slot=app.slot_id
 DirAccess.make_dir_absolute("user://library.pending.json")
 app.show_menu();button("Yes · Save and leave").pressed.emit()
 check(app.editor_leave_open and app.slot_id==previous_slot and app.library.size()==count,"Filesystem write failure cannot navigate or commit a new in-memory save")
 check(FileAccess.get_file_as_string("user://library.json")==persisted,"Filesystem write failure preserves the previous saved file")
 DirAccess.remove_absolute("user://library.pending.json")
 button("Continue editing").pressed.emit()
 app.playtest();app.world.set_physics_process(false);app.show_menu()
 check(app.editor_leave_open,"Leaving a playtest also protects its unsaved editor map")
 button("No · Leave without saving").pressed.emit()
 check(not app.editor_session_active,"Discard choice ends the active editor navigation guard")
 button("Continue playing").pressed.emit()
 check(app.editor_session_active,"Continuing a playtest from Menu reactivates protection")
 app.show_menu();button("No · Leave without saving").pressed.emit()
 fresh();edit("road",Vector2i(3,6));edit("hop_fragment",Vector2i(3,6))
 check(app.level.objects.size()==1 and app.level.objects[0].type=="hop_fragment","Editor places a fragment on a road")
 check(Data.validate(app.level)=="","Road fragment layout validates")
 var exported=Data.normalize(JSON.parse_string(JSON.stringify(app.level)))
 check(exported==app.level and Data.validate(exported)=="","Road fragment survives JSON export/import normalization")
 app.playtest();app.world.set_physics_process(false)
 app.world.tile_rules.request(Vector2i.UP,false)
 for i in range(26):await physics_frame;app.world._physics_process(1.0/60)
 check(app.world.tile_rules.fragments==1 and app.world.result=="","Safe road landing collects the fragment")
 fresh();edit("hop_fragment",Vector2i(3,6));edit("road",Vector2i(3,6))
 check(app.level.tiles[6][3]=="road" and app.level.objects.size()==1,"Painting road under an existing fragment keeps it")
 app.undo();check(app.level.tiles[6][3]=="floor" and app.level.objects.size()==1,"Undo restores terrain while retaining the fragment")
 app.level.tiles[6][3]="water"
 check(Data.validate(app.level)!="","Fragments still reject water")
 app.level.tiles[6][3]="road";app.level.objects[0].type="hop_seed"
 check(Data.validate(app.level)!="","Hop seeds retain their safe-bank rule")
 fresh()
 for x in range(1,8):app.level.tiles[6][x]="road"
 app.level.objects=[{"id":"f","type":"hop_fragment","pos":[3,6],"solid":false},{"id":"car","type":"car","pos":[4,6],"solid":false,"direction":-1,"speed":1.0,"length":1.0}]
 app.playtest();app.world.set_physics_process(false)
 app.world.tile_rules.request(Vector2i.UP,false)
 for i in range(26):await physics_frame;app.world._physics_process(1.0/60)
 check(app.world.result=="SQUISHED!" and app.world.tile_rules.fragments==0,"Traffic remains lethal; a fatal contact does not award its fragment")
 print("EDITOR LEAVE/ROAD FRAGMENTS: %d checks, %d failures"%[checks,failures.size()])
 app.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
