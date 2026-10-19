extends SceneTree
const Data=preload("res://scripts/level_data.gd")
const Suite=preload("res://tests/integration.gd")
var suite=Suite.new()
var app:Control
func _initialize()->void:
 app=preload("res://main.tscn").instantiate();app.rule_notices_enabled=false
 root.add_child(app);call_deferred("run")
func ticks(seconds:float)->void:
 for i in range(ceili(seconds*60)):
  await physics_frame
  app.world._physics_process(1.0/60)
func fresh(mode:String)->void:
 app.level=Data.blank("Resource rules","egypt",11,11)
 app.level.game_mode="tile";app.level.move_with_me=true;app.level.rules={"long_hop":mode,"charge_hops":25}
 app.level.spawn=[3,8];app.level.exit=[9,1]
 app.level.objects=[{"id":"a","type":"hop_fragment" if mode=="fragments" else "hop_seed","pos":[3,7],"solid":false},{"id":"b","type":"hop_fragment" if mode=="fragments" else "hop_seed","pos":[3,6],"solid":false},{"id":"c","type":"hop_fragment" if mode=="fragments" else "hop_seed","pos":[3,5],"solid":false},{"id":"extra","type":"hop_fragment" if mode=="fragments" else "hop_seed","pos":[3,4],"solid":false}]
 app.level.checkpoints=[[3,5]]
 app.enter_editor();app.playtest();app.world.set_physics_process(false)
func hop(direction:Vector2i,big:bool=false)->bool:
 var accepted:bool=app.world.tile_rules.request(direction,big)
 if accepted:await ticks(.42)
 return accepted
