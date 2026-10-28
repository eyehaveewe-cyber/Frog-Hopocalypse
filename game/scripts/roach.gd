extends "res://scripts/actor.gd"
## Distance-driven alternating tripod gait, with separate antenna motion.
const Streetlife = preload("res://scripts/nyc_streetlife_art.gd")
var species := "roach"
var legs: Array[Node] = []
var antennae: Array[Node] = []
var gait_distance := 0.0
var antenna_clock := 0.0

func setup(player_actor: bool, theme_name: String, obj: Dictionary = {}, hat: bool = true) -> void:
	super.setup(player_actor, theme_name, obj, hat)
	species = "roach"
	remove_child(visual)
	visual.queue_free()
	visual = Streetlife.roach()
	add_child(visual)
	legs = visual.find_children("Leg_*", "Node3D", true, false)
	for key in ["AntennaL", "AntennaR"]:
		antennae.append(visual.find_child(key, true, false))

func step(delta: float, input_vector: Vector2 = Vector2.ZERO) -> void:
	var before := position
	super.step(delta, input_vector)
	var travel := before.distance_to(position)
	gait_distance += travel
	antenna_clock += delta
	visual.position.y = 0
	for i in range(legs.size()):
		var side := -1.0 if "L" in str(legs[i].name) else 1.0
		var pair := int(str(legs[i].name).right(1))
		var phase := gait_distance * 20.0 + (pair % 2) * PI + (PI if side > 0 else 0.0)
		legs[i].rotation.y = sin(phase) * 0.33
		legs[i].rotation.z = maxf(0, cos(phase)) * side * 0.2
	for i in range(antennae.size()):
		antennae[i].rotation.y = sin(antenna_clock * 5.0 + i * 1.7) * 0.16
