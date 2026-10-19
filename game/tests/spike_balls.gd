extends SceneTree
const Suite=preload("res://tests/integration.gd")
const Data=preload("res://scripts/level_data.gd")
var suite=Suite.new()
var app: Control
func _initialize() -> void:
 app=preload("res://main.tscn").instantiate()
 root.add_child(app)
 call_deferred("run")
func fresh(linked: bool=true) -> void:
 app.level=Data.blank("Spike test","egypt",11,11)
 app.level.game_mode="tile"
 app.level.move_with_me=linked
 app.level.spawn=[5,8]
 app.level.objects=[{"id":"rail","type":"spike_ball","pos":[2,5],"behavior":"slam_patrol","waypoints":[[8,5]],"patrol_loop":true,"pause":2,"solid":false}]
 app.world.load_level(app.level,false,"none")
 app.world.set_physics_process(false)
func ticks(seconds: float) -> void:
 for i in range(ceili(seconds*60)):
  await physics_frame
  app.world._physics_process(1.0/60.0)
func run() -> void:
 await process_frame
 app.set_process(false)
 app.set_sound_enabled(false)
 fresh()
 var ball=app.world.spikes.balls[0]
 var start: Vector3=ball.node.position
 var target: Vector3=ball.target
 await ticks(1.5)
 suite.check(ball.node.position==start and ball.hold==2 and ball.target==target,"Move with me freezes the spike and its locked telegraph at rest")
 app.world.spikes.begin_beat()
 app.world.spikes.begin_beat()
 suite.check(not ball.moving and ball.hold==0,"Two hold beats precede the slam beat")
 app.world.spikes.begin_beat()
 app.world.spikes.advance(0.16,app.world.player.position,app.world.player.position,false,true)
 suite.check(ball.node.position==target and ball.slams==1,"Patrol ball slams the complete cardinal segment in 0.16 seconds")
 suite.check(ball.target==start and ball.hold==2,"Loop selects and telegraphs its return before moving")
 fresh()
 app.level.objects[0].patrol_loop=false
 app.world.load_level(app.level,false,"none")
 ball=app.world.spikes.balls[0]
 for i in range(3): app.world.spikes.begin_beat()
 app.world.spikes.advance(0.16,app.world.player.position,app.world.player.position,false,true)
 for i in range(6): app.world.spikes.begin_beat()
 suite.check(ball.stopped and ball.slams==1 and ball.target==ball.node.position,"A nonlooping patrol holds at its final target")
 fresh()
 ball=app.world.spikes.balls[0]
 app.world.player.position=app.world.cell_position([5,5])
 for i in range(3):app.world.spikes.begin_beat()
 app.world.spikes.advance(0.16,app.world.player.position,app.world.player.position,false,true)
 suite.check(app.world.result=="SPIKED!","Swept collision catches the frog between distant slam endpoints")
 fresh()
 ball=app.world.spikes.balls[0]
 var mid: Vector3=app.world.cell_position([5,5])
 for i in range(3):app.world.spikes.begin_beat()
 app.world.spikes.advance(0.16,mid,mid,true,true)
 suite.check(app.world.result.is_empty(),"Airborne long hops clear a spike slam")
 fresh()
 app.world.player.position=app.world.spikes.balls[0].node.position
 app.world.spikes.advance(0.01,app.world.player.position,app.world.player.position,false,true)
 suite.check(app.world.result=="SPIKED!","A holding ball remains a contact hazard")
 fresh()
 app.level.objects[0].behavior="free_shift"
 app.level.objects[0].directions=[270]
 app.level.objects[0].range=3
 app.level.tiles[5][4]="cheese_wall"
 app.world.load_level(app.level,false,"none")
 ball=app.world.spikes.balls[0]
 suite.check(app.world.position_cell(ball.target)==Vector2i(3,5),"Free shift obeys its enabled direction and stops before cheese")
 app.level.tiles[5][4]="wall"
 suite.check(not Data.spike_segment_open(app.level,[2,5],[6,5]),"Walls block a spike patrol segment")
 app.level.tiles[5][4]="water"
 suite.check(not Data.spike_segment_open(app.level,[2,5],[6,5]),"Water bounds free-shift arenas")
 app.level.tiles[5][4]="floor"
 suite.check(not Data.spike_segment_open(app.level,[2,5],[6,6]),"Spike patrols cannot move diagonally")
 app.level.objects[0].directions=[]
 suite.check(Data.validate(app.level)!="","Portable maps reject zero enabled directions")
 app.level.objects[0].directions=[0,0]
 suite.check(Data.validate(app.level)!="","Portable maps reject duplicate directions")
 fresh()
 app.level.objects[0].behavior="free_shift"
 app.level.objects[0].pos=[5,5]
 app.level.objects[0].directions=[0,90,180,270]
 app.level.objects[0].range=2
 app.world.load_level(app.level,false,"none")
 ball=app.world.spikes.balls[0]
 var first: Vector3=ball.target
 var seen={}
 var cardinal=true
 for i in range(30):
  var delta: Vector3=ball.target-ball.node.position
  cardinal=cardinal and (absf(delta.x)<0.01 or absf(delta.z)<0.01) and delta.length()<=app.world.CELL*2+0.01
  seen[Vector2i(signi(int(delta.x)),signi(int(delta.z)))]=true
  for beat in range(3): app.world.spikes.begin_beat()
  app.world.spikes.advance(0.16,Vector3(1000,0,1000),Vector3(1000,0,1000),false,true)
 suite.check(cardinal and seen.size()==4,"Four-direction free shifts stay cardinal and bounded over thirty slams")
 app.world.load_level(app.level,false,"none")
 suite.check(app.world.spikes.balls[0].target==first,"Stable object IDs reproduce the first telegraphed target on retry")
 fresh(false)
 start=app.world.spikes.balls[0].node.position
 await ticks(2.3)
 suite.check(app.world.spikes.balls[0].slams>0 and app.world.spikes.balls[0].node.position!=start,"Ordinary tile mode runs spike holds while the player waits")
 fresh()
 app.level.game_mode="hopan"
 app.level.move_with_me=true
 app.world.load_level(app.level,false,"none")
 ball=app.world.spikes.balls[0]
 await ticks(1)
 suite.check(ball.hold==2,"Regular Hopán linked time freezes the spike at rest too")
 app.world.input_vector=Vector2.LEFT
 await ticks(0.3)
 suite.check(ball.hold<2,"Regular Hopán movement advances the spike hold")
 app.mode="edit"
 app.level=Data.blank("Editor spike","egypt",11,11)
 app.enter_editor()
 app.set_tool("spike_ball")
 app.stroke_changed=false
 app.edit_cell(Vector2i(4,4))
 suite.check(app.selected_object().type=="spike_ball" and Data.validate(app.level)=="","Editor places a valid free-shifting spike")
 app.change_property("behavior","slam_patrol")
 app.set_tool("route")
 app.edit_cell(Vector2i(7,4))
 suite.check(app.selected_object().waypoints==[[7,4]],"Editor draws cardinal spike patrol targets")
 app.edit_cell(Vector2i(6,6))
 suite.check(app.selected_object().waypoints==[[7,4]],"Editor rejects diagonal patrol segments")
 var saved=JSON.parse_string(JSON.stringify(app.level))
 suite.check(Data.validate(saved)=="" and Data.normalize(saved)==app.level,"Spike behavior survives portable JSON round trip")
 app.undo()
 suite.check(app.level.objects[0].get("waypoints",[]).is_empty(),"Undo restores the spike's preceding route")
 for path in app.TILE_LEVELS:
  var d=Data.load_json(path)
  suite.check(not d.is_empty() and Data.reachable(d),"Redesigned map has valid schema and an exit route: "+path)
 print("SPIKE BALLS: %d checks, %d failures"%[suite.checks,suite.failures.size()])
 quit(0 if suite.failures.is_empty() else 1)