func run()->void:
 await process_frame
 app.set_process(false);app.world.set_physics_process(false);app.exit_preview=false;app.set_sound_enabled(false)
 suite.check(app.TILE_LEVELS.size()==5,"Tile set has five ordered stages")
 for path in app.TILE_LEVELS:
  var d=Data.load_json(path)
  suite.check(not d.is_empty() and Data.reachable(d) and d.get("checkpoints",[]).size()==1,"One checkpoint and structural route: "+path)
 fresh("fragments")
 var rules=app.world.tile_rules
 suite.check(not rules.long_hop_ready() and not rules.request(Vector2i.UP,true) and rules.beat_count==0,"Fragments start empty; an empty long hop spends no move")
 await hop(Vector2i.UP)
 suite.check(rules.fragments==1 and not app.world.hop_pickups[0].node.visible,"Landing collects a fragment and removes its visible mesh")
 await hop(Vector2i.UP)
 suite.check(rules.fragments==2 and not rules.long_hop_ready(),"Two fragments are insufficient")
 await hop(Vector2i.UP)
 suite.check(rules.fragments==0 and rules.long_hop_ready(),"Third fragment grants exactly one reserve")
 suite.check(app.checkpoint_hop_state.reserve and app.checkpoint_hop_state.collected.size()==3,"Checkpoint captures the earned resource and collected IDs")
 await hop(Vector2i.UP)
 suite.check(rules.collected.size()==3 and app.world.hop_pickups[3].node.visible,"Full reserve leaves the extra pickup available")
 suite.check(rules.request(Vector2i.LEFT,true) and not rules.reserve,"A valid long hop spends the reserve")
 await ticks(.42)
 app.retry();app.world.set_physics_process(false);rules=app.world.tile_rules
 suite.check(rules.long_hop_ready() and rules.collected.size()==3 and app.world.hop_pickups[3].node.visible and app.world.position_cell(app.world.player.position)==Vector2i(3,5),"Retry restores checkpoint resource and hides only pickups already collected there")
 # Land beyond the remaining pickup; the skipped middle cell is not collected.
 await hop(Vector2i.UP,true)
 suite.check(rules.collected.size()==3 and not rules.reserve,"Airborne traversal does not collect a skipped pickup")
 await hop(Vector2i.DOWN)
 suite.check(rules.fragments==1,"An uncollected extra fragment remains usable after spending reserve")
 app.checkpoint_spawn=[];app.checkpoint_history=[];app.retry();app.world.set_physics_process(false)
 suite.check(not app.world.tile_rules.reserve and app.world.tile_rules.collected.is_empty() and app.world.hop_pickups.all(func(p):return p.node.visible),"Restart before any checkpoint resets the collection route")
 fresh("powerup");rules=app.world.tile_rules
 await hop(Vector2i.UP)
 suite.check(rules.reserve and rules.collected.size()==1,"One diamond seed grants one hop")
 await hop(Vector2i.UP)
 suite.check(rules.collected.size()==1 and app.world.hop_pickups[1].node.visible,"Seeds cannot be accidentally consumed while full")
 app.world.level.tiles[5][3]="wall"
 suite.check(not rules.request(Vector2i.UP,true) and rules.reserve,"Blocked long hop keeps a seed reserve")
 app.world.level.tiles[5][3]="floor"
 await hop(Vector2i.RIGHT,true)
 suite.check(not rules.reserve,"One valid long hop spends exactly one seed reserve")
 await ticks(2)
 suite.check(not rules.reserve,"Waiting does not regenerate a seed")
 for i in range(26):await hop(Vector2i.UP if i%2==0 else Vector2i.DOWN)
 suite.check(not rules.reserve,"Ordinary hopping never refills a pickup rule")
 app.update_long_hop_indicator();app.activate_long_hop()
 suite.check(app.rule_notice_open and not app.long_hop_button.button_pressed,"Empty thumb button opens rules instead of arming an unavailable hop")
 app.close_level_rules()
 fresh("charged");rules=app.world.tile_rules
 await hop(Vector2i.RIGHT,true)
 for i in range(24):await hop(Vector2i.UP if i%2==0 else Vector2i.DOWN)
 suite.check(rules.charge_remaining==1 and not rules.long_hop_ready(),"25-hop rule remains empty after 24 short landings")
 await hop(Vector2i.UP)
 suite.check(rules.long_hop_ready(),"25th short landing refills the reserve")
 var event:=InputEventKey.new();event.pressed=true;event.keycode=KEY_SPACE
 app._input(event)
 suite.check(app.long_hop_button.button_pressed,"Space arms the same next-hop control as touch")
 var dir:=InputEventKey.new();dir.pressed=true;dir.keycode=KEY_RIGHT
 app._input(dir);await ticks(.42)
 suite.check(rules.long_hops_used==2 and not app.long_hop_button.button_pressed,"Space then a direction consumes one long hop and clears arming")
 fresh("free")
 app.enter_editor();app.change_hop_rule("long_hop","fragments")
 app.set_tool("hop_fragment");app.edit_cell(Vector2i(5,5));app.stroke_changed=false
 suite.check(app.level.rules.long_hop=="fragments" and app.level.objects[-1].type=="hop_fragment","Editor authors fragment rules and pickups")
 app.undo()
 suite.check(not app.level.objects.any(func(o):return o.pos==[5,5]),"Pickup placement participates in Undo")
 var d=Data.normalize(JSON.parse_string(JSON.stringify(app.level)))
 suite.check(Data.validate(d)=="" and d.rules.long_hop=="fragments","Portable JSON round trips rules and pickups")
 var bad=d.duplicate(true);bad.objects[0].solid=true
 suite.check(Data.validate(bad)!="","Solid pickups are rejected")
 bad=d.duplicate(true);bad.objects[0].pos=[1.5,3]
 suite.check(Data.validate(bad)!="","Off-grid pickups are rejected")
 bad=d.duplicate(true);bad.objects[0].pos=[0,0]
 suite.check(Data.validate(bad)!="","Pickups inside walls are rejected")
 bad=d.duplicate(true);bad.objects[1].pos=bad.objects[0].pos
 suite.check(Data.validate(bad)!="","Overlapping pickups are rejected")
 bad=d.duplicate(true);bad.objects.append({})
 suite.check(Data.validate(bad)!="","A malformed peer cannot crash pickup validation")
 app.set_tool("hop_seed");app.edit_cell(Vector2i(5,6));app.stroke_changed=false
 app.set_tool("road");app.edit_cell(Vector2i(5,6))
 suite.check(app.level.tiles[6][5]!="road","Painting road cannot leave an invalid pickup on traffic terrain")
 app.completed_human_stages=[0,1,2,3];app.completed_tile_stages=[0,1,2,3]
 app.play_builtin(4,"tile");app.world.set_physics_process(false);app.world.finish("LEVEL COMPLETE!");app.world.result_time=2.3;app.update_result_presentation()
 suite.check(app.completed_tile_stages.size()==5 and not app.overlay_box.find_children("*","Button",true,false).any(func(b):return b.text=="Retry" or b.text.begins_with("Next")),"Fifth-stage completion ends the set without Retry or a nonexistent next stage")
 print("TOUR RULES: %d checks, %d failures"%[suite.checks,suite.failures.size()])
 quit(0 if suite.failures.is_empty() else 1)
