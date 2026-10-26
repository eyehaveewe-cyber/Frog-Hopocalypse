extends RefCounted
## Original cosmetic geometry/textures; never writes the actor's collision transform.
static var skins:Dictionary={}
static func material(color:Color)->StandardMaterial3D:
 var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.8;return m
static func box(p:Node3D,n:String,size:Vector3,at:Vector3,c:Color)->MeshInstance3D:
 var v:=MeshInstance3D.new();v.name=n;var m:=BoxMesh.new();m.size=size;v.mesh=m;v.position=at;v.material_override=material(c);p.add_child(v,true);return v
static func cylinder(p:Node3D,n:String,r:float,h:float,at:Vector3,c:Color)->MeshInstance3D:
 var v:=MeshInstance3D.new();v.name=n;var m:=CylinderMesh.new();m.top_radius=r;m.bottom_radius=r;m.height=h;m.radial_segments=24;v.mesh=m;v.position=at;v.material_override=material(c);p.add_child(v,true);return v
static func fit_pyramid(hat:Node3D)->void:
 hat.scale=Vector3(.82,.64,.82);hat.position=Vector3(0,-.025,-.06)
 hat.get_node("GlassFaces").hide()
 cylinder(hat,"FittedHeadband",.42,.12,Vector3(0,.04,.14),Color("624d30"))
 cylinder(hat,"SoftGoldBrim",.5,.045,Vector3(0,-.01,.14),Color("c19b58"))
 var image:=Image.create(128,128,false,Image.FORMAT_RGB8)
 for y in range(128):
  for x in range(128):
   var seam:=y%16<2 or (x+(16 if (y/16)%2 else 0))%32<2
   var tone:=float((x*17+y*31)%11)/100.0
   image.set_pixel(x,y,Color("8d6c3d") if seam else Color("ceb47b").lightened(tone))
 var mat:=material(Color.WHITE);mat.albedo_texture=ImageTexture.create_from_image(image);mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 var mesh:=ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,mat)
 var corners=[Vector3(-.48,.09,-.3),Vector3(.48,.09,-.3),Vector3(.48,.09,.58),Vector3(-.48,.09,.58)]
 var apex:=Vector3(0,.98,.14)
 # Front face has a real inset viewing aperture, with stone cheeks and cap.
 for i in range(4):
  var a:Vector3=corners[i];var b:Vector3=corners[(i+1)%4]
  var triangles:Array=[]
  if i==0:
   var left:=a.lerp(b,.25);var right:=a.lerp(b,.75)
   var tl:=left.lerp(apex,.66);var tr:=right.lerp(apex,.66)
   triangles=[[a,left,tl],[a,tl,apex],[right,b,apex],[right,apex,tr],[tl,tr,apex]]
  else:triangles=[[a,b,apex]]
  for tri in triangles:
   var normal:Vector3=(tri[1]-tri[0]).cross(tri[2]-tri[0]).normalized()
   for v in tri:
    mesh.surface_set_normal(normal);mesh.surface_set_uv(Vector2((v.x+.48) if i%2==0 else (v.z+.3),v.y));mesh.surface_add_vertex(v)
 mesh.surface_end();var faces:=MeshInstance3D.new();faces.name="StoneBlockShell";faces.mesh=mesh;hat.add_child(faces)
 hat.get_node("Hourglass").position.z=-.13
static func suit(root:Node3D)->void:
 var coat:=Node3D.new();coat.name="MorningSuit";root.add_child(coat)
 var black:=Color("252b35");var grey:=Color("81838a")
 var back:=MeshInstance3D.new();back.name="TailcoatBack"
 var shell:=SphereMesh.new();shell.radius=.5;shell.height=1;shell.radial_segments=16;shell.rings=8
 back.mesh=shell;back.scale=Vector3(.81,.49,.76);back.position=Vector3(0,.31,.17);back.material_override=material(black);coat.add_child(back)
 box(coat,"BackSeam",Vector3(.018,.012,.32),Vector3(0,.555,.18),grey.darkened(.35))
 # Fitted flank panels leave the throat and eyes uncovered.
 for side in [-1,1]:
  var panel:=box(coat,"CutawayCoat",Vector3(.14,.34,.56),Vector3(side*.31,.31,.07),black);panel.rotation.z=side*.1
  var tail:=box(coat,"CoatTail",Vector3(.22,.035,.36),Vector3(side*.14,.20,.53),black);tail.rotation.x=-.22
  var lapel:=box(coat,"Lapel",Vector3(.10,.24,.045),Vector3(side*.18,.30,-.35),grey);lapel.rotation.z=-side*.3
  box(coat,"ShirtCollar",Vector3(.14,.075,.12),Vector3(side*.1,.39,-.39),Color.WHITE)
 box(coat,"Waistcoat",Vector3(.32,.23,.055),Vector3(0,.25,-.40),Color("b5aa8d"))
 for y in [.19,.26,.33]:box(coat,"WaistcoatButton",Vector3(.025,.025,.02),Vector3(0,y,-.44),black)
 box(coat,"Cravat",Vector3(.075,.15,.04),Vector3(0,.33,-.46),Color("a04352"))
 var hat:=Node3D.new();hat.name="MorningHat";root.get_node("HatSocket").add_child(hat);hat.position.z=.03
 cylinder(hat,"Brim",.36,.035,Vector3(0,.015,0),black)
 cylinder(hat,"Crown",.255,.38,Vector3(0,.21,0),black)
 cylinder(hat,"SatinBand",.259,.07,Vector3(0,.075,0),grey)
 coat.hide();hat.hide()
static func skin(kind:String)->StandardMaterial3D:
 if skins.has(kind):return skins[kind]
 var colors={"orange":Color("e98532"),"yellow":Color("efd345"),"spotted":Color("e5ce46"),"purple_white":Color("8249b9"),"gummy":Color("e64077")}
 var mat:=material(colors.get(kind,Color("9bc952")))
 if kind=="spotted":
  var img:=Image.create(64,64,false,Image.FORMAT_RGB8);img.fill(colors.spotted)
  for y in range(64):
   for x in range(64):
    for point in [Vector2(10,12),Vector2(39,9),Vector2(24,35),Vector2(53,46),Vector2(5,57)]:
     if Vector2(x,y).distance_to(point)<6:img.set_pixel(x,y,Color("3b813f"))
  mat.albedo_color=Color.WHITE;mat.albedo_texture=ImageTexture.create_from_image(img)
 if kind=="gummy":
  mat.roughness=.12;mat.metallic_specular=.85;mat.clearcoat_enabled=true;mat.clearcoat=.9
  mat.rim_enabled=true;mat.rim=.7;mat.rim_tint=.5
 skins[kind]=mat;return mat
