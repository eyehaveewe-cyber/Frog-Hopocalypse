extends SceneTree
var errors:Array[String]=[]
var checks:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:errors.append(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var app=load("res://main.tscn").instantiate();root.add_child(app)
 await process_frame
 app.set_process(false);app.world.set_physics_process(false)
 for field in ["completed_stages","completed_human_stages","completed_bonus_stages","completed_tile_stages","completed_sync_stages"]:app.set(field,[])
 check(app.available_skins()==["green"],"New profile has green only")
 app.completed_stages=[0,1];check("orange" in app.available_skins() and "yellow" not in app.available_skins(),"Two distinct clears unlock orange")
 app.completed_stages=[0,1,2,3];app.completed_human_stages=[0,1]
 app.refresh_outfit_unlocks();check("morning" in app.unlocked_hats and "spotted" in app.available_skins(),"Six clears unlock suit and spots")
 app.completed_human_stages=[0,1,2,3];app.completed_tile_stages=[0,1]
 check("gummy" in app.available_skins() and "purple_white" in app.available_skins(),"Ten clears unlock requested colors")
 app.skin="gummy";app.hat="morning";app.save_profile();app.skin="green";app.hat="none";app.load_profile()
 check(app.skin=="gummy" and app.hat=="morning","New cosmetics survive profile restore")
 var actor=app.world.player;actor.set_hat("morning");var at=actor.position
 actor.idle_dance(3.35,true)
 check(actor.dance_active and actor.position==at,"Dance changes cosmetics only")
 check(actor.visual.get_node("HatSocket/MorningHat").position.y>0,"Idle includes hat tip")
 actor.idle_dance(.01,false)
 check(not actor.dance_active and actor.visual.rotation.z==0,"Movement cancels dance immediately")
 for i in range(actor.hop_parts.size()):check(actor.hop_parts[i].transform==actor.hop_rest[i],"Cancellation restores limb rest")
 var poses=[]
 for fps in [30,60,120]:
  actor.idle_dance(0,false)
  for i in range(int(3.35*fps)):actor.idle_dance(1.0/fps,true)
  poses.append(actor.visual.rotation.z)
 check(absf(poses[0]-poses[2])<.025,"Idle timing stable across 30/120 Hz")
 actor.idle_dance(3.35,true)
 app.world.halted=true;app.world._physics_process(.016)
 check(not actor.dance_active,"World pause cancels idle")
 app.world.halted=false;app.world.active=true;app.world.input_vector=Vector2.RIGHT
 actor.idle_dance(3.35,true);app.world._physics_process(.016)
 check(not actor.dance_active,"Actual world input interrupts idle before movement")
 app.world.input_vector=Vector2.ZERO
 actor.set_hat("hourglass")
 check(not actor.dance_active and not actor.visual.get_node("MorningSuit").visible,"Hat switch cleans up suit and motion")
 check(actor.visual.get_node("HatSocket/HourglassHat/StoneBlockShell").visible,"Pyramid has textured opaque shell")
 actor.set_skin("purple_white")
 check(actor.visual.get_child(1).material_override.albedo_color==Color.WHITE,"White belly is white")
 print(JSON.stringify({"checks":checks,"errors":errors}));quit(0 if errors.is_empty() else 1)
