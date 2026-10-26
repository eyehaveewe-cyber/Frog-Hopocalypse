extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 var app=load("res://main.tscn").instantiate();root.add_child(app);await process_frame
 app.set_process(false);app.exit_preview=false;app.rule_notices_enabled=false;app.set_sound_enabled(false);app.completed_human_stages=[0,1,2,3]
 for index in range(5):
  app.play_builtin(index,"sync");app.world.set_physics_process(false);app.overlay.hide();app.world.set_map_view(true)
  for i in range(3):await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://../docs/previews/move-redesign/stage-%d.png"%(index+1))
 quit()
