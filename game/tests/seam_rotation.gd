extends SceneTree
const Data = preload("res://scripts/level_data.gd")
const Suite = preload("res://tests/integration.gd")
var suite = Suite.new()
var app: Control
func _initialize() -> void:
 app = preload("res://main.tscn").instantiate()
 root.add_child(app)
 call_deferred("run")
func run() -> void:
 await process_frame
 app.set_process(false)
 app.world.set_physics_process(false)
 app.level = Data.blank("Rotating seams", "egypt", 11, 11)
 app.enter_editor()
 app.set_tool("seam_worm")
 app.stroke_changed = false
 app.edit_cell(Vector2i(5,5))
 var id: String = app.selection
 var loop: CheckBox = app.inspector.find_child("PatrolLoop", true, false)
 suite.check(loop != null and loop.text == "Loop" and loop.get_parent() is HBoxContainer and loop.get_parent().get_child(0).text == "Draw route", "Compact Loop checkbox shares the Draw route row")
 loop.button_pressed = false
 suite.check(not app.selected_object().patrol_loop, "Compact Loop checkbox edits the saved patrol flag")
 app.change_property("patrol_loop", true)
 for pair in [[90,[5.5,4.5]],[180,[4.5,4.5]],[270,[4.5,5.5]],[0,[5.5,5.5]]]:
  app.change_property("rotation", pair[0])
  suite.check(app.selected_object().pos == pair[1] and app.selected_object().seam_anchor == [5,5], "Rotation %d changes seam around the same placement tile" % pair[0])
 app.change_property("rotation", 180)
 suite.check(app.object_at(Vector2i(5,5)) == 0, "Rotated worm stays selectable from its original tile")
 app.undo()
 app.selection = id
 suite.check(app.selected_object().pos == [5.5,5.5] and app.selected_object().rotation == 0, "Undo restores seam position and rotation together")
 app.redo()
 app.selection = id
 suite.check(app.selected_object().pos == [4.5,4.5] and app.selected_object().rotation == 180, "Redo reapplies the seam move")
 app.change_property("rotation", 0)
 app.change_property("waypoints", [[7.5,5.5],[7.5,7.5],[5.5,7.5],[5.5,5.5]])
 app.change_property("rotation", 180)
 suite.check(app.selected_object().waypoints == [[2.5,4.5],[2.5,2.5],[4.5,2.5],[4.5,4.5]] and Data.validate(app.level).is_empty(), "Drawn patrol pivots with the worm and keeps valid square turns")
 var round_trip: Dictionary = Data.normalize(JSON.parse_string(JSON.stringify(app.level)))
 app.level = round_trip
 app.rebuild()
 app.change_property("rotation", 0)
 suite.check(app.selected_object().pos == [5.5,5.5] and app.selected_object().waypoints[0] == [7.5,5.5], "Anchor and reversible patrol rotation survive JSON reload")
 app.change_property("waypoints", [])
 app.level.objects.append({"id":"tree","type":"tree","pos":[4,4],"solid":true})
 var before: Dictionary = app.selected_object().duplicate(true)
 app.change_property("rotation", 180)
 suite.check(app.selected_object() == before, "Rotation beside a solid tree is rejected without changing the worm")
 app.level.objects.pop_back()
 app.level.tiles[4][4] = "water"
 app.change_property("rotation", 180)
 suite.check(app.selected_object() == before, "Rotation into water is rejected")
 app.level.tiles[4][4] = "floor"
 app.selected_object().erase("seam_anchor")
 app.change_property("rotation", 180)
 suite.check(app.selected_object().pos == [4.5,4.5] and Data.validate(app.level).is_empty(), "Legacy worms without an anchor rotate from their existing placement tile")
 var bad: Dictionary = app.level.duplicate(true)
 bad.objects[0].seam_anchor = ["bad",5]
 suite.check(not Data.validate(bad).is_empty(), "Malformed placement anchors fail JSON validation")
 app.selected_object().behavior = "patrol"
 var unchanged: Array = app.selected_object().pos.duplicate()
 app.change_property("rotation", 90)
 suite.check(app.selected_object().pos == unchanged, "Ordinary critter rotation does not move its tile position")
 app.level = Data.blank("Boundary", "egypt", 7,7)
 app.enter_editor()
 app.set_tool("seam_worm")
 app.stroke_changed = false
 app.edit_cell(Vector2i(1,3))
 before = app.selected_object().duplicate(true)
 app.change_property("rotation", 180)
 suite.check(app.selected_object() == before, "Boundary wall prevents rotating onto an obstructed outer seam")
 print("SEAM ROTATION: %d checks, %d failures" % [suite.checks,suite.failures.size()])
 quit(0 if suite.failures.is_empty() else 1)
