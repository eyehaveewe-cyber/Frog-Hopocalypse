extends Node3D
## Fixed world-space cutout art, independent of course size and landmark LOD.
const Models=preload("res://scripts/landmark_models.gd")
const TEXTURES={"sphinx":preload("res://art/backdrops/sphinx.png"),"osiris":preload("res://art/backdrops/osiris.png"),"pyramid":preload("res://art/backdrops/pyramid.png"),"moss_tree":preload("res://art/backdrops/moss_tree.png"),"heron":preload("res://art/backdrops/heron.png")}
const PORTRAIT_HEIGHT=1.5
const MAX_COUNT=4
static var materials:Dictionary={}
var world:Node3D
var entries:Array=[]
var sea:MeshInstance3D

static func material(kind:String)->StandardMaterial3D:
 if materials.has(kind):return materials[kind]
 var mat:=StandardMaterial3D.new()
 mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
 mat.alpha_scissor_threshold=0.5
 mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
 mat.albedo_texture=TEXTURES[kind]
 mat.albedo_color=Color(0.83,0.87,0.9,1)
 # Leave depth testing/writing enabled: foreground objects occlude the art.
 materials[kind]=mat
 return mat

func setup(level:Dictionary,owner_world:Node3D)->void:
 world=owner_world
 for obj in level.objects:
  if obj.type!="backdrop":continue
  var kind:String=obj.get("backdrop_kind","pyramid")
  var anchor:Vector3=world.cell_position(obj.pos)
  var direction:=Vector3(anchor.x,0,anchor.z).normalized()
  if direction.length_squared()<0.01:direction=Vector3.FORWARD
  var distance:float=obj.get("backdrop_distance",480)
  var height:float=PORTRAIT_HEIGHT*float(obj.get("backdrop_scale",80))
  var texture:Texture2D=TEXTURES[kind]
  var width:float=height*float(texture.get_width())/float(texture.get_height())
  var quad:=QuadMesh.new()
  quad.size=Vector2(width,height)
  var card:=MeshInstance3D.new()
  card.name=str(obj.id)
  card.mesh=quad
  card.material_override=material(kind)
  card.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  card.position=direction*distance+Vector3(0,height/2-0.6,0)
  var normal:Vector3=-direction
  card.basis=Basis(Vector3(normal.z,0,-normal.x),Vector3.UP,normal)
  add_child(card)
  # Small, fixed map thumbnail at the authored ground pin, not the virtual sea.
  var thumbnail:=MeshInstance3D.new()
  var icon:=QuadMesh.new()
  icon.size=Vector2(2.4*width/height,2.4)
  thumbnail.mesh=icon
  thumbnail.material_override=material(kind)
  thumbnail.position=anchor+Vector3(0,0.15,0)
  thumbnail.rotation.x=-PI/2
  thumbnail.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  add_child(thumbnail)
  if world.editing:
   var pin:=MeshInstance3D.new()
   var mark:=BoxMesh.new()
   mark.size=Vector3(0.35,0.04,0.35)
   pin.mesh=mark
   var gold:=StandardMaterial3D.new()
   gold.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
   gold.albedo_color=Color("f5ce70")
   gold.no_depth_test=true
   gold.render_priority=2
   pin.material_override=gold
   pin.position=anchor+Vector3(0,0.18,0)
   pin.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
   add_child(pin)
  entries.append({"obj":obj,"card":card,"thumbnail":thumbnail,"anchor":anchor,"direction":direction,"height":height,"width":width,"distance":distance})
 if not entries.is_empty():
  sea=MeshInstance3D.new()
  sea.name="BackdropHorizonSea"
  var plane:=PlaneMesh.new()
  plane.size=Vector2(8192,8192)
  sea.mesh=plane
  sea.position.y=-0.62
  var ink:=StandardMaterial3D.new()
  ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  ink.albedo_color=Color("2f3653") if level.theme=="swamp" else Color("245667")
  sea.material_override=ink
  sea.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  add_child(sea)
 configure_view()

func configure_view()->void:
 var full:bool=world.editing or world.map_view
 for entry in entries:
  entry.card.visible=not full
  entry.thumbnail.visible=full
 if is_instance_valid(sea):sea.visible=not full

func far_limit()->float:
 var result:=0.0
 for entry in entries:
  result=maxf(result,entry.distance+240+maxf(world.level.width,world.level.height)*world.CELL)
 return result

func stats()->Dictionary:
 var pixels:=0.0
 var visible:=0
 var viewport:Vector2=world.get_viewport().get_visible_rect().size
 for entry in entries:
  if not entry.card.visible:continue
  visible+=1
  var rect:=Rect2()
  var started:=false
  var has_front:=false
  for corner in [Vector3(-entry.width/2,-entry.height/2,0),Vector3(entry.width/2,-entry.height/2,0),Vector3(entry.width/2,entry.height/2,0),Vector3(-entry.width/2,entry.height/2,0)]:
   var point:Vector3=entry.card.to_global(corner)
   has_front=has_front or not world.camera.is_position_behind(point)
   var screen:Vector2=world.camera.unproject_position(point)
   if not started:rect=Rect2(screen,Vector2.ZERO);started=true
   else:rect=rect.expand(screen)
  if has_front:
   var clipped:Rect2=rect.intersection(Rect2(Vector2.ZERO,viewport))
   pixels+=maxf(0,clipped.size.x)*maxf(0,clipped.size.y)
 return {"cards":entries.size(),"active_cards":visible,"card_triangles":visible*2,"horizon_triangles":2 if visible>0 else 0,"quad_rect_pixels":roundi(pixels),"viewport_pixels":int(viewport.x*viewport.y),"camera_far":world.camera.far}
