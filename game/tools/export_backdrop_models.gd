extends SceneTree
## Bake input exported from the actual course models; no image-generation service.
const Models=preload("res://scripts/landmark_models.gd")
func _initialize() -> void:
 var result: Dictionary={}
 for kind in Models.KINDS:
  var mesh:=Models.model(kind,false)
  var arrays:=mesh.surface_get_arrays(0)
  var vertices: Array=[]
  var colors: Array=[]
  var normals: Array=[]
  for v in arrays[Mesh.ARRAY_VERTEX]:vertices.append([v.x,v.y,v.z])
  for n in arrays[Mesh.ARRAY_NORMAL]:normals.append([n.x,n.y,n.z])
  for c in arrays[Mesh.ARRAY_COLOR]:colors.append([c.r,c.g,c.b])
  result[kind]={"vertices":vertices,"normals":normals,"colors":colors}
 var folder:=ProjectSettings.globalize_path("res://../art-source/backdrops").simplify_path()
 DirAccess.make_dir_recursive_absolute(folder)
 var file:=FileAccess.open(folder.path_join("models.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify(result))
 print("Exported five model bake sources.")
 quit()
