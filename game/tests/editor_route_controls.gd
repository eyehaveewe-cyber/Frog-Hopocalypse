extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;push_error(label)
 else:print("PASS: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var app=load("res://main.tscn").instantiate();root.add_child(app);await process_frame
 app.enter_editor()
 var obj={"id":"route_controls_test","type":"critter","variant":0,"pos":[2,2],"behavior":"patrol","speed":1.6,"waypoints":[[3,2],[4,2]],"patrol_loop":true}
 app.level.objects.append(obj);app.rebuild();app.selection=obj.id;app.set_tool("route");await process_frame;await process_frame
 check(app.route_overlay.visible and app.route_overlay.points.size()==3,"Start and waypoint flags are projected in route editing")
 check(app.accept_route_button.visible and not app.accept_route_button.disabled,"Accept is available for a drawn route")
 var original:float=app.world.camera.size
 app.zoom_editor(.5);await process_frame
 check(app.world.camera.size<original and app.route_overlay.points.size()==3,"Zoom in retains screen-space flags")
 app.zoom_editor(2);check(is_equal_approx(app.world.camera.size,original),"Zoom out restores scale")
 app.level.tiles[2][5]="floor"
 app.level.objects.append({"id":"route_scenery","type":"tree","pos":[5,2],"rotation":0})
 app.edit_cell(Vector2i(5,2));await process_frame;await process_frame
 check(app.selected_object().waypoints.has([5,2]) and app.route_overlay.points.size()==4,"A route waypoint can occupy a scenery object's dry cell")
 var before_pan:Vector3=app.world.camera.position
 var before_flags:Vector2=app.route_overlay.points[1]
 app.world.pan_editor(Vector2(90,45));await process_frame
 check(app.world.camera.position.distance_to(before_pan)>.1 and app.route_overlay.points[1].distance_to(before_flags)>1,"Panning moves camera and projected flags together")
 var pan:Vector3=app.world.editor_pan
 app.rebuild();await process_frame
 check(app.world.editor_pan==pan,"Rebuild keeps camera pan")
 app.editor_panning=true;app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(not app.editor_panning,"Focus loss ends camera drag")
 check(app.route_overlay.z_index==100 and app.route_overlay.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Route flags draw above scenery without blocking route clicks")
 var route:Array=app.selected_object().waypoints.duplicate(true)
 app.accept_route_button.pressed.emit();await process_frame
 check(app.tool=="select" and not app.route_overlay.visible and not app.accept_route_button.visible,"Accept exits route mode and hides annotations")
 check(app.selected_object().waypoints==route,"Accept preserves route data")
 app.set_tool("route");app.selection="";await process_frame
 check(not app.route_overlay.visible and not app.accept_route_button.visible,"Deselection hides route UI")
 app.enter_editor();var zoom:float=app.world.editor_zoom;app.rebuild();check(app.world.editor_zoom==zoom,"Rebuilding preserves editor zoom")
 print("ROUTE CONTROLS: %d failures"%failures);quit(1 if failures else 0)
