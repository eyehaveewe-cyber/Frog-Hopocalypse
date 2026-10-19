extends Node3D
## Two cached mesh LODs, one opaque draw per visible landmark; no actor physics.
const Models = preload("res://scripts/landmark_models.gd")
const Art = preload("res://scripts/art.gd")
const MARGIN = 16
const MAX_COUNT = 32
static var materials: Dictionary = {}
var world: Node3D
var entries: Array = []
var clock = 0.0

static func material(coarse: bool) -> StandardMaterial3D:
 var key := str(coarse) + str(Art.compatibility_mode)
 if materials.has(key): return materials[key]
 var mat := StandardMaterial3D.new()
 mat.vertex_color_use_as_albedo = true
 mat.roughness = 1.0
 mat.metallic_specular = 0
 mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if coarse or Art.compatibility_mode else BaseMaterial3D.SHADING_MODE_PER_VERTEX
 if not coarse:
  # Broad 4x4 patches in a tiny texture, enlarged across each model face.
  # No screen blur, alpha layers, animated noise or normal maps.
  var image := Image.create(16,16,false,Image.FORMAT_RGB8)
  for y in range(16):
   for x in range(16):
    var value := 0.78 + float(posmod((x/4)*7+(y/4)*11,5))*0.045
    image.set_pixel(x,y,Color(value,value,value))
  mat.albedo_texture = ImageTexture.create_from_image(image)
  mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
 materials[key] = mat
 return mat

func setup(level: Dictionary, owner_world: Node3D) -> void:
 world = owner_world
 for obj in level.objects:
  if obj.type != "landmark": continue
  var body := Node3D.new()
  body.name = str(obj.id)
  body.position = world.cell_position(obj.pos)
  body.rotation.y = deg_to_rad(float(obj.get("rotation",0)))
  body.scale = Vector3.ONE * float(obj.get("landmark_scale",1))
  add_child(body)
  var renderers: Array = []
  for far in [false,true]:
   var mesh := MeshInstance3D.new()
   mesh.mesh = Models.model(obj.get("landmark_kind","sphinx"),far)
   mesh.material_override = material(far)
   mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
   body.add_child(mesh)
   renderers.append(mesh)
  entries.append({"body":body,"near":renderers[0],"far":renderers[1],"state":"", "kind":obj.get("landmark_kind","sphinx")})
  if world.editing:
   # Tall art projects away from its ground cell in the overhead editor.
   # This fixed-size, editor-only pin shows the actual selectable anchor.
   var pin := MeshInstance3D.new()
   var disc := CylinderMesh.new()
   disc.top_radius = 0.3
   disc.bottom_radius = 0.3
   disc.height = 0.035
   disc.radial_segments = 8
   disc.rings = 1
   pin.mesh = disc
   if not materials.has("editor_pin"):
    var ink := StandardMaterial3D.new()
    ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    ink.albedo_color = Color("f5ce70")
    ink.no_depth_test = true
    ink.render_priority = 2
    materials.editor_pin = ink
   pin.material_override = materials.editor_pin
   pin.position = body.position + Vector3(0,0.05,0)
   pin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
   add_child(pin)
 update_lod()

func _process(delta: float) -> void:
 clock += delta
 if clock >= 0.15:
  clock = 0
  update_lod()

func update_lod() -> void:
 if not is_instance_valid(world) or not is_instance_valid(world.camera): return
 var limit: float = float(world.level.get("draw_distance",18)) * world.CELL
 var close: float = limit * 0.56
 var full: bool = world.editing or world.map_view
 for entry in entries:
  # A shared ground anchor drives both meshes, so changes are complementary.
  # Hysteresis prevents flicker while pacing around a threshold.
  var offset: Vector3 = world.camera.global_position-entry.body.global_position
  var distance := Vector2(offset.x,offset.z).length()
  var state: String = entry.state
  if full:
   state = "far"
  elif state == "hidden" and distance > limit-1.2:
   state = "hidden"
  elif distance > limit+1.2:
   state = "hidden"
  elif state == "near" and distance < close+1.2:
   state = "near"
  elif distance < close-1.2:
   state = "near"
  else:
   state = "far"
  entry.state = state
  entry.near.visible = state == "near"
  entry.far.visible = state == "far"

func stats() -> Dictionary:
 var result := {"near":0,"far":0,"hidden":0,"visible_triangles":0,"visible_draws":0}
 for entry in entries:
  result[entry.state] += 1
  if entry.state != "hidden":
   var mesh: Mesh = entry.near.mesh if entry.state == "near" else entry.far.mesh
   result.visible_triangles += mesh.surface_get_array_len(0)/3
   result.visible_draws += 1
 return result
