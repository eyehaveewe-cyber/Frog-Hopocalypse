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
 fresh("free");die()
 check(labels().contains("Long hop: ready"), "Free-hop retry remains clear")
 app.level.erase("game_mode")
 check(not app.retry_description().contains("Long hop"), "Classic Hopan does not receive tile-only resource copy")
 print("RECOVERY FEEDBACK: %d checks, %d failures" % [checks,failures.size()])
 quit(0 if failures.is_empty() else 1)
