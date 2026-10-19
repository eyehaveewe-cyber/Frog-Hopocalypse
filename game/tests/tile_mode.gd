extends SceneTree
const Data = preload("res://scripts/level_data.gd")
const Suite = preload("res://tests/integration.gd")
var suite = Suite.new()
var app: Control
func _initialize() -> void:
 app = preload("res://main.tscn").instantiate()
 root.add_child(app)
 call_deferred("run")
func fresh(linked: bool = true) -> void:
 app.level = Data.blank("Tile metrics", "egypt",11,11)
 app.level.game_mode = "tile"
 app.level.move_with_me = linked
 app.level.spawn = [3,6]
 app.enter_editor()
 app.playtest()
 app.world.set_physics_process(false)
func tick(seconds: float) -> void:
 for i in range(ceili(seconds*60)):
  await physics_frame
  app.world._physics_process(1.0/60.0)
func run() -> void:
 await process_frame
 app.set_process(false)
 app.world.set_physics_process(false)
 app.exit_preview = false
 app.set_sound_enabled(false)
 for path in app.TILE_LEVELS + [app.MOVE_DEMO]:
  var level := Data.load_json(path)
  suite.check(not level.is_empty() and Data.reachable(level), "Authored large demo has valid schema and a structurally achievable route: " + path)
 app.completed_stages=[]
 suite.check(not app.tile_mode_unlocked() and not app.load_builtin(0,"tile"), "Fresh profile cannot bypass the Not as Hard as It Looks unlock")
 app.completed_stages=[0,1,2,3]
 suite.check(not app.tile_mode_unlocked() and not app.load_builtin(0,"tile"),"Baby Mode completion alone does not unlock Tile Hop")
 app.completed_human_stages=[0,1,2]
 app.play_builtin(3,"human")
 app.world.finish("LEVEL COMPLETE!")
 app.world.result_time=2.3
 app.update_result_presentation()
 suite.check(app.tile_mode_unlocked() and app.overlay_box.find_children("*","Button",true,false).any(func(b):return b.text=="Start · Tile Hop"),"Fourth Not as Hard as It Looks clear offers the newly unlocked Tile Hop mode")
 suite.check(app.tile_mode_unlocked() and app.load_builtin(0,"tile"), "All four Not as Hard as It Looks stages unlock the separate tile set")
 fresh()
 suite.check(app.world.tile_rules != null and app.world.player.visual.scale.x == 1.5, "Tile mode builds the larger frog and grid simulation")
 suite.check(app.long_hop_button.visible and not app.edit_button.visible,"Tile play exposes Long hop and keeps Editor hidden")
 app.update_long_hop_indicator()
 suite.check(app.long_hop_indicator.text=="READY","Tile long hop starts ready")
 app.long_hop_button.set_pressed_no_signal(true)
 app.update_long_hop_indicator()
 suite.check(app.long_hop_indicator.text=="ARMED","Touch selection is visibly armed")
 app.world.tile_rules.request(Vector2i.RIGHT,true)
 app.update_long_hop_indicator()
 suite.check(app.long_hop_indicator.text=="HOPPING" and not app.long_hop_button.button_pressed,"Accepted hop clears arming and displays hopping")
 await tick(0.4)
 app.update_long_hop_indicator()
 suite.check(app.long_hop_indicator.text=="READY","Indicator returns ready after landing")
 app.world.tile_rules.repeat_clock=0.15
 app.update_long_hop_indicator()
 suite.check(app.long_hop_indicator.text=="WAIT","Blocked-input recovery displays wait")
 app.world.tile_rules.repeat_clock=0.08
 app.update_long_hop_indicator()
 suite.check(app.long_hop_indicator.text=="READY" and app.world.tile_rules.ready_for_input(),"Ready matches the queued input acceptance threshold")
 app.world.map_view=true
 app.update_long_hop_indicator()
 suite.check(app.long_hop_indicator.text=="PAUSED","Map inspection cannot imply a hop is available")
 fresh()

 var p: Vector3 = app.world.player.position
 await tick(1)
 suite.check(app.world.elapsed == 0 and app.world.player.position == p,"Move with me has no simulation time while idle")
 suite.check(app.world.tile_rules.request(Vector2i.UP,false),"Single cardinal hop is accepted")
 await tick(0.4)
 suite.check(app.world.position_cell(app.world.player.position)==Vector2i(3,5) and app.world.player.visual.position.y==0,"One hop lands exactly at the next tile center")
 suite.check(app.world.tile_rules.beat_count == 1,"One accepted hop advances one hazard beat")
 app.level.tiles[4][3]="wall"
 app.world.level.tiles[4][3]="wall"
 var beats: int = app.world.tile_rules.beat_count
 suite.check(not app.world.tile_rules.request(Vector2i.UP,true) and app.world.tile_rules.beat_count == beats,"Long hop cannot pass through a wall or advance a blocked turn")
 app.world.level.tiles[4][3]="cheese_wall"
 suite.check(not app.world.tile_rules.request(Vector2i.UP,true),"Cheese walls also block a long hop")
 app.world.level.tiles[4][3]="floor"
 app.world.level.objects.append({"id":"obstacle","type":"pillar","pos":[3,4],"solid":true})
 suite.check(app.world.tile_rules.request(Vector2i.UP,true),"Long hop can clear a non-wall obstacle in the middle tile")
 await tick(0.18)
 suite.check(app.world.tile_rules.airborne() and app.world.player.visual.position.y > 1,"Long hop has a visibly raised airborne phase")
 await tick(0.25)
 suite.check(app.world.position_cell(app.world.player.position)==Vector2i(3,3) and app.world.result.is_empty(),"Two-tile hop lands safely beyond the obstacle")
 fresh()
 app.level.objects=[{"id":"bug","type":"critter","pos":[3,5],"behavior":"patrol","waypoints":[[3,5]],"patrol_loop":false,"speed":1.6}]
 # Stationary critter fixture models a danger on the skipped middle tile.
 app.world.load_level(app.level,false,app.hat)
 app.world.tile_rules.request(Vector2i.UP,true)
 await tick(0.4)
 suite.check(app.world.result.is_empty() and app.world.position_cell(app.world.player.position)==Vector2i(3,4),"Airborne long hop clears a middle-tile enemy")
 fresh()
 app.world.spawn_projectile(app.world.cell_position([3,5])+Vector3(0,0.36,0),Vector3.ZERO)
 app.world.tile_rules.request(Vector2i.UP,true)
 await tick(0.4)
 suite.check(app.world.result.is_empty(),"Airborne long hop clears a middle-tile projectile")
 fresh()
 app.world.spawn_projectile(app.world.cell_position([3,5])+Vector3(0,0.36,0),Vector3.ZERO)
 app.world.tile_rules.request(Vector2i.UP,false)
 await tick(0.4)
 suite.check(app.world.result=="HIT!","Short hop stays vulnerable to the projectile")
 fresh()
 app.world.level.tiles[5][3]="water"
 app.world.tile_rules.request(Vector2i.UP,true)
 await tick(0.4)
 suite.check(app.world.result.is_empty(),"A long hop clears a one-tile water gap")
 fresh()
 app.world.level.tiles[5][3]="water"
 app.world.tile_rules.request(Vector2i.UP,false)
 await tick(0.4)
 suite.check(app.world.result=="SPLASHED!","Landing on unsupported water still drowns the frog")
 fresh()
 app.level.objects=[{"id":"patrol","type":"critter","pos":[7,2],"behavior":"patrol","waypoints":[[7,4],[5,4]],"patrol_loop":true,"speed":1.6}]
 app.world.load_level(app.level,false,app.hat)
 p=app.world.critters[0].position
 await tick(1)
 suite.check(app.world.critters[0].position==p,"Tile enemies remain frozen until a hop in Move with me")
 app.world.tile_rules.request(Vector2i.UP,false)
 await tick(0.4)
 suite.check(app.world.critters[0].position==app.world.cell_position([7,3]),"Enemy beat moves exactly one cardinal tile, without a diagonal")
 fresh()
 for x in range(1,10):
  app.level.tiles[2][x]="road"
  app.level.tiles[3][x]="water"
 app.level.tiles[3][7]="road"
 app.level.tiles[4][7]="road"
 app.level.objects=[{"id":"car","type":"car","pos":[2,2],"speed":1.0,"direction":1,"length":1.0},{"id":"log","type":"log","pos":[2,3],"speed":1.0,"direction":1,"length":3.0},{"id":"police","type":"patrol_car","pos":[7,2],"speed":1.0,"direction":1,"length":1.0,"axis":"north_south"},{"id":"trap","type":"emitter","pos":[1,8],"rotation":270,"interval":1.0}]
 app.world.load_level(app.level,false,app.hat)
 app.world.tile_rules.request(Vector2i.UP,false)
 await tick(0.4)
 var movers: Array=app.world.crossing.movers
 suite.check(movers[0].node.position==app.world.cell_position([3,2]),"Tile traffic advances one whole road tile per beat")
 suite.check(movers[1].node.position==app.world.cell_position([3,3]),"Logs advance one whole water tile per beat")
 suite.check(movers[2].node.position==app.world.cell_position([7,3]),"North-south patrol cars use the same tile beat")
 suite.check(app.world.projectiles.size()==1 and app.world.position_cell(app.world.projectiles[0].node.position)==Vector2i(3,8),"Darts emit from a cardinal tile and advance one cell in the beat")
 var shot_pos: Vector3=app.world.projectiles[0].node.position
 var shot_life: float=app.world.projectiles[0].life
 await tick(1)
 suite.check(app.world.projectiles[0].node.position==shot_pos and app.world.projectiles[0].life==shot_life and movers[0].node.position==app.world.cell_position([3,2]),"Idle Move with me freezes cars, logs, projectiles and projectile lifetime")
 app.world.player.position=app.world.cell_position([3,3])
 app.world.tile_rules.request(Vector2i.RIGHT,false)
 await tick(0.4)
 suite.check(app.world.result.is_empty() and app.world.player.position==app.world.cell_position([4,3]),"Landing on a moving log stays on the exact tile center without double carry")
 fresh(false)
 await tick(0.75)
 suite.check(app.world.elapsed > 0.7 and app.world.tile_rules.beat_count==1,"Regular tile mode continues ticking hazards while the frog rests")
 app.level = Data.blank("Regular time rule","egypt",11,11)
 app.level.move_with_me=true
 app.level.objects=[{"id":"patrol","type":"critter","pos":[7,2],"behavior":"patrol","waypoints":[[7,4]],"speed":1.6}]
 app.enter_editor()
 app.playtest()
 p=app.world.critters[0].position
 await tick(0.5)
 suite.check(app.world.elapsed==0 and app.world.critters[0].position==p and app.world.tile_rules==null,"Regular Hopán can freeze hazards while idle without grid movement")
 app.world.input_vector=Vector2.UP
 await tick(0.25)
 suite.check(app.world.elapsed>0 and app.world.critters[0].position!=p,"Actual regular Hopán movement advances enemies and time")
 app.world.input_vector=Vector2.ZERO
 var elapsed: float=app.world.elapsed
 p=app.world.critters[0].position
 await tick(0.4)
 suite.check(app.world.elapsed==elapsed and app.world.critters[0].position==p,"Releasing regular movement freezes the world again")
 app.open_movement_demo(0)
 suite.check(app.mode=="edit" and app.tile_mode_toggle.button_pressed and not app.movement_toggle.button_pressed,"Editor demo picker loads ordinary tile mode without changing the original maps")
 app.set_level_rule("move_with_me",true)
 var roundtrip: Dictionary=Data.normalize(JSON.parse_string(JSON.stringify(app.level)))
 suite.check(roundtrip.move_with_me and roundtrip.game_mode=="tile" and Data.validate(roundtrip).is_empty(),"Movement/editor settings round-trip in portable JSON")
 app.world.set_map_view(false)
 app.playtest()
 var chunks: Array=app.world.geometry.find_children("*","MultiMeshInstance3D",true,false).filter(func(n): return n.get_meta("spatial_chunk",false))
 suite.check(chunks.size()>10 and app.world.camera.far < app.level.height*app.world.CELL,"Large demo uses spatial rendering chunks and a draw range shorter than its length")
 app.world.set_map_view(true)
 suite.check(app.world.camera.far >= 200 and chunks.all(func(n):return n.visibility_range_end==0),"Overhead map restores full distance and visibility")
 app.completed_tile_stages=[0]
 app.save_profile()
 app.completed_tile_stages=[]
 app.load_profile()
 suite.check(app.completed_tile_stages==[0] and app.completed_stages==[0,1,2,3],"Tile progress persists separately from Baby Mode")
 fresh()
 app.world.level.checkpoint=[3,4]
 app.world.tile_rules.request(Vector2i.UP,true)
 await tick(0.4)
 suite.check(app.checkpoint_spawn==[3,4],"Converted tile maps retain the legacy bank-checkpoint behavior")
 app.level=Data.blank("Snap old objects", "egypt",11,11)
 app.level.tiles[3][2]="road"
 app.level.objects=[{"id":"old-car","type":"car","pos":[2.4,3],"speed":1.0,"length":1.0}]
 app.enter_editor()
 app.set_level_rule("game_mode","tile")
 suite.check(app.level.objects[0].pos==[2,3] and Data.validate(app.level).is_empty(),"Editor converts legacy off-center objects onto their owned grid tile")
 app.undo()
 suite.check(app.level.objects[0].pos==[2.4,3] and app.level.get("game_mode","hopan")=="hopan","Undo restores the original mode and off-center authoring data")
 fresh()
 app.world.tile_rules.queue_hop(Vector2i.UP,true)
 app.world.input_vector=Vector2.ZERO
 await tick(0.4)
 suite.check(app.world.position_cell(app.world.player.position)==Vector2i(3,4),"A short queued input remains a two-tile hop even when released before the next physics frame")
 app.level=Data.blank("Blocked continuous movement","egypt",11,11)
 app.level.spawn=[3,6]
 app.level.move_with_me=true
 app.level.tiles[5][3]="wall"
 app.enter_editor()
 app.playtest()
 app.world.input_vector=Vector2.UP
 await tick(0.6)
 var stopped_time: float=app.world.elapsed
 await tick(0.5)
 suite.check(app.world.elapsed==stopped_time,"Holding regular movement against a wall stops the linked world after physical contact")
 print("TILE MODE: %d checks, %d failures" % [suite.checks,suite.failures.size()])
 quit(0 if suite.failures.is_empty() else 1)
