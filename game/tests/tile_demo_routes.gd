extends SceneTree
const Data = preload("res://scripts/level_data.gd")
var app: Control
var failures: Array=[]
var results: Array=[]
func _initialize() -> void:
 app=preload("res://main.tscn").instantiate()
 root.add_child(app)
 call_deferred("run")
func ticks(seconds: float) -> void:
 for i in range(ceili(seconds*60)):
  await physics_frame
  app.world._physics_process(1.0/60.0)
func hop(dir: Vector2i, big: bool) -> bool:
 if not app.world.result.is_empty(): return false
 if not app.world.tile_rules.request(dir,big): return false
 await ticks(0.42)
 return app.world.result.is_empty() or app.world.result=="LEVEL COMPLETE!"
func run() -> void:
 await process_frame
 app.set_process(false)
 app.world.set_physics_process(false)
 app.set_sound_enabled(false)
 app.exit_preview=false
 # Complete routes with hazards active and the real hop interpolation/collision checks.
 app.open_movement_demo(0)
 app.playtest()
 var skipped_rows: Array=[43,37,31,25,22,19,15,12,9]
 var limit:=0
 while app.world.result.is_empty() and limit<60:
  var row: int=app.world.position_cell(app.world.player.position).y
  if row==2: break
  if not await hop(Vector2i.UP,row-1 in skipped_rows): break
  limit+=1
 var r={"level":app.level.name,"result":app.world.result,"hops":app.world.tile_rules.hop_count,"elapsed":app.world.elapsed,"position":app.world.position_cell(app.world.player.position)}
 results.append(r)
 if app.world.result!="LEVEL COMPLETE!":failures.append(r)
 app.open_movement_demo(1)
 app.playtest()
 limit=0
 while app.world.result.is_empty() and limit<80:
  var cell: Vector2i=app.world.position_cell(app.world.player.position)
  var direction:=Vector2i.RIGHT if cell.y==22 and cell.x<17 else Vector2i.UP
  var big: bool=direction==Vector2i.UP and cell.y-1 in [36,34,29,24,18,16,12,7]
  if not await hop(direction,big): break
  limit+=1
 r={"level":app.level.name,"result":app.world.result,"hops":app.world.tile_rules.hop_count,"beats":app.world.tile_rules.beat_count,"elapsed":app.world.elapsed,"position":app.world.position_cell(app.world.player.position)}
 results.append(r)
 if app.world.result!="LEVEL COMPLETE!":failures.append(r)
 app.open_movement_demo(2)
 app.playtest()
 app.world.input_vector=Vector2.UP
 for i in range(1800):
  await physics_frame
  app.world._physics_process(1.0/60.0)
  if not app.world.result.is_empty():break
 r={"level":app.level.name,"result":app.world.result,"elapsed":app.world.elapsed,"position":app.world.position_cell(app.world.player.position)}
 results.append(r)
 if app.world.result!="LEVEL COMPLETE!":failures.append(r)
 print("DEMO ROUTES: "+JSON.stringify(results))
 for failure in failures: print("FAILED ROUTE: "+JSON.stringify(failure))
 quit(0 if failures.is_empty() else 1)
