extends SceneTree
const Data = preload("res://scripts/level_data.gd")
var app: Control
var checks := 0
var failures: Array = []
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures.append(message);push_error(message)
func _initialize() -> void:
 app = preload("res://main.tscn").instantiate()
 app.rule_notices_enabled = false
 root.add_child(app)
 call_deferred("run")
func ticks() -> void:
 for i in range(26):
  await physics_frame
  app.world._physics_process(1.0/60)
func labels() -> String:
 return "\n".join(app.overlay_box.find_children("*", "Label", true, false).map(func(n):return n.text))
func action(text: String) -> Button:
 for b in app.overlay_box.find_children("*", "Button", true, false):
  if b.text == text: return b
 return null
func fresh(rule: String = "fragments") -> void:
 app.level = Data.blank("Recovery fixture", "egypt", 9, 9)
 app.level.game_mode = "tile"
 app.level.rules = {"long_hop":rule,"charge_hops":25}
 app.level.checkpoints = [[1,6]]
 app.level.objects = [{"id":"a","type":"hop_fragment" if rule=="fragments" else "hop_seed","pos":[1,6],"solid":false}]
 app.enter_editor();app.playtest();app.world.set_physics_process(false)
func die() -> void:
 app.world.finish("HIT!")
 app.world.result_time = 2.0
 app.update_result_presentation()
func run() -> void:
 await process_frame
 app.set_process(false);app.exit_preview=false;app.set_sound_enabled(false)
 fresh()
 die()
 check(labels().contains("level start") and labels().contains("0 / 3 fragments"), "Unclaimed flag describes the start and empty fragments")
 check(action("Retry from start · R") != null, "Death offers an explicit start retry")
 action("Retry from start · R").pressed.emit();app.world.set_physics_process(false)
 check(app.world.position_cell(app.world.player.position)==Vector2i(1,7) and app.world.result.is_empty(), "Start retry button really starts a new attempt")
 check(app.world.tile_rules.request(Vector2i.UP,false), "Fixture accepts normal hop to checkpoint")
 await ticks()
 check(app.checkpoint_spawn==[1,6] and app.checkpoint_hop_state.fragments==1, "Normal landing saves checkpoint fragment")
 app.world.tile_rules.fragments=2 # Later inventory must not leak into the saved preview.
 die()
 check(labels().contains("1 / 3 fragments") and labels().contains("Hazards restart"), "Death reports saved inventory and hazard reset, not current inventory")
 check(action("Retry checkpoint · R") != null, "Checkpoint retry has a distinct action label")
 action("Retry checkpoint · R").pressed.emit();app.world.set_physics_process(false)
 check(app.world.position_cell(app.world.player.position)==Vector2i(1,6) and app.world.tile_rules.fragments==1, "Checkpoint button restores the actual saved state")
 check(app.status_label.text.begins_with("Checkpoint restored"), "Retry confirms checkpoint restoration")
 fresh("powerup")
 check(app.world.tile_rules.request(Vector2i.UP,false), "Seed fixture accepts normal checkpoint hop")
 await ticks();die()
 check(labels().contains("saved reserve restored"), "Seed checkpoint advertises the saved hop")
 action("Retry checkpoint · R").pressed.emit();app.world.set_physics_process(false)
 check(app.world.tile_rules.reserve, "Advertised seed reserve is actually restored")
 fresh("charged")
 check(app.world.tile_rules.request(Vector2i.UP,false), "Charged fixture accepts checkpoint hop")
 await ticks();app.world.tile_rules.charge_remaining=17;die()
 check(labels().contains("Long hop: ready"), "Charged retry advertises refill, not current cooldown")
 action("Retry checkpoint · R").pressed.emit();app.world.set_physics_process(false)
 check(app.world.tile_rules.long_hop_ready(), "Charged retry really refills")
 fresh()
 check(app.world.tile_rules.request(Vector2i.UP,false), "Pause fixture accepts checkpoint hop")
 await ticks()
 app.joystick.show()
 app.toggle_pause()
 check(not app.joystick.visible, "Pause hides the touch joystick so it cannot cover recovery text")
 check(app.paused and app.world.halted and action("Retry checkpoint · R")!=null, "Pause offers the same checkpoint recovery while hazards are halted")
 check(labels().contains("1 / 3 fragments"), "Pause summary reads the saved resource")
 check(action("Restart level…")!=null, "Saved checkpoint exposes a separate full restart")
 action("Restart level…").pressed.emit()
 check(app.restart_confirmation_open and app.paused and app.world.halted, "Full restart asks before discarding the active checkpoint")
 var event:=InputEventKey.new();event.pressed=true;event.keycode=KEY_R
 app._input(event)
 check(app.restart_confirmation_open and app.checkpoint_spawn==[1,6], "R cannot bypass the restart decision")
 event.keycode=KEY_ESCAPE;app._input(event)
 check(not app.restart_confirmation_open and app.paused and action("Resume")!=null, "Escape returns to Pause without resuming hazards")
 action("Restart level…").pressed.emit()
 action("Keep checkpoint").pressed.emit()
 check(app.checkpoint_spawn==[1,6] and app.world.tile_rules.fragments==1, "Cancel preserves checkpoint and pickups")
 action("Retry checkpoint · R").pressed.emit();app.world.set_physics_process(false)
 check(not app.paused and app.pause_button.text=="Pause" and not app.overlay.visible, "Pause retry resets the header label and closes Pause")
 app.toggle_pause();action("Restart level…").pressed.emit()
 app.completed_tile_stages=[0,1]
 action("Restart from beginning").pressed.emit();app.world.set_physics_process(false)
 check(app.checkpoint_spawn.is_empty() and app.checkpoint_history.is_empty() and app.checkpoint_hop_state.is_empty(), "Confirmed full restart clears the active checkpoint snapshot")
 check(app.world.position_cell(app.world.player.position)==Vector2i(1,7) and app.world.tile_rules.fragments==0 and app.world.hop_pickups[0].node.visible, "Confirmed restart resets position and collected pickups")
 check(app.completed_tile_stages==[0,1] and app.mode=="test", "Full restart preserves campaign progress and playtest context")
 check(not app.restart_confirmation_open and not app.paused and not app.overlay.visible, "Confirmed restart clears confirmation and paused state")
 app.toggle_pause()
 check(action("Retry from start · R")!=null and action("Restart level…")==null, "Before a flag, Pause avoids duplicate restart actions")
 app.toggle_pause()
 app.mode="play";app.campaign_level=true;app.campaign_set="tile";app.builtin_index=2
 check(app.world.tile_rules.request(Vector2i.UP,false), "Campaign restart fixture reaches a checkpoint")
 await ticks();app.toggle_pause();action("Restart level…").pressed.emit();action("Restart from beginning").pressed.emit();app.world.set_physics_process(false)
 check(app.mode=="play" and app.campaign_level and app.campaign_set=="tile" and app.builtin_index==2, "Campaign full restart retains set and stage identity")
 fresh("free");die()
 check(labels().contains("Long hop: ready"), "Free-hop retry remains clear")
 app.level.erase("game_mode")
 check(not app.retry_description().contains("Long hop"), "Classic Hopan does not receive tile-only resource copy")
 print("RECOVERY FEEDBACK: %d checks, %d failures" % [checks,failures.size()])
 quit(0 if failures.is_empty() else 1)
