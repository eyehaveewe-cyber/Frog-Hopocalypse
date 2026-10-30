extends SceneTree
const Data = preload("res://scripts/level_data.gd")
var failed := 0
func check(value: bool, label: String) -> void:
 if value: print("PASS: " + label)
 else: failed += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var app = load("res://main.tscn").instantiate()
 root.add_child(app)
 await process_frame
 app.enter_editor()
 var level: Dictionary = app.level.duplicate(true)
 var old: String = Data.validate(level, true)
 check(old.is_empty(), "Old level without tile colors is valid")
 level.tile_colors = {"1,1":"#d83722", "2,1":"#2ca9da", "3,1":"#ba21e0", "4,1":"#f0d221"}
 level.tiles[1][1] = "wall"
 level.tiles[1][2] = "floor"
 level.tiles[1][3] = "path"
 level.tiles[1][4] = "cheese_wall"
 check(Data.validate(level, true).is_empty(), "Painted level passes validation")
 var normalized: Dictionary = Data.normalize(JSON.parse_string(JSON.stringify(level)))
 check(normalized.tile_colors == level.tile_colors, "Colors survive JSON round trip")
 level.tile_colors["999,0"] = "#ffffff"
 check(not Data.validate(level, true).is_empty(), "Out-of-bounds color is rejected")
 level.tile_colors.erase("999,0")
 app.level = level
 app.rebuild()
 var shaders: Array = preload("res://scripts/art.gd").retro_materials.values()
 var found: Dictionary = {}
 for material in shaders:
  var col: Color = material.get_shader_parameter("albedo_color")
  for wanted in ["d83722", "2ca9da", "ba21e0", "f0d221"]:
   if col.is_equal_approx(Color(wanted)): found[wanted] = true
 check(found.size() == 4, "Wall, floor, path and cheese wall colors reach rendered materials")
 var art = preload("res://scripts/art.gd")
 art.compatibility_mode = true
 app.rebuild()
 var safe_found: Dictionary = {}
 for material in art.materials.values():
  if material is StandardMaterial3D:
   for wanted in ["d83722", "2ca9da", "ba21e0", "f0d221"]:
    if material.albedo_color.is_equal_approx(Color(wanted)): safe_found[wanted] = true
 check(safe_found.size() == 4, "Paint also reaches compatibility rendering materials")
 print("TILE COLOR DATA: %d failures" % failed)
 quit(1 if failed else 0)
