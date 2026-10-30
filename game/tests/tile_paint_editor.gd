extends SceneTree
var failures:=0
func check(ok:bool, text:String)->void:
 if ok: print("PASS: "+text)
 else: failures+=1;push_error(text)
func _initialize()->void:call_deferred("run")
func run()->void:
 var app=load("res://main.tscn").instantiate();root.add_child(app);await process_frame
 app.enter_editor()
 app.level.tiles[2][2]="floor";app.level.tiles[2][3]="wall"
 app.level.objects.append({"id":"paint_tree","type":"tree","pos":[2,2],"rotation":0})
 app.rebuild();app.set_tool("paint_color");app.tile_paint_picker.color=Color("d83722")
 app.stroke_changed=false;app.edit_cell(Vector2i(2,2));app.edit_cell(Vector2i(3,2))
 check(app.level.tile_colors=={"2,2":"#d83722","3,2":"#d83722"},"Paint stroke colors floor and wall")
 check(app.object_at(Vector2i(2,2))>=0,"Painting preserves the object on the cell")
 app.undo();await process_frame
 check(app.level.get("tile_colors",{}).is_empty(),"One undo removes the full stroke")
 app.redo();await process_frame
 check(app.level.get("tile_colors",{}).size()==2,"Redo restores both painted cells")
 app.stroke_changed=false;app.edit_cell(Vector2i(2,2),true)
 check(not app.level.tile_colors.has("2,2") and app.object_at(Vector2i(2,2))>=0,"Right-click restores color without erasing object")
 app.stroke_changed=false;app.edit_cell(Vector2i(2,2))
 check(app.save_level(),"Painted level saves to library")
 var saved:Dictionary=app.library[-1].level.duplicate(true)
 check(saved.tile_colors==app.level.tile_colors,"Saved library retains paint colors")
 app.playtest();await process_frame
 check(app.mode=="test" and app.world.level.tile_colors==saved.tile_colors,"Playtest retains painted colors")
 app.return_to_editor();await process_frame
 check(app.level.tile_colors==saved.tile_colors,"Return to editor retains painted colors")
 app.set_tool("floor");app.stroke_changed=false;app.edit_cell(Vector2i(3,2))
 check(not app.level.get("tile_colors",{}).has("3,2"),"Replacing terrain clears its prior tint")
 print("TILE PAINT EDITOR: %d failures"%failures);quit(1 if failures else 0)
