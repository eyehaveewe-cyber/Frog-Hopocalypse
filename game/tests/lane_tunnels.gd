extends SceneTree
const Data = preload("res://scripts/level_data.gd")
const Tunnels = preload("res://scripts/lane_tunnels.gd")
var app: Control
var checks := 0
var failures: Array = []
func check(ok: bool, message: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok: failures.append(message)
func _initialize() -> void:
	app = preload("res://main.tscn").instantiate()
	app.rule_notices_enabled = false
	root.add_child(app)
	call_deferred("run")
func fixture() -> Dictionary:
	var d := Data.blank("Portal fixture","egypt",9,9)
	for x in range(1,8):
		d.tiles[4][x] = "road"
		d.tiles[5][x] = "water"
	d.objects = [{"id":"car","type":"car","pos":[7,4],"length":1.5,"speed":4.0,"direction":1,"solid":false},
		{"id":"log","type":"log","pos":[7,5],"length":6.0,"speed":4.0,"direction":1,"solid":false}]
	return d
func run() -> void:
	await process_frame
	app.set_process(false)
	app.set_sound_enabled(false)
	app.exit_preview = false
	var data := fixture()
	var before := data.duplicate(true)
	var plans := Tunnels.plan(data,1.8)
	check(plans.size() == 4 and data == before, "Two full-width wrapping lanes gain four portals without changing map data")
	var portal_root := Node3D.new()
	root.add_child(portal_root)
	for theme_name in Data.THEMES:
		Tunnels.build(portal_root,plans,theme_name)
	check(portal_root.get_child_count() == 16, "All four existing theme kits build both road and water portals")
	check(portal_root.find_children("*","CollisionObject3D",true,false).is_empty(), "Tunnel art adds no collision or gameplay obstacles")
	var clear := true
	for mesh in portal_root.find_children("*","MeshInstance3D",true,false):
		var p: Dictionary = mesh.get_parent().get_meta("lane_tunnel")
		var box: AABB = mesh.get_aabb()
		var minimum: float = mesh.global_position.x + box.position.x
		var maximum: float = mesh.global_position.x + box.end.x
		if (p.side > 0 and minimum < p.inner-0.001) or (p.side < 0 and maximum > -p.inner+0.001): clear = false
	check(clear, "Every tunnel mesh stays outside the playable interior, including the opening trim")
	portal_root.queue_free()
	var sparse := data.duplicate(true)
	sparse.tiles[4][3] = "floor"
	check(Tunnels.plan(sparse,1.8).size() == 2, "A partial interior road does not receive misleading full-width portals")
	var border := data.duplicate(true)
	border.tiles[4][0] = "road"
	check(Tunnels.plan(border,1.8).size() == 2, "An authored playable border is never decorated over")
	var tiled := data.duplicate(true)
	tiled.game_mode = "tile"
	check(Tunnels.plan(tiled,1.8).is_empty(), "Tile movers that reverse instead of wrapping retain their visible endpoints")
	var patrol := data.duplicate(true)
	patrol.objects = [{"id":"p","type":"patrol_car","pos":[3,4],"solid":false,"length":1,"speed":1}]
	check(Tunnels.plan(patrol,1.8).is_empty(), "Bounded patrol cars do not gain fake entrance tunnels")
	var repeated := data.duplicate(true)
	var second: Dictionary = repeated.objects[0].duplicate(true)
	second.id = "second"
	second.length = 3.0
	repeated.objects.append(second)
	var long_plans := Tunnels.plan(repeated,1.8)
	check(long_plans.size() == 4 and is_equal_approx(long_plans[0].depth,7.2), "A shared lane uses one pair sized to cover its longest mover")
	app.level = data
	app.enter_editor()
	check(app.world.lane_tunnel_plans.size() == 4, "Editor shows the same generated portals as gameplay")
	var static_count: int = app.world.geometry.find_children("*","StaticBody3D",true,false).size()
	app.playtest()
	app.world.set_physics_process(false)
	await physics_frame
	check(app.world.geometry.find_children("*","StaticBody3D",true,false).size() == static_count, "Playtest retains the editor's original static boundary colliders")
	var initial: Vector3 = app.world.crossing.movers[0].node.position
	app.world._physics_process(1.0/60)
	check(is_equal_approx(app.world.crossing.movers[0].node.position.x-initial.x,4.0/60), "Car speed is unchanged by the tunnel presentation")
	var wrapped := {"car":false,"log":false}
	var covered := true
	for i in range(260):
		await physics_frame
		app.world._physics_process(1.0/60)
		for mover in app.world.crossing.movers:
			if mover.wrapped:
				wrapped[mover.kind] = true
				var match_plan: Dictionary = plans.filter(func(p): return p.row == int(app.world.position_cell(mover.node.position).y) and p.side == signf(mover.node.position.x))[0]
				if absf(mover.node.position.x)+mover.length/2 > match_plan.inner+match_plan.depth: covered = false
	check(wrapped.car and wrapped.log and covered, "Both car and longest log wrap inside the covered seam using real continuous simulation")
	check(app.world.result.is_empty() and app.level == before, "Portals do not alter the safe spawn or authored document")
	app.enter_editor()
	check(app.level == before, "Returning from playtest retains exact saved terrain and entity settings")
	var campaign := Data.load_json("res://levels/little_frog_crossing.json")
	check(Tunnels.plan(campaign,1.8).size() == 16, "Baby Mode's traffic/log finale gains eight clear lane pairs")
	app.hop_audio.clear()
	app.voice.clear()
	print("LANE TUNNELS: %d checks, %d failures" % [checks,failures.size()])
	OS.delay_msec(150)
	app.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
