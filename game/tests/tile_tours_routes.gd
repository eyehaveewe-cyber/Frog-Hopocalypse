extends SceneTree
const Data=preload("res://scripts/level_data.gd")
var app:Control
var results:Array=[]
var failed=false
var visited:Array=[]
var recharge_before_gate:Array=[]
func _initialize()->void:
 app=preload("res://main.tscn").instantiate()
 app.rule_notices_enabled=false
 root.add_child(app)
 call_deferred("run")
func ticks(seconds:float)->void:
 for i in range(ceili(seconds*60)):
  await physics_frame
  app.world._physics_process(1.0/60.0)
func hop(direction:Vector2i,big:bool=false)->bool:
 var rules=app.world.tile_rules
 if not app.world.result.is_empty():return false
 if big:recharge_before_gate.append({"at":str(app.world.position_cell(app.world.player.position)),"ready":rules.long_hop_ready(),"hops":rules.hop_count,"remaining":rules.charge_remaining})
 if not rules.request(direction,big):
  print("BLOCKED ",app.world.position_cell(app.world.player.position),direction,big," ",rules.last_block)
  return false
 await ticks(.42)
 visited.append(app.world.position_cell(app.world.player.position))
 return app.world.result.is_empty() or app.world.result=="LEVEL COMPLETE!"
func walk(x:int,y:int)->bool:
 var goal=Vector2i(x,y)
 while app.world.position_cell(app.world.player.position)!=goal:
  var p:Vector2i=app.world.position_cell(app.world.player.position)
  var diff=goal-p
  var direction=Vector2i(signi(diff.x),0) if diff.x!=0 else Vector2i(0,signi(diff.y))
  if not await hop(direction):return false
 return true
func road_cross(x:int,from_y:int,to_y:int)->bool:
 # In linked time, safe ordinary hops on the bank choose a clear next beat.
 var row=20
 var step=signi(to_y-from_y)
 for attempt in range(9):
  var safe=true
  for mover in app.world.crossing.movers:
   var cell=app.world.position_cell(mover.node.position)
   if cell.y!=row:continue
   var direction=signi(int(signf(mover.speed)))
   for beat in range(3):
    if abs(cell.x-x)<2:safe=false
    var next=cell+Vector2i(direction,0)
    if not app.world.inside(next) or app.world.level.tiles[next.y][next.x]!="road":direction=-direction
    cell+=Vector2i(direction,0)
  if safe:return await walk(x,to_y)
  if not await hop(Vector2i(0,-step)) or not await hop(Vector2i(0,step)):return false
 return false
func route(index:int,outer:bool=false,delay:float=0)->void:
 app.level=Data.load_json(app.TILE_LEVELS[index])
 app.enter_editor();app.playtest();app.world.set_physics_process(false)
 visited=[];recharge_before_gate=[]
 await ticks(delay)
 var ok=true
 if index==0:
  ok=await walk(8,37) and await hop(Vector2i.UP,true) and await hop(Vector2i.UP,true) and await walk(8,31) and await hop(Vector2i.UP,true)
  if ok:
   if outer:ok=await walk(4,29) and await walk(4,21) and await walk(8,21)
   else:ok=await hop(Vector2i.UP,true) and await walk(8,26) and await hop(Vector2i.UP,true) and await walk(8,23) and await hop(Vector2i.UP,true)
  if ok:ok=await walk(8,16) and await hop(Vector2i.UP,true) and await walk(8,13) and await walk(8,10) and await hop(Vector2i.UP,true) and await walk(8,6) and await hop(Vector2i.UP,true) and await walk(8,2)
 elif index==2:
  for p in [[6,32],[6,31],[6,29],[12,29],[12,31],[12,27],[9,27],[9,26]]:
   if ok:ok=await walk(p[0],p[1])
  if ok:ok=await hop(Vector2i.UP,true)
  if ok:ok=await walk(5,24) and await walk(5,23) and await walk(7,23) and await walk(7,21) and await road_cross(7,21,19) and await walk(7,18) and await walk(15,18) and await walk(15,19) and await road_cross(15,19,21) and await walk(13,21) and await walk(13,23) and await walk(15,23) and await walk(15,21) and await road_cross(15,21,19) and await walk(15,17) and await walk(9,17) and await walk(9,16)
  if ok:ok=await hop(Vector2i.UP,true)
  for p in [[5,14],[5,13],[5,11],[13,11],[13,13],[13,8],[9,8],[9,7]]:
   if ok:ok=await walk(p[0],p[1])
  if ok:ok=await hop(Vector2i.UP,true) and await walk(5,5) and await walk(5,2) and await walk(9,2)
 elif index==3:
  ok=await walk(3,29) and await walk(7,29) and await hop(Vector2i.RIGHT,true) and await walk(17,29) and await walk(17,27) and await walk(18,27) and await walk(18,24) and await hop(Vector2i.UP,true)
  if ok:ok=await walk(15,22) and await walk(15,20) and await walk(12,20) and await walk(12,18) and await hop(Vector2i.LEFT,true) and await walk(4,18) and await walk(4,16) and await hop(Vector2i.UP,true)
  if ok:ok=await walk(6,14) and await walk(6,12) and await walk(9,12) and await walk(9,9) and await hop(Vector2i.RIGHT,true) and await walk(19,9) and await walk(19,5) and await walk(17,5) and await walk(17,2)
 elif index==4:
  ok=await walk(10,38) and await hop(Vector2i.UP,true)
  for p in [[3,36],[3,30],[14,30],[14,27],[10,27],[10,24]]:
   if ok:ok=await walk(p[0],p[1])
  if ok:ok=await hop(Vector2i.UP,true)
  for p in [[17,22],[17,16],[11,16],[11,15],[11,16],[4,16],[4,10],[10,10],[10,8]]:
   if ok:ok=await walk(p[0],p[1])
  if ok:ok=await hop(Vector2i.UP,true) and await walk(12,6) and await walk(12,3) and await walk(10,3) and await walk(10,2)
 var r={"level":app.level.name,"outer_route":outer,"delay":delay,"result":app.world.result,"cell":str(app.world.position_cell(app.world.player.position)),"hops":app.world.tile_rules.hop_count,"long_hops":app.world.tile_rules.long_hops_used,"pickups":app.world.tile_rules.pickups_collected,"elapsed":app.world.elapsed,"checkpoints":app.world.claimed_checkpoints.size(),"gates":recharge_before_gate}
 results.append(r);print("TOUR ROUTE "+JSON.stringify(r))
 if not ok or app.world.result!="LEVEL COMPLETE!" or app.world.claimed_checkpoints.size()!=1:failed=true
func run()->void:
 await process_frame
 app.set_process(false);app.world.set_physics_process(false);app.exit_preview=false;app.set_sound_enabled(false)
 await route(0)
 await route(0,true,1.5)
 await route(2)
 await route(3)
 await route(4)
 print("TILE TOURS ROUTES: "+JSON.stringify(results))
 quit(1 if failed else 0)
