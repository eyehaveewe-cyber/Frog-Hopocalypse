extends SceneTree
const Data=preload("res://scripts/level_data.gd")
var app: Control
var results: Array=[]
var failed=false
func _initialize() -> void:
 app=preload("res://main.tscn").instantiate()
 root.add_child(app)
 call_deferred("run")
func ticks(seconds: float) -> void:
 for i in range(ceili(seconds*60)):
  await physics_frame
  app.world._physics_process(1.0/60.0)
func hop(direction: Vector2i,big: bool=false) -> bool:
 if not app.world.result.is_empty():return false
 if not app.world.tile_rules.request(direction,big):
  print("BLOCKED ",app.world.position_cell(app.world.player.position),direction,big)
  return false
 await ticks(0.42)
 return app.world.result.is_empty() or app.world.result=="LEVEL COMPLETE!"
func walk_to(x: int,y: int) -> bool:
 var goal=Vector2i(x,y)
 while app.world.position_cell(app.world.player.position)!=goal:
  var p: Vector2i=app.world.position_cell(app.world.player.position)
  var difference=goal-p
  var direction=Vector2i(signi(difference.x),0) if difference.x!=0 else Vector2i(0,signi(difference.y))
  if not await hop(direction):return false
 return true
func course(index: int,wait: float=0,shortcut: bool=false) -> void:
 app.open_movement_demo(index)
 app.playtest()
 await ticks(wait)
 var ok=true
 if index==0:
  ok=await walk_to(8,43) and await hop(Vector2i.UP,true) and await walk_to(8,38) and await walk_to(5,38) and await walk_to(5,35)
  if ok and wait>0:
   # Observe the visible far traffic lane from the safe bank, then commit.
   for i in range(240):
    var lane=app.world.crossing.movers[1]
    var cell=app.world.tile_rules.point(lane.node.position)
    if cell.x<3.1 or cell.x>7: break
    await ticks(0.05)
  if ok:ok=await hop(Vector2i.UP,true) and await walk_to(5,32) and await walk_to(12,32) and await walk_to(12,31) and await hop(Vector2i.UP,true) and await walk_to(12,28)
  if ok:ok=await walk_to(12,26) and await hop(Vector2i.UP,true) and await walk_to(5,24) and await walk_to(5,23) and await hop(Vector2i.UP,true) and await hop(Vector2i.UP,true) and await hop(Vector2i.UP,true)
  if ok:ok=await walk_to(5,15) and await hop(Vector2i.UP,true) and await walk_to(12,13) and await walk_to(12,12) and await hop(Vector2i.UP,true) and await walk_to(12,9) and await hop(Vector2i.UP,true)
  if ok:ok=await walk_to(8,7) and await walk_to(8,6) and await hop(Vector2i.UP,true) and await walk_to(8,2)
 else:
  ok=await walk_to(3,36) and await hop(Vector2i.UP,true) and await walk_to(6,34) and await walk_to(6,32) and await hop(Vector2i.UP,true) and await walk_to(8,30) and await hop(Vector2i.RIGHT,true) and await walk_to(18,30)
  if ok:ok=await walk_to(18,26) and await walk_to(17,26) and await walk_to(17,25) and await walk_to(16,25) and await hop(Vector2i.LEFT,true) and await walk_to(10,25) and await walk_to(10,21)
  if ok:ok=await walk_to(6,21) and await walk_to(6,18) and await hop(Vector2i.UP,true) and await walk_to(6,15) and await hop(Vector2i.UP,true) and await walk_to(10,13) and await walk_to(10,12) and await walk_to(12,12) and await walk_to(12,11)
  if ok:
   if shortcut:ok=await walk_to(13,11) and await hop(Vector2i.RIGHT,true) and await walk_to(17,11) and await hop(Vector2i.UP,true) and await walk_to(18,9) and await walk_to(18,5) and await hop(Vector2i.UP,true) and await walk_to(17,3) and await walk_to(17,2)
   else:ok=await walk_to(11,11) and await hop(Vector2i.UP,true) and await walk_to(10,9) and await walk_to(10,5) and await hop(Vector2i.UP,true) and await walk_to(17,3) and await walk_to(17,2)
 var r={"level":app.level.name,"initial_wait":wait,"vault_shortcut":shortcut,"result":app.world.result,"hops":app.world.tile_rules.hop_count,"elapsed":app.world.elapsed,"position":app.world.position_cell(app.world.player.position),"checkpoints":app.world.claimed_checkpoints.size(),"spike_slams":app.world.spikes.balls.map(func(ball: Dictionary):return ball.slams)}
 results.append(r)
 print("ROUTE "+JSON.stringify(r))
 if not ok or app.world.result!="LEVEL COMPLETE!":failed=true
func run() -> void:
 await process_frame
 app.set_process(false)
 app.world.set_physics_process(false)
 app.set_sound_enabled(false)
 app.exit_preview=false
 if "--shortcut-only" in OS.get_cmdline_user_args():
  await course(1,0,true)
  quit(1 if failed else 0)
  return
 await course(0)
 await course(1)
 await course(0,1.55)
 await course(1,0,true)
 # Original regular-mode demo remains a separate regression, with its bytes unchanged.
 app.open_movement_demo(2)
 app.playtest()
 app.world.input_vector=Vector2.UP
 for i in range(1800):
  await physics_frame
  app.world._physics_process(1.0/60)
  if not app.world.result.is_empty():break
 results.append({"level":app.level.name,"result":app.world.result,"elapsed":app.world.elapsed})
 if app.world.result!="LEVEL COMPLETE!":failed=true
 print("DEMO ROUTES: "+JSON.stringify(results))
 quit(1 if failed else 0)
