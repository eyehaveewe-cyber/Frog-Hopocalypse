extends SceneTree
const Data=preload("res://scripts/level_data.gd")
var app:Control
var checks:=0
var failures:Array=[]
func check(ok:bool,message:String)->void:
 checks+=1
 if not ok:failures.append(message);push_error(message)
func _initialize()->void:
 app=preload("res://main.tscn").instantiate();app.rule_notices_enabled=false
 root.add_child(app);call_deferred("run")
func fresh(style:String="smooth")->void:
 app.level=Data.blank("Hop feel","egypt",11,11);app.level.game_mode="tile";app.level.move_with_me=true;app.level.spawn=[5,8]
 app.enter_editor();app.playtest();app.world.set_physics_process(false);app.world.hop_pose_style=style
func run()->void:
 await process_frame
 app.set_process(false);app.exit_preview=false
 app.hop_audio.play_event("takeoff")
 check(app.hop_audio.history.is_empty(),"Effects require a gesture")
 app.hop_audio.unlocked=true;app.set_sound_enabled(true)
 fresh()
 var frog=app.world.player
 var rest:Array=[]
 for part in frog.hop_parts:rest.append(part.transform)
 frog.pose_tile_hop(.40,true)
 check(frog.hop_parts[2].position.z>1.0 and absf(frog.hop_parts[2].position.x)>.65,"Full flight extends rearward and spreads outward")
 check(frog.hop_parts[1].visible and frog.hop_parts[6].visible,"Connected shins appear during extension")
 check(is_equal_approx(frog.hop_parts[2].position.x,-frog.hop_parts[7].position.x),"Rear leg silhouette mirrors correctly")
 frog.pose_tile_hop(.94,true)
 check(frog.hop_parts[2].position.z<.52,"Legs tuck on approach before contact")
 frog.pose_tile_hop(1.0,true)
 check(range(10).all(func(i):return frog.hop_parts[i].transform.is_equal_approx(rest[i])) and not frog.hop_parts[1].visible,"Landing restores exact original rest transforms")
 frog.hop_pose_style="stepped";frog.pose_tile_hop(.30,true);var phase=frog.pose_phase
 frog.pose_tile_hop(.35,true)
 check(is_equal_approx(phase,frog.pose_phase),"Stepped poses hold while simulation phase advances")
 frog.hop_pose_style="smooth";frog.pose_tile_hop(.35,true)
 check(is_equal_approx(frog.pose_phase,.35),"Smooth poses consume the continuous simulation phase")
 for fps in [30,60,120]:
  for style in ["smooth","stepped"]:
   fresh(style)
   var start=app.world.player.position
   var count=app.hop_audio.history.size()
   check(app.world.tile_rules.request(Vector2i.UP,true),"Accepted hop at %d Hz, %s"%[fps,style])
   var frames=0
   while app.world.tile_rules.jumping:
    await physics_frame;app.world._physics_process(1.0/fps);frames+=1
   check(app.world.player.position.is_equal_approx(start+Vector3(0,0,-3.6)) and frames==ceili(.34*fps),"Same two-tile destination and .34-second hop at %d Hz, %s"%[fps,style])
   check(app.hop_audio.history.size()==count+2 and app.hop_audio.history[-1].contains("landing"),"One takeoff and one landing at %d Hz, %s"%[fps,style])
   for i in range(8):app.world._physics_process(1.0/fps)
   check(app.hop_audio.history.size()==count+2,"Idle never repeats landing")
 fresh();app.world.level.tiles[6][5]="water"
 var count=app.hop_audio.history.size()
 app.world.tile_rules.request(Vector2i.UP,true)
 for i in range(26):await physics_frame;app.world._physics_process(1.0/60)
 check(app.world.result=="SPLASHED!" and app.hop_audio.history.size()==count+1,"Water death has takeoff but no false dry landing")
 check(app.world.player.pose_phase==0 and not app.hop_audio.takeoff.playing,"Death interrupts pose and hop audio")
 fresh();count=app.hop_audio.history.size();app.world.level.tiles[7][5]="wall"
 check(not app.world.tile_rules.request(Vector2i.UP,false) and app.hop_audio.history.size()==count,"Blocked hop is silent")
 app.hop_audio.play_event("takeoff",false);var full:float=app.hop_audio.takeoff.volume_db
 app.hop_audio.play_event("takeoff",true)
 check(app.hop_audio.takeoff.volume_db<full-5,"Effects duck under recorded speech")
 app.hop_audio.set_gain(.25);var quiet:float=app.hop_audio.takeoff.volume_db
 app.hop_audio.set_gain(.75)
 check(app.hop_audio.takeoff.volume_db>quiet+9,"Volume gain changes actual playback level")
 app.hop_audio.set_gain(0);count=app.hop_audio.history.size();app.hop_audio.play_event("takeoff")
 check(not app.hop_audio.takeoff.playing and app.hop_audio.history.size()==count,"Zero volume stops and suppresses future effects")
 app.hop_audio.set_gain(.7);app.hop_audio.play_event("takeoff");app.set_sound_enabled(false)
 check(not app.hop_audio.takeoff.playing and not app.voice.enabled,"Existing Sound Off stops effects and voices together")
 app.set_sound_enabled(true)
 check(not app.hop_audio.takeoff.playing,"Unmute never replays stale effects")
 print("HOP FEEL: %d checks, %d failures"%[checks,failures.size()])
 app.hop_audio.clear();app.voice.clear()
 # Let the audio mixer release stopped sample playbacks before forced test exit.
 OS.delay_msec(250) # Audio mixer runs on wall time even with --fixed-fps acceleration.
 await process_frame
 app.queue_free()
 await process_frame
 OS.delay_msec(100)
 quit(0 if failures.is_empty() else 1)
