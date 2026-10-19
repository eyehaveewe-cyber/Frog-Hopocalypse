extends SceneTree
const Data=preload("res://scripts/level_data.gd")
const Suite=preload("res://tests/integration.gd")
var suite=Suite.new()
var app:Control
var records:Array=[]
func _initialize()->void:
 app=preload("res://main.tscn").instantiate();app.rule_notices_enabled=false
 root.add_child(app);call_deferred("run")
func run()->void:
 await process_frame
 app.set_process(false);app.world.set_physics_process(false);app.exit_preview=false;app.set_sound_enabled(false)
 for path in app.TILE_LEVELS:
  var d:Dictionary=Data.normalize(JSON.parse_string(FileAccess.get_file_as_string(path)))
  var error=Data.validate(d)
  suite.check(error=="" and Data.reachable(d),"Harder map validates: "+path+" "+error)
  if error!="":continue
  suite.check(d.checkpoints.size()==1,"One checkpoint retained: "+d.name)
  app.level=d;app.enter_editor();app.playtest();app.world.set_physics_process(false)
  await physics_frame
  for i in range(app.world.emitters.size()):
   var emitter=app.world.emitters[i]
   var origin:Vector2i=app.world.position_cell(emitter.pos)
   var dir=Vector2i(roundi(emitter.dir.x),roundi(emitter.dir.z))
   var here=origin+dir
   var target=Vector2i(-1,-1)
   while app.world.inside(here):
    if d.tiles[here.y][here.x]=="cheese_wall":target=here;break
    if d.tiles[here.y][here.x]=="wall" or d.objects.any(func(o):return o.pos==[here.x,here.y] and (o.type in ["pillar","tree","emitter"] or o.get("solid",false))):break
    here+=dir
   suite.check(target.x>=0,"Turret fires toward unobstructed cheese: "+d.name+str(origin)+" dir "+str(dir))
   if target.x<0:continue
   var from:Vector3=emitter.pos+emitter.dir*.9
   var to:Vector3=app.world.cell_position([target.x,target.y])+Vector3(0,.42,0)
   var query=PhysicsRayQueryParameters3D.create(from,to,1)
   suite.check(app.world.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),"Actual wall collision leaves the cheese firing line clear")
   query.collision_mask=8
   suite.check(not app.world.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),"The firing line intersects the actual cheese collider")
   var forward:Vector3=emitter.model.global_basis*Vector3.FORWARD
   suite.check(forward.dot(emitter.dir)>.99,"Visible barrel and projectile direction agree")
   records.append({"level":d.name,"turret":[origin.x,origin.y],"direction":[dir.x,dir.y],"cheese":[target.x,target.y]})
 # Real projectile traversal, four cardinal facings, without disabling collision.
 for angle in [0,90,180,270]:
  var dir3=Vector3.FORWARD.rotated(Vector3.UP,deg_to_rad(angle))
  var dir=Vector2i(roundi(dir3.x),roundi(dir3.z))
  var d=Data.blank("Dart cheese fixture","egypt",11,11)
  d.game_mode="tile";d.spawn=[1,9];d.exit=[9,9]
  var target=Vector2i(5,5)+dir*2
  d.tiles[target.y][target.x]="cheese_wall"
  d.objects=[{"id":"gun","type":"emitter","pos":[5,5],"rotation":angle,"interval":2,"solid":true}]
  app.level=d;app.enter_editor();app.playtest();app.world.set_physics_process(false)
  await physics_frame
  app.world.spawn_projectile(app.world.cell_position([5,5])+Vector3(0,.36,0)+dir3*app.world.CELL,dir3)
  for beat in range(3):
   app.world.tile_rules.begin_beat()
   for tick in range(21):
    await physics_frame
    app.world._physics_process(1.0/60)
  suite.check(app.world.projectiles.any(func(shot):return (shot.node.position-app.world.cell_position([5,5])).dot(dir3)>app.world.CELL*2.5),"A live dart passes through cheese facing "+str(angle))
 print("DART ALIGNMENTS "+JSON.stringify(records))
 print("HARDER DARTS: %d checks, %d failures"%[suite.checks,suite.failures.size()])
 quit(0 if suite.failures.is_empty() else 1)
