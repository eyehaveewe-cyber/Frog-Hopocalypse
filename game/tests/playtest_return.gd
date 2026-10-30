extends SceneTree
var failures:=0
func check(ok:bool,message:String)->void:
 if not ok:failures+=1;push_error(message)
 else:print("PASS: "+message)
func _initialize()->void:call_deferred("run")
func run()->void:
 var app=load("res://main.tscn").instantiate();root.add_child(app)
 await process_frame
 app.rule_notices_enabled=false;app.exit_preview=false
 app.load_builtin(0,"baby");app.enter_editor()
 app.editor_saved_snapshot=app.level.duplicate(true);app.name_field.text="Unsaved return test";app.commit_name()
 var edited:Dictionary=app.level.duplicate(true)
 app.playtest();await process_frame
 check(app.mode=="test" and app.return_editor_button.visible,"Clearly labelled return control appears in playtest")
 app.world.set_map_view(true);await process_frame
 check(app.return_editor_button.visible,"Return remains available in map view")
 app.return_editor_button.pressed.emit();await process_frame
 check(app.mode=="edit" and app.sidebar.visible,"Visible button returns to editor")
 check(app.level==edited and app.editor_has_unsaved_changes(),"Unsaved level edits survive round trip")
 check(not app.editor_leave_open,"Returning to same edit session does not request discard")
 app.playtest();app.toggle_pause()
 var pause_buttons=app.overlay_box.find_children("*","Button",true,false).filter(func(b):return b.text=="Back to editor")
 check(pause_buttons.size()==1,"Pause includes explicit Back to editor action")
 pause_buttons[0].pressed.emit();check(app.mode=="edit" and app.level==edited,"Paused return preserves edits")
 app.playtest();app.present_result("LEVEL COMPLETE!",false,false)
 var result_buttons=app.overlay_box.find_children("*","Button",true,false).filter(func(b):return b.text=="Back to editor" and not b.is_queued_for_deletion())
 check(result_buttons.size()==1,"Result includes return action")
 result_buttons[0].pressed.emit();check(app.mode=="edit" and app.level==edited,"Completion return preserves edits")
 app.start_play(false);await process_frame
 check(not app.return_editor_button.visible,"Normal campaign play has no edit-return button")
 print("PLAYTEST RETURN: %d failures"%failures);quit(1 if failures else 0)
