extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 var scene:=Node3D.new();root.add_child(scene)
 var Actor=load("res://scripts/actor.gd")
 var kinds=["green","purple_white","orange","yellow","spotted","gummy"]
 for i in range(6):
  var frog=Actor.new();scene.add_child(frog);frog.setup(true,"egypt");frog.set_skin(kinds[i]);frog.set_hat("hourglass" if i==0 else "morning" if i==1 else "none");frog.position=Vector3((i%3)*1.6,0,(i/3)*1.8)
  if i==1:frog.idle_dance(3.35,true)
 var Art=load("res://scripts/art.gd")
 Art.box(scene,Vector3(7,.08,5),Vector3(1.6,-.04,.8),Color("506760"))
 var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-45,-25,0);sun.light_energy=1.4;scene.add_child(sun)
 var env:=WorldEnvironment.new();var e:=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("182630");e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color.WHITE;e.ambient_light_energy=.7;env.environment=e;scene.add_child(env)
 var cam:=Camera3D.new();scene.add_child(cam);cam.position=Vector3(5,4,-6);cam.look_at(Vector3(1.5,.5,.8));cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=6.6
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://../docs/previews/frog-outfits/lineup.png")
 cam.position=Vector3(1.9,1.8,-2.8);cam.look_at(Vector3(.7,.65,0));cam.size=2.8
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://../docs/previews/frog-outfits/hats-close.png")
 cam.position=Vector3(3.2,1.5,-2.8);cam.look_at(Vector3(1.6,.6,0));cam.size=1.9
 var dancer=scene.get_child(1)
 dancer.idle_dance(0,false);dancer.idle_dance(2.5,true)
 DirAccess.make_dir_recursive_absolute("/tmp/frog-dance")
 for frame in range(40):
  dancer.idle_dance(.1,true)
  await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/frog-dance/%03d.png"%frame)
 cam.position=Vector3(3.2,1.4,2.3);cam.look_at(Vector3(1.6,.5,0));cam.size=1.8
 dancer.idle_dance(0,false)
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://../docs/previews/frog-outfits/suit-back.png")
 quit()
