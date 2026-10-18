extends SceneTree
const Suite = preload("res://tests/integration.gd")
var suite = Suite.new()
var app: Control
func _initialize() -> void:
 app=preload("res://main.tscn").instantiate()
 root.add_child(app)
 call_deferred("run")
func node(name: String) -> Node:
 return app.overlay_box.find_child(name,true,false)
func run() -> void:
 await process_frame
 app.set_process(false)
 app.world.set_physics_process(false)
 app.completed_stages=[]
 app.completed_human_stages=[]
 app.completed_bonus_stages=[]
 app.show_menu()
 suite.check(node("Set_baby")!=null and node("Set_human")==null and not node("Stages_baby").visible,"Fresh menu has a compact Baby Mode button and hides the locked set")
 node("Set_baby").pressed.emit()
 suite.check(app.mode=="play" and app.builtin_index==0,"Fresh set button starts stage one")
 app.completed_stages=[0,2]
 app.show_menu()
 node("Set_baby").pressed.emit()
 suite.check(app.builtin_index==2,"Main set button replays the most recently completed stage")
 app.play_builtin(0,"baby")
 app.world.finish("LEVEL COMPLETE!")
 suite.check(app.set_start_index("baby")==0 and app.completed_stages==[0,2],"Replaying a previously cleared stage updates the most recent clear")
 app.save_profile()
 app.last_cleared_stages={}
 app.load_profile()
 suite.check(app.set_start_index("baby")==0,"Most recent replay survives profile reload")
 app.completed_stages=[0,1,2,3]
 app.show_menu()
 node("Set_baby").pressed.emit()
 suite.check(app.builtin_index==0,"Fully completed set restarts from stage one")
 app.show_menu()
 node("Expand_baby").pressed.emit()
 var stages:Node=node("Stages_baby")
 suite.check(stages.visible and stages.get_child_count()==4,"Expand exposes all four available Baby Mode stage choices")
 node("Expand_baby").pressed.emit()
 suite.check(not stages.visible and node("Expand_baby").text=="+","Collapse restores the compact set row")
 suite.check(node("Set_human")!=null and not node("Stages_human").visible,"Unlocked human-made set has its own compact selector")
 app.completed_human_stages=[0,2]
 node("Set_human").pressed.emit()
 suite.check(app.campaign_set=="human" and app.builtin_index==2,"Human-made button resumes its own most recent clear")
 app.completed_human_stages=[0,1,2,3]
 app.show_menu()
 node("Set_human").pressed.emit()
 suite.check(app.builtin_index==0,"Completed human-made set also restarts from stage one")
 suite.check(app.paths_for_set("bonus")==app.BONUS_LEVELS and app.progress_for_set("bonus").is_empty(),"Bonus routing and progress remain separate from existing campaigns")
 app.save_profile()
 app.completed_stages=[]
 app.completed_human_stages=[]
 app.load_profile()
 suite.check(app.completed_stages.size()==4 and app.completed_human_stages.size()==4,"Existing campaign progress survives profile save/reload")
 app.completed_stages=[]
 app.completed_human_stages=[]
 app.completed_bonus_stages=[]
 app.unlocked_hats=["none","pharaoh"]
 app.hat="pharaoh"
 app.show_menu()
 suite.check(node("Set_bonus")!=null and not node("Stages_bonus").visible,"Bonus set is present immediately and starts collapsed")
 node("Expand_bonus").pressed.emit()
 suite.check(node("Stages_bonus").get_child_count()==1,"Bonus expands to exactly the authored Shelby stage")
 suite.check(FileAccess.get_sha256(app.BONUS_LEVELS[0])=="3341a1fcd91c81f89d2bb0abdfbc787e54d338f2aa2e1c0a7f01c39bcdc03aa8","Shelby's exact original attachment bytes are bundled")
 node("Set_bonus").pressed.emit()
 suite.check(app.mode=="play" and app.campaign_set=="bonus" and app.level.name=="Shelby" and app.world.active,"Original pre-cheese-wall Shelby launches from a fresh profile")
 app.world.finish("LEVEL COMPLETE!")
 suite.check(app.completed_bonus_stages==[0] and app.completed_stages.is_empty() and not app.human_set_unlocked() and "baby" not in app.unlocked_hats,"Bonus completion does not grant campaign progress or hat unlocks")
 app.save_profile()
 app.completed_bonus_stages=[]
 app.load_profile()
 suite.check(app.completed_bonus_stages==[0],"Bonus completion survives reload")
 print("SET MENU: %d checks, %d failures"%[suite.checks,suite.failures.size()])
 quit(0 if suite.failures.is_empty() else 1)
