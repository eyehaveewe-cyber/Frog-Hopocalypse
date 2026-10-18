extends RefCounted
const Data = preload("res://scripts/level_data.gd")

func frame(app: Control, count: int = 1) -> void:
	for _i in range(count):
		await app.get_tree().physics_frame

func run(app: Control, suite: RefCounted) -> void:
	var level := Data.load_json(app.BUILTINS[3])
	suite.check(not level.is_empty() and Data.reachable(level), "Crossing JSON validates and log lanes connect the route")
	var invalid := level.duplicate(true)
	invalid.objects[0].direction = true
	suite.check(Data.validate(invalid) != "", "Malformed lane properties are rejected")
	app.load_builtin(0)
	app.start_play(false)
	suite.check(app.hat == "baby" and "baby" in app.unlocked_hats and app.world.player.visual.get_node("HatSocket/BabyBonnet").visible, "Starting Baby Mode unlocks and equips the baby bonnet")
	var cycled: Array = []
	for _i in range(3):
		app.toggle_hat()
		cycled.append(app.hat)
	suite.check(cycled == ["none", "pharaoh", "baby"], "Hat cycles only unlocked headwear, including bare head")
	app.hat = "pharaoh"
	app.save_profile()
	app.hat = "none"
	app.load_profile()
	suite.check(app.hat == "pharaoh" and "baby" in app.unlocked_hats, "Unlocked hats and equipped choice survive profile reload")
	app.load_builtin(3)
	app.start_play(false)
	await frame(app, 2)
	var log: Dictionary = app.world.crossing.movers.filter(func(m: Dictionary): return m.kind == "log")[1]
	app.world.player.position = log.node.position
	var before: Vector3 = app.world.player.position
	await frame(app, 20)
	suite.check(app.world.result.is_empty() and app.world.player.position.x > before.x + 0.1, "A stationary frog rides a moving log without splashing")
	app.toggle_map()
	var stopped: Vector3 = log.node.position
	await frame(app, 12)
	suite.check(log.node.position == stopped, "Overhead map pauses cars and logs")
	app.toggle_map()
	app.world.player.position = app.world.cell_position([1, 13])
	# Locate a genuine open-water gap, rather than assuming a starting log phase.
	for i in range(1, 16):
		var point: Vector3 = app.world.cell_position([i, 13])
		if app.world.crossing.log_at(point).is_empty():
			app.world.player.position = point
			break
	await frame(app, 2)
	suite.check(app.world.result == "SPLASHED!", "Open water between logs remains a hazard")
	app.retry()
	await frame(app, 2)
	var car: Dictionary = app.world.crossing.movers.filter(func(m: Dictionary): return m.kind == "car")[0]
	app.world.player.position = car.node.position
	await frame(app, 2)
	suite.check(app.world.result == "SQUISHED!", "Moving traffic hits the frog")
	app.retry()
	app.world.player.position = app.world.cell_position(level.checkpoint)
	await frame(app, 2)
	app.world.finish("SQUISHED!")
	app.retry()
	suite.check(app.world.position_cell(app.world.player.position) == Vector2i(8, 10) and app.world.result.is_empty(), "After the log bank, retry restarts at the safe checkpoint")
	# Traverse every section through the actual moving world at several arrival
	# phases. The driver waits on banks, then walks; no hazards are disabled.
	for delay in [0, 100, 220]:
		app.load_builtin(3)
		app.start_play(false)
		await frame(app, delay + 2)
		var survived := await walk(app, 16)
		if survived:
			survived = await walk(app, 15)
		if survived:
			survived = await wait_window(app, [14, 13, 12], 15, true)
		if survived:
			survived = await walk(app, 11)
		if survived:
			survived = await walk(app, 10)
		if survived:
			survived = await wait_window(app, [9, 8, 7], 10, false)
		if survived:
			survived = await walk(app, 6)
		if survived:
			survived = await walk(app, 2)
		suite.check(survived and app.world.result == "LEVEL COMPLETE!", "Finale physically crossed with active traffic/logs at arrival phase %d" % delay)
	app.completed_stages = [0, 1, 2]
	app.load_builtin(3)
	app.start_play(false)
	app.world.finish("LEVEL COMPLETE!")
	app.load_profile()
	suite.check(app.completed_stages.size() == 4, "All four Baby Mode stage completions persist")

func predicted_x(mover: Dictionary, after: float) -> float:
	return wrapf(mover.node.position.x + mover.speed * after, -mover.limit, mover.limit)

func wait_window(app: Control, rows: Array, bank: int, logs: bool) -> bool:
	for _attempt in range(1500):
		var safe := true
		for row in rows:
			var arrival: float = (bank - row) * app.world.CELL / 4.2
			var good_log := false
			for mover in app.world.crossing.movers:
				if app.world.position_cell(mover.node.position).y != row:
					continue
				var x := predicted_x(mover, arrival)
				if logs and mover.kind == "log" and absf(x) < mover.length / 2 - 1.4:
					good_log = true
				elif not logs and mover.kind == "car" and absf(x) < mover.length / 2 + 1.7:
					safe = false
			if logs and not good_log:
				safe = false
		if safe:
			return true
		await frame(app)
	return false

func walk(app: Control, row: int) -> bool:
	var target: Vector3 = app.world.cell_position([8, row])
	# The first road band can also be approached at different phases.
	if row == 16 and not await wait_window(app, [18, 17], 19, false):
		return false
	for _i in range(600):
		if not app.world.result.is_empty():
			app.world.input_vector = Vector2.ZERO
			return app.world.result == "LEVEL COMPLETE!"
		var offset: Vector3 = target - app.world.player.position
		if offset.length() < 0.09:
			app.world.input_vector = Vector2.ZERO
			return true
		app.world.input_vector = Vector2(offset.x, offset.z).normalized()
		await frame(app)
	app.world.input_vector = Vector2.ZERO
	return false
