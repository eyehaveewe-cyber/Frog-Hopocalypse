extends SceneTree
const Data=preload("res://scripts/level_data.gd")
const Rules=preload("res://scripts/level_rules.gd")
const Suite=preload("res://tests/integration.gd")
var suite=Suite.new()
var app: Control
func _initialize() -> void:
 app=preload("res://main.tscn").instantiate()
 root.add_child(app)
 call_deferred("run")
func ticks(seconds: float) -> void:
 for i in range(ceili(seconds*60)):
  await physics_frame
  app.world._physics_process(1.0/60)
func hop(direction: Vector2i,big: bool=false) -> bool:
 if not app.world.tile_rules.request(direction,big):return false
 await ticks(0.42)
 return true
func fresh() -> void:
 app.level=Data.blank("Rules test","egypt",11,11)
 app.level.spawn=[5,7]
 app.level.game_mode="tile"
 app.level.rules={"long_hop":"charged","charge_hops":10}
 app.enter_editor()
 app.playtest()
func run() -> void:
 await process_frame
 app.set_process(false)
 app.world.set_physics_process(false)
 app.exit_preview=false
 app.set_sound_enabled(false)
 app.seen_rule_ids=[]
 fresh()
 suite.check(app.rule_notice_open and app.world.halted,"Unseen per-level rules pause before play")
 var elapsed: float=app.world.elapsed
 await ticks(1)
 suite.check(app.world.elapsed==elapsed,"Rule reading advances neither hazards nor game clock")
 suite.check(app.pending_rule_ids==["tile-v2","charge-10-v1"],"Only the rules active on this level are introduced")
 app.close_level_rules()
 suite.check(not app.world.halted and "charge-10-v1" in app.seen_rule_ids,"Acknowledging rules resumes and remembers them")
 app.save_profile()
 app.seen_rule_ids=[]
 app.load_profile()
 suite.check("charge-10-v1" in app.seen_rule_ids,"Seen rules survive profile reload")
 fresh()
 suite.check(not app.rule_notice_open and not app.overlay.visible,"Known rules do not interrupt another start")
 app.show_level_rules(false)
 suite.check(app.rule_notice_open,"Rules can be reopened at any time")
 app.show_level_rules(false)
 app.close_level_rules()
 suite.check(not app.world.halted,"Repeated rule-open input cannot leave the world stuck on pause")
 suite.check(app.world.tile_rules.long_hop_ready(),"Charged levels start with a full reserve")
 var start: Vector3=app.world.player.position
 suite.check(await hop(Vector2i.UP,true),"A charged long hop is accepted")
 suite.check(app.world.tile_rules.charge_remaining==10,"Long hop consumes the reserve without counting itself toward recharge")
 var count: int=app.world.tile_rules.hop_count
 suite.check(not app.world.tile_rules.request(Vector2i.DOWN,true) and app.world.tile_rules.hop_count==count,"An empty long hop cannot move or advance the linked beat")
 app.update_long_hop_indicator()
 suite.check(app.long_hop_indicator.text=="10 SHORT HOPS" and not app.long_hop_button.disabled,"HUD names the remaining hops and keeps rule help accessible")
 await ticks(2)
 suite.check(app.world.tile_rules.charge_remaining==10,"Idle time never recharges")
 for i in range(9):await hop(Vector2i.LEFT if i%2==0 else Vector2i.RIGHT)
 suite.check(app.world.tile_rules.charge_remaining==1,"Nine completed ordinary hops leave one remaining")
 app.world.tile_rules.request(Vector2i.RIGHT,false)
 suite.check(app.world.tile_rules.charge_remaining==1,"Taking off does not count as a completed ordinary hop")
 await ticks(0.42)
 suite.check(app.world.tile_rules.long_hop_ready(),"The tenth landing restores the reserve")
 app.world.level.tiles[4][5]="wall"
 suite.check(not app.world.tile_rules.request(Vector2i.UP,true) and app.world.tile_rules.long_hop_ready(),"A wall-blocked long hop never spends charge")
 app.checkpoint_spawn=[3,7]
 app.world.tile_rules.charge_remaining=8
 app.retry()
 suite.check(app.world.tile_rules.long_hop_ready() and app.world.position_cell(app.world.player.position)==Vector2i(3,7),"Checkpoint retry restores charge and the checkpoint position")
 suite.check(not app.rule_notice_open,"Retry does not repeat the rule introduction")
 app.level.rules.long_hop="free"
 app.playtest()
 suite.check(app.pending_rule_ids==["free-long-hop-v1"],"Changing to a new rule only introduces that changed rule")
 app.close_level_rules()
 await hop(Vector2i.UP,true)
 suite.check(app.world.tile_rules.long_hop_ready(),"Free long-hop levels retain unlimited long hops")
 app.enter_editor()
 app.hop_rule_picker.item_selected.emit(1)
 suite.check(Rules.charged(app.level),"Editor can assign charged hops per level")
 app.hop_charge_picker.value=12
 suite.check(app.level.rules.charge_hops==12,"Editor spinner saves the per-level recharge count")
 app.undo()
 suite.check(Rules.charge_hops(app.level)==10,"Recharge-count edits participate in Undo")
 app.undo()
 suite.check(not Rules.charged(app.level),"Rule edits participate in Undo")
 var roundtrip: Dictionary=Data.normalize(JSON.parse_string(JSON.stringify(app.level)))
 suite.check(Data.validate(roundtrip)=="" and roundtrip.rules.long_hop=="free","Portable JSON preserves per-level rules")
 roundtrip.rules.charge_hops=2.5
 suite.check(Data.validate(roundtrip)!="","Fractional recharge values are rejected")
 roundtrip.rules={"long_hop":"unknown"}
 suite.check(Data.validate(roundtrip)!="","Unsupported rules cannot silently load")
 roundtrip.rules=[]
 suite.check(Data.validate(roundtrip)!="","Malformed rules are rejected before gameplay")
 var normal: Dictionary=app.level.duplicate(true)
 normal.game_mode="hopan"
 normal.rules={"long_hop":"charged","charge_hops":10}
 suite.check(not Rules.charged(normal) and not Rules.cards(normal).any(func(card):return card.id.begins_with("charge-")),"Regular Hopán does not apply a tile-only charge rule")
 normal.game_mode="tile"
 normal.rules.charge_hops=12
 suite.check(Rules.cards(normal).any(func(card):return card.id=="charge-12-v1"),"A changed recharge amount has its own first-seen notice")
 app.world.map_view=true
 app.show_level_rules(false)
 app.close_level_rules()
 suite.check(app.world.map_view,"Reopening rules from the map preserves map pause on return")
 app.world.map_view=false
 app.rule_notices_enabled=false
 app.open_movement_demo(3)
 app.playtest()
 var ok: bool=await hop(Vector2i.UP) and await hop(Vector2i.UP,true)
 for i in range(10):ok=await hop(Vector2i.UP) and ok
 ok=await hop(Vector2i.UP,true) and ok
 for i in range(7):ok=await hop(Vector2i.UP) and ok
 suite.check(ok and app.world.result=="LEVEL COMPLETE!","Charge Trial completes through two water gates with exactly ten recharge hops between")
 suite.check(app.world.claimed_checkpoints.size()==1,"Charge Trial reaches its refuge checkpoint")
 print("LEVEL RULES: %d checks, %d failures" % [suite.checks,suite.failures.size()])
 quit(0 if suite.failures.is_empty() else 1)
