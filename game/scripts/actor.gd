extends CharacterBody3D
const Art = preload("res://scripts/art.gd")
var visual: Node3D
var is_player := false
var behavior := "wander"
var speed := 1.6
var waypoints: Array[Vector3] = []
var waypoint_index := 0
var direction := Vector3.ZERO
var turn_timer := 0.0
var hop_clock := 0.0
var rng := RandomNumberGenerator.new()
var stuck_time := 0.0

func setup(player: bool, theme_name: String, obj: Dictionary = {}, hat: bool = true) -> void:
	is_player = player
	behavior = obj.get("behavior", "wander")
	speed = 4.2 if player else float(obj.get("speed", 1.6))
	collision_layer = 2 if player else 4
	collision_mask = 1
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.32 if player else 0.38
	shape.shape = sphere
	shape.position.y = 0.34
	add_child(shape)
	visual = Art.frog(hat) if player else Art.critter(theme_name, behavior)
	add_child(visual)
	var shadow := Art.cylinder(self, 0.43 if player else 0.4, 0.43 if player else 0.4, 0.012, Vector3(0, 0.015, 0), Color(0.06, 0.09, 0.06, 0.4))
	var shadow_material := Art.mat(Color(0.06, 0.09, 0.06, 0.4)).duplicate() as StandardMaterial3D
	shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow.material_override = shadow_material
	rng.seed = hash(obj.get("id", "frog"))
	choose_direction()

func choose_direction() -> void:
	var angle := rng.randf_range(-PI, PI)
	direction = Vector3(sin(angle), 0, cos(angle))
	turn_timer = rng.randf_range(0.8, 2.2)

func step(delta: float, input_vector: Vector2 = Vector2.ZERO) -> void:
	if is_player:
		direction = Vector3(input_vector.x, 0, input_vector.y).limit_length()
	elif behavior == "patrol" and waypoints.size() > 0:
		var target := waypoints[waypoint_index]
		if position.distance_to(target) < 0.20:
			waypoint_index = (waypoint_index + 1) % waypoints.size()
			target = waypoints[waypoint_index]
		direction = (target - position).normalized()
	else:
		turn_timer -= delta
		if turn_timer <= 0:
			choose_direction()
	velocity = direction * speed
	var before := position
	move_and_slide()
	position.y = 0
	if not is_player and get_slide_collision_count() > 0:
		if behavior == "wander":
			var normal := get_slide_collision(0).get_normal()
			direction = direction.bounce(normal).normalized()
			turn_timer = 0.5
		else:
			stuck_time += delta
			if stuck_time > 0.5:
				waypoint_index = (waypoint_index + 1) % maxi(1, waypoints.size())
				stuck_time = 0
	else:
		stuck_time = 0
	if position.distance_to(before) > delta * 0.1:
		hop_clock += delta * (16 if is_player else 10)
		visual.position.y = absf(sin(hop_clock)) * (0.13 if is_player else 0.045)
		if is_player:
			visual.get_node("HindLegL").rotation.x = sin(hop_clock) * 0.22
			visual.get_node("HindLegR").rotation.x = sin(hop_clock) * 0.22
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-direction.x, -direction.z), minf(1, delta * 18))
	else:
		visual.position.y = lerpf(visual.position.y, 0, delta * 12)

func set_hat(kind: Variant) -> void:
	if is_player:
		var selected: String = ("pharaoh" if kind else "none") if kind is bool else str(kind)
		visual.get_node("HatSocket/PharaohHat").visible = selected == "pharaoh"
		visual.get_node("HatSocket/BabyBonnet").visible = selected == "baby"
