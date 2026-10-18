extends SceneTree
const Data = preload("res://scripts/level_data.gd")
const Suite = preload("res://tests/integration.gd")
var suite = Suite.new()
var app: Control
func _initialize() -> void:
 app = preload("res://main.tscn").instantiate()
 root.add_child(app)
 call_deferred("run")
func run() -> void:
 await process_frame
 app.set_process(false)
 app.world.set_physics_process(false)
 for axis in ["east_west","north_south"]:
  var level := Data.blank("Road test", "egypt", 9,9)
  for i in range(2,7):level.tiles[4 if axis=="east_west" else i][i if axis=="east_west" else 4]="road"
  level.objects=[{"id":"patrol","type":"patrol_car","pos":[4,4],"axis":axis,"length":1.0,"speed":3.0,"direction":1,"waypoints":[]}]
  suite.check(Data.validate(level).is_empty(),"Axis patrol validates: "+axis)
  app.level=level
  app.world.load_level(level,false,app.hat)
  var mover: Dictionary=app.world.crossing.movers[0]
  var safe:=true
  var reversals:=0
  var direction:int=mover.direction
  var low:=false
  var high:=false
  for i in range(800):
   app.world.crossing.advance(1.0/60.0,app.world.player)
   var cell:Vector2i=app.world.position_cell(mover.node.position)
   safe=safe and Data.road_cell_open(level,cell)
   var coordinate:int=cell.x if axis=="east_west" else cell.y
   low=low or coordinate==2
   high=high or coordinate==6
   if mover.direction!=direction:
    reversals+=1
    direction=mover.direction
  suite.check(safe and low and high and reversals>=4,"Road-only motion reverses repeatedly at both road ends: "+axis)
  app.world.player.position=mover.node.position
  suite.check(app.world.crossing.traffic_hit(app.world.player.position,app.world.player.position),"Patrol car can hit the frog: "+axis)
  var stationary:Vector3=mover.node.position
  app.world.begin_exit_preview()
  app.world._physics_process(0.3)
  suite.check(mover.node.position==stationary,"Exit preview pauses patrol car: "+axis)
 var level:=Data.blank("Square roads","egypt",9,9)
 for i in range(2,7):
  level.tiles[2][i]="road"
  level.tiles[6][i]="road"
  level.tiles[i][2]="road"
  level.tiles[i][6]="road"
 level.objects=[{"id":"patrol","type":"patrol_car","pos":[2,2],"length":1.0,"speed":4.0,"waypoints":[[6,2],[6,6],[2,6],[2,2]]}]
 suite.check(Data.validate(level).is_empty(),"Square drawn car route validates")
 app.level=level
 app.world.load_level(level,false,app.hat)
 var mover:Dictionary=app.world.crossing.movers[0]
 var safe:=true
 var visited:Dictionary={}
 for i in range(1000):
  app.world.crossing.advance(1.0/60.0,app.world.player)
  var cell:Vector2i=app.world.position_cell(mover.node.position)
  safe=safe and Data.road_cell_open(level,cell)
  visited[cell]=true
 suite.check(safe and visited.has(Vector2i(6,6)) and visited.has(Vector2i(2,6)) and visited.has(Vector2i(2,2)),"Drawn route repeats square turns without leaving roads")
 var bad:Dictionary=level.duplicate(true)
 bad.objects[0].waypoints=[[6,6]]
 suite.check(not Data.validate(bad).is_empty(),"Diagonal car route is rejected")
 bad=level.duplicate(true)
 bad.tiles[2][4]="wall"
 suite.check(not Data.validate(bad).is_empty(),"A wall through a drawn car route is rejected")
 app.enter_editor()
 app.level=level
 app.rebuild()
 app.selection="patrol"
 app.set_tool("route")
 app.edit_cell(Vector2i(3,3))
 suite.check(app.selected_object().waypoints.size()==4,"Editor rejects off-road patrol waypoints")
 var roundtrip:Dictionary=Data.normalize(JSON.parse_string(JSON.stringify(level)))
 suite.check(roundtrip.objects[0].waypoints==level.objects[0].waypoints and roundtrip.objects[0].get("axis","east_west")==level.objects[0].get("axis","east_west") and Data.validate(roundtrip).is_empty(),"Car route and axis survive JSON save/load")
 var tree_level:=Data.blank("Tree clearance","egypt",7,7)
 for y in range(1,6):
  for x in [2,4]:tree_level.tiles[y][x]="wall"
 tree_level.spawn=[3,5]
 tree_level.exit=[3,1]
 tree_level.objects=[{"id":"tree","type":"tree","pos":[3,3],"solid":true}]
 suite.check(Data.reachable(tree_level),"A tree no longer marks an exit path as blocked")
 tree_level.objects[0].type="pillar"
 suite.check(not Data.reachable(tree_level),"Pillars still block structural routes")
 print("CAR/TREE: %d checks, %d failures"%[suite.checks,suite.failures.size()])
 quit(0 if suite.failures.is_empty() else 1)
