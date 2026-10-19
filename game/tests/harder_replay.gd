extends SceneTree
## Acceptance: fresh-load ordinary input/physics replay. No oracle, state restore,
## teleport, invincibility, or enemy/projectile changes are used in these runs.
const Data=preload("res://scripts/level_data.gd")
var app:Control
var results:Array=[]
var failed=false
func _initialize()->void:
 app=preload("res://main.tscn").instantiate();app.rule_notices_enabled=false
 root.add_child(app);call_deferred("run")
func ticks(seconds:float)->void:
 for i in range(ceili(seconds*60)):
  await physics_frame
  app.world._physics_process(1.0/60)
func run()->void:
 await process_frame
 app.set_process(false);app.world.set_physics_process(false);app.exit_preview=false;app.set_sound_enabled(false)
 for index in range(5):
  var fixture=JSON.parse_string(FileAccess.get_file_as_string("res://tests/routes/harder_%d.json"%index))
  app.level=Data.load_json(fixture.level)
  app.enter_editor();app.playtest();app.world.set_physics_process(false)
  await physics_frame
  var ok=true
  var checkpoint_action=-1
  var action_index=0
  for a in fixture.actions:
   if a.wait>0:await ticks(a.wait)
   if app.world.result!="" or not app.world.tile_rules.request(Vector2i(a.direction[0],a.direction[1]),a.big):ok=false;break
   await ticks(26.0/60)
   if app.world.result not in ["","LEVEL COMPLETE!"]:ok=false;break
   if checkpoint_action<0 and not app.checkpoint_spawn.is_empty():checkpoint_action=action_index
   action_index+=1
  var r={"level":app.level.name,"result":app.world.result,"hops":app.world.tile_rules.hop_count,"long_hops":app.world.tile_rules.long_hops_used,"elapsed":app.world.elapsed,"pickups":app.world.tile_rules.pickups_collected,"checkpoints":app.world.claimed_checkpoints.size(),"position":str(app.world.position_cell(app.world.player.position))}
  results.append(r);print("HARDER REPLAY "+JSON.stringify(r))
  if not ok or app.world.result!="LEVEL COMPLETE!" or app.world.claimed_checkpoints.size()!=1:failed=true
  if ok and checkpoint_action>=0:
   app.retry();app.world.set_physics_process(false)
   await physics_frame
   var retry_ok=true
   var retry_actions=fixture.actions.slice(checkpoint_action+1)
   var retry_path="res://tests/routes/harder_retry_%d.json"%index
   if FileAccess.file_exists(retry_path):retry_actions=JSON.parse_string(FileAccess.get_file_as_string(retry_path)).actions
   for a in retry_actions:
    if a.wait>0:await ticks(a.wait)
    if app.world.result!="" or not app.world.tile_rules.request(Vector2i(a.direction[0],a.direction[1]),a.big):retry_ok=false;break
    await ticks(26.0/60)
    if app.world.result not in ["","LEVEL COMPLETE!"]:retry_ok=false;break
   print("HARDER RETRY "+JSON.stringify({"level":app.level.name,"result":app.world.result,"position":str(app.world.position_cell(app.world.player.position)),"hops":app.world.tile_rules.hop_count,"completed":retry_ok and app.world.result=="LEVEL COMPLETE!","alternate_route":FileAccess.file_exists(retry_path)}))

   if not retry_ok or app.world.result!="LEVEL COMPLETE!":failed=true

 print("HARDER REPLAYS: %d successes of 5"%results.filter(func(r):return r.result=="LEVEL COMPLETE!").size())
 quit(1 if failed else 0)
