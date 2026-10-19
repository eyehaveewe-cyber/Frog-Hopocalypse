extends RefCounted
## Original editable low-poly model kit. One shared-material surface per LOD.
const KINDS = ["sphinx", "osiris", "pyramid", "moss_tree", "heron"]
const TITLES = ["Sphinx", "Osiris statue", "Pyramid", "Giant moss tree", "Giant heron"]
static var cache: Dictionary = {}
var vertices := PackedVector3Array()
var normals := PackedVector3Array()
var colors := PackedColorArray()
var uvs := PackedVector2Array()
var baked_shading = false

static func model(kind: String, coarse: bool) -> ArrayMesh:
 var key := kind + (":far" if coarse else ":near")
 if cache.has(key): return cache[key]
 var builder := new()
 builder.baked_shading = coarse
 builder.draw(kind, coarse)
 var arrays: Array = []
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX] = builder.vertices
 arrays[Mesh.ARRAY_NORMAL] = builder.normals
 arrays[Mesh.ARRAY_COLOR] = builder.colors
 arrays[Mesh.ARRAY_TEX_UV] = builder.uvs
 var mesh := ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
 mesh.resource_name = key
 cache[key] = mesh
 return mesh

func primitive(mesh: Mesh, position: Vector3, color: Color, basis: Basis = Basis.IDENTITY) -> void:
 var data := mesh.surface_get_arrays(0)
 var points: PackedVector3Array = data[Mesh.ARRAY_VERTEX]
 var ns: PackedVector3Array = data[Mesh.ARRAY_NORMAL]
 var tex: PackedVector2Array = data[Mesh.ARRAY_TEX_UV]
 var indices: PackedInt32Array = data[Mesh.ARRAY_INDEX]
 for i in range(indices.size() if not indices.is_empty() else points.size()):
  var at: int = indices[i] if not indices.is_empty() else i
  vertices.append(basis * points[at] + position)
  normals.append((basis.inverse().transposed() * ns[at]).normalized())
  colors.append(shade(color, (basis.inverse().transposed() * ns[at]).normalized()))
  uvs.append(tex[at] if not tex.is_empty() else Vector2.ZERO)

func box(size: Vector3, at: Vector3, color: Color, rotation: float = 0) -> void:
 var mesh := BoxMesh.new()
 mesh.size = size
 primitive(mesh, at, color, Basis(Vector3.FORWARD, rotation))

func tube(radius: float, top: float, height: float, at: Vector3, color: Color, sides: int = 6) -> void:
 var mesh := CylinderMesh.new()
 mesh.bottom_radius = radius
 mesh.top_radius = top
 mesh.height = height
 mesh.radial_segments = sides
 mesh.rings = 1
 primitive(mesh, at, color)

func link(a: Vector3, b: Vector3, radius: float, color: Color, sides: int = 5) -> void:
 var mesh := CylinderMesh.new()
 mesh.bottom_radius = radius
 mesh.top_radius = radius * 0.65
 mesh.height = a.distance_to(b)
 mesh.radial_segments = sides
 mesh.rings = 1
 var up := (b-a).normalized()
 var axis := up.cross(Vector3.RIGHT if absf(up.x)<0.8 else Vector3.FORWARD).normalized()
 primitive(mesh, (a+b)*0.5, color, Basis(axis, up, axis.cross(up)).orthonormalized())

