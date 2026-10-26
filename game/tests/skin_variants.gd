extends SceneTree
const Suite = preload("res://tests/integration.gd")
const Art = preload("res://scripts/art.gd")
const Pixels = preload("res://scripts/pixel_textures.gd")
var suite = Suite.new()
var app: Control
func _initialize() -> void:
 app=preload("res://main.tscn").instantiate()
 root.add_child(app)
 call_deferred("run")
func run() -> void:
 await process_frame
 app.set_process(false)
 app.world.set_physics_process(false)
 app.completed_stages=[]
 app.skin="green"
 app.toggle_skin()
 suite.check(app.skin=="green","Purple cannot be selected before Baby Mode completion")
 app.completed_stages=[0,1,2]
 app.unlocked_hats=["none","pharaoh"]
 app.play_builtin(3,"baby")
 app.on_finished("LEVEL COMPLETE!")
 suite.check(app.skin=="purple" and app.completed_stages.size()==4,"Fourth Baby Mode clear unlocks and equips purple")
 var body=app.world.player.visual.get_child(0)
 suite.check(body.material_override==Art.retro_mat("frog_purple"),"Frog body uses the purple palette")
 suite.check(app.world.player.visual.get_node("HatSocket/BabyFrogHat").visible,"Purple skin retains the earned baby hat")
 app.save_profile()
 app.skin="green"
 app.load_profile()
 suite.check(app.skin=="purple","Purple selection survives profile reload")
 app.toggle_skin()
 suite.check(app.skin=="green" and body.material_override==body.get_meta("frog_base_material"),"Green selector restores original materials")
 app.load_profile()
 suite.check(app.skin=="green","Choosing green remains saved")
 while app.skin!="purple":app.toggle_skin()
 app.play_builtin(0,"baby")
 suite.check(app.world.player.visual.get_child(0).material_override==Art.retro_mat("frog_purple"),"Purple remains equipped when loading another map")
 var hashes={}
 var silhouettes={}
 for i in range(5):
  var tree=Art.scenery("tree","egypt",i)
  silhouettes[str([tree.get_child_count(),tree.get_child(0).position.y,tree.get_child(1).rotation.y])]=true
  tree.free()
  var texture=Pixels.get_texture("leaf@%d"%i)
  var data=texture.get_image().get_data()
  hashes[data.hex_encode().sha256_text()]=true
  suite.check(texture==Pixels.get_texture("leaf@%d"%i),"Tree foliage variant %d is fixed and cached"%i)
 suite.check(hashes.size()==5 and silhouettes.size()==5,"Five distinct fixed foliage textures and tree silhouettes exist")
 app.completed_stages=[0,1,2]
 app.skin="purple"
 app.save_profile()
 app.load_profile()
 suite.check(app.skin=="green","Incomplete progress cannot restore a locked purple skin")
 print("SKIN VARIANTS: %d checks, %d failures"%[suite.checks,suite.failures.size()])
 quit(0 if suite.failures.is_empty() else 1)
