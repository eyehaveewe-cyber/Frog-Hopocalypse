extends Control
## Screen-space patrol annotations, independent of terrain height and zoom.
var app
var points:Array[Vector2]=[]
func _ready()->void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 clip_contents=true
func _process(_dt:float)->void:
 var obj:Dictionary=app.selected_object()
 visible=app.mode=="edit" and app.tool=="route" and not app.overlay.visible and obj.get("type","") in ["critter","patrol_car","spike_ball"]
 points.clear()
 if not visible:return
 position=app.view_container.global_position;size=app.view_container.size
 for point in [obj.pos]+obj.get("waypoints",[]):
  points.append(app.world.camera.unproject_position(app.world.cell_position(point))*size/Vector2(app.view.size))
 queue_redraw()
func _draw()->void:
 if points.is_empty():return
 var edges:Array=[]
 for i in range(1,points.size()):edges.append([points[i-1],points[i]])
 var obj:Dictionary=app.selected_object()
 if obj.get("patrol_loop",true) and points.size()>2:edges.append([points[-1],points[1]])
 for edge in edges:
  draw_line(edge[0],edge[1],Color("12231b"),7,true)
  draw_line(edge[0],edge[1],Color("ffe477"),3,true)
 var font:Font=ThemeDB.fallback_font
 for i in points.size():
  var p:Vector2=points[i]
  draw_circle(p,5,Color("12231b"));draw_circle(p,3,Color("ffe477"))
  draw_line(p,p+Vector2(0,-28),Color("12231b"),5)
  draw_line(p,p+Vector2(0,-28),Color.WHITE,2)
  var flag:=Rect2(p+Vector2(0,-32),Vector2(54 if i==0 else 30,24))
  draw_rect(flag.grow(2),Color("12231b"));draw_rect(flag,Color("ffe477"))
  draw_string(font,flag.position+Vector2(5,18),"Start" if i==0 else str(i),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("12231b"))