func triangle(a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
 var normal := (b-a).cross(c-a).normalized()
 # Godot's front faces use clockwise winding; keep outward lighting normals.
 vertices.append_array(PackedVector3Array([a,c,b]))
 normals.append_array(PackedVector3Array([normal,normal,normal]))
 var painted := shade(color, normal)
 colors.append_array(PackedColorArray([painted,painted,painted]))
 uvs.append_array(PackedVector2Array([Vector2(0,1),Vector2(0.5,0),Vector2(1,1)]))

func peak(width: float, height: float, depth: float, at: Vector3, color: Color) -> void:
 var corners := [Vector3(-width/2,0,-depth/2),Vector3(width/2,0,-depth/2),Vector3(width/2,0,depth/2),Vector3(-width/2,0,depth/2)]
 for i in range(4):
  triangle(corners[i]+at, Vector3(0,height,0)+at, corners[(i+1)%4]+at, color.lightened(0.04*i))
 triangle(corners[0]+at,corners[1]+at,corners[2]+at,color)
 triangle(corners[0]+at,corners[2]+at,corners[3]+at,color)

func lump(size: Vector3, at: Vector3, color: Color) -> void:
 var ring := [Vector3(-1,0,0),Vector3(0,0,-1),Vector3(1,0,0),Vector3(0,0,1)]
 for i in range(4):
  triangle(ring[i]*size+at,Vector3(0,1,0)*size+at,ring[(i+1)%4]*size+at,color.lightened(i*0.035))
  triangle(ring[(i+1)%4]*size+at,Vector3(0,-1,0)*size+at,ring[i]*size+at,color.darkened(0.08))

func draw(kind: String, far: bool) -> void:
 var sand := Color("bb9d69")
 var gold := Color("d9bb70")
 var bronze := Color("608578")
 var bark := Color("655b47")
 var moss := Color("667e54")
 match kind:
  "pyramid":
   peak(8.4,7.7,8.4,Vector3.ZERO,sand)
   if not far:
    box(Vector3(9,0.35,9),Vector3(0,0.17,0),sand.darkened(0.15))
    for side in [-1,1]:
     for i in range(6):
      box(Vector3(1.35,0.42,0.36),Vector3(-3.4+i*1.36,0.6,side*3.9),sand.lightened(0.035*(i%3)))
    for i in range(4):
     box(Vector3(1.6,0.2,0.6),Vector3(0,0.25+i*0.2,-4.5+i*0.5),sand)
    box(Vector3(0.9,1.1,0.15),Vector3(0,0.9,-3.6),Color("4e554e"))
  "sphinx":
   box(Vector3(3.8,0.38,5.8),Vector3(0,0.19,0),sand.darkened(0.12))
   box(Vector3(2.4,1.4,3.4),Vector3(0,1.05,0.6),sand)
   for side in [-1,1]:
    box(Vector3(0.8,0.6,2.0),Vector3(side*1.0,0.65,-1.7),sand.lightened(0.12))
   box(Vector3(1.25,1.5,1.0),Vector3(0,2.9,-1.2),sand.lightened(0.1))
   box(Vector3(2.0,0.42,1.3),Vector3(0,3.68,-1.0),gold)
   if far:
    for side in [-1,1]:
     box(Vector3(0.36,1.3,1.0),Vector3(side*0.78,2.9,-1.0),gold.darkened(0.1))
    box(Vector3(0.8,0.10,0.05),Vector3(0,3.14,-1.73),sand.darkened(0.5))
   if not far:
    for side in [-1,1]:
     lump(Vector3(0.6,0.7,1),Vector3(side*1.0,1.2,1.4),sand)
     box(Vector3(0.42,1.4,1.1),Vector3(side*0.82,2.9,-1.0),gold.darkened(0.08))
     for i in range(3):
      box(Vector3(0.43,0.10,0.04),Vector3(side*0.82,2.4+i*0.34,-1.57),Color("657e7a"))
     box(Vector3(0.24,0.09,0.05),Vector3(side*0.31,3.14,-1.73),Color("615b47"))
     for toe in range(3):
      box(Vector3(0.04,0.06,0.45),Vector3(side*1.0+(toe-1)*0.19,0.96,-2.3),sand.darkened(0.2))
    box(Vector3(0.22,0.4,0.28),Vector3(0,2.94,-1.78),sand)
    box(Vector3(0.28,0.5,0.28),Vector3(0,2.26,-1.6),sand.darkened(0.12))
    link(Vector3(1.1,0.7,2),Vector3(1.65,0.7,1.2),0.18,sand)
  "osiris":
   box(Vector3(2.9,0.7,2.5),Vector3(0,0.35,0),sand.darkened(0.18))
   tube(0.85,0.66,3.5,Vector3(0,2.45,0),bronze,4 if far else 8)
   box(Vector3(1.7,1.0,0.85),Vector3(0,4.0,0),bronze)
   box(Vector3(0.85,1.2,0.85),Vector3(0,5.05,-0.08),bronze.lightened(0.14))
   tube(0.47,0.15,1.8,Vector3(0,6.5,0),gold,4 if far else 6)
   if not far:
    for side in [-1,1]:
     lump(Vector3(0.25,0.9,0.12),Vector3(side*0.65,6.4,0),gold.lightened(0.15))
     link(Vector3(side*0.8,4.25,-0.05),Vector3(-side*0.3,3.75,-0.66),0.18,bronze.lightened(0.2))
     box(Vector3(0.18,0.07,0.05),Vector3(side*0.22,5.22,-0.53),Color("303e3c"))
    tube(0.19,0.14,0.75,Vector3(0,4.42,-0.55),gold,4)
    box(Vector3(0.16,0.32,0.16),Vector3(0,5.0,-0.61),bronze)
    link(Vector3(-0.3,3.8,-0.7),Vector3(-0.5,5,-0.8),0.055,gold)
    link(Vector3(-0.5,5,-0.8),Vector3(-0.78,5.1,-0.8),0.055,gold)
    link(Vector3(-0.78,5.1,-0.8),Vector3(-0.85,4.8,-0.8),0.055,gold)
    link(Vector3(0.3,3.8,-0.7),Vector3(0.6,4.8,-0.8),0.055,gold)
    for i in range(3):
     link(Vector3(0.6,4.8,-0.8),Vector3(0.8+i*0.13,4.25,-0.8),0.035,gold)
     box(Vector3(1.2-i*0.07,0.08,1.05),Vector3(0,1.3+i*0.7,0),bronze.darkened(0.12))
  "moss_tree":
   tube(0.85,0.40,6.5,Vector3(0,3.25,0),bark,4 if far else 7)
   lump(Vector3(4.2,1.9,3.5),Vector3(0,7.0,0),moss)
   if not far:
    for i in range(5):
     var angle := i*TAU/5
     var tip := Vector3(cos(angle)*2.9,6.0+float(i%2),sin(angle)*2.6)
     link(Vector3(0,3.6+i*0.35,0),tip,0.30,bark)
     lump(Vector3(1.9,1.3,1.7),tip+Vector3.UP,moss.lightened(0.035*(i%3)))
     link(Vector3(0,0.35,0),Vector3(cos(angle)*1.8,0.05,sin(angle)*1.8),0.32,bark)
     for j in range(2):
      peak(0.22,1.0+j*0.55,0.22,tip+Vector3(j*0.2,-1.6,0),moss.darkened(0.15))
  "heron":
   var feather := Color("a9bec4")
   for side in [-1,1]:
    link(Vector3(side*0.4,0,0.5),Vector3(side*0.37,3.0,0.1),0.09,Color("9b9e73"),4)
   lump(Vector3(1.05,1.2,1.7),Vector3(0,3.8,0.5),feather)
   link(Vector3(0,4.25,-0.7),Vector3(0,5.4,-0.1),0.23,feather,4 if far else 6)
   link(Vector3(0,5.4,-0.1),Vector3(0,6.5,-0.9),0.2,feather,4 if far else 6)
   lump(Vector3(0.38,0.38,0.65),Vector3(0,6.6,-1.05),feather.lightened(0.14))
   beak(Vector3(0,6.57,-1.5),gold)
   if not far:
    for side in [-1,1]:
     lump(Vector3(0.35,0.9,1.45),Vector3(side*0.75,3.65,0.7),Color("657e94"))
     box(Vector3(0.06,0.12,0.18),Vector3(side*0.34,6.7,-1.25),Color("263c4a"))
     for toe in range(3):
      link(Vector3(side*0.4,0.05,0.5),Vector3(side*0.4+(toe-1)*0.25,0.04,-0.15),0.04,Color("a3a17b"),4)
    link(Vector3(0,6.7,-0.55),Vector3(0,6.35,0.55),0.06,Color("3d536a"),4)

func beak(at: Vector3, color: Color) -> void:
 var a := at+Vector3(-0.18,0.14,0)
 var b := at+Vector3(0.18,0.14,0)
 var c := at+Vector3(0,-0.16,0)
 var tip := at+Vector3(0,0,-1.6)
 triangle(a,b,tip,color)
 triangle(b,c,tip,color.darkened(0.15))
 triangle(c,a,tip,color.lightened(0.1))
 triangle(a,c,b,color)

func shade(color: Color, normal: Vector3) -> Color:
 if not baked_shading: return color
 var intensity := 0.68 + maxf(0,normal.dot(Vector3(-0.4,0.8,-0.5).normalized()))*0.32
 return Color(color.r*intensity,color.g*intensity,color.b*intensity,1)
