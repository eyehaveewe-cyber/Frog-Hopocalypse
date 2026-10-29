extends RefCounted
## Seeded per-lap stunt routes; fixed lap seam, varied take-off points.
static func route(spec: Dictionary, bridge: Dictionary, lap: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(spec.get("seed",1))+lap*7919
	var rect: Array = bridge.rect
	var axis: int = 0 if bridge.axis == "x" else 1
	var cross_axis := 1-axis
	var lo := float(rect[axis])-0.5+float(bridge.ramp_cells)+0.3
	var hi := float(rect[axis+2])+0.5-float(bridge.ramp_cells)-0.3
	var left := float(rect[cross_axis])-0.40
	var right := float(rect[cross_axis+2])+0.40
	var near_rail := left if int(spec.get("side",-1))<0 else right
	var far_rail := right if int(spec.get("side",-1))<0 else left
	var near_deck := lerpf(near_rail,far_rail,0.28)
	var far_deck := lerpf(near_rail,far_rail,0.72)
	var launch := rng.randf_range(lo+(hi-lo)*0.35,lo+(hi-lo)*0.58)
	var end := launch-0.9
	var h := float(bridge.height)
	var nodes: Array = []
	# Stored in bridge longitudinal/lateral coordinates, then mapped to grid.
	var frames := [
		[near_rail,hi,h+0.65,"grind"], [near_rail,launch,h+0.65,"ramp"],
		[lerpf(near_rail,near_deck,0.5),launch-0.5,h+1.15,"ramp"],
		[near_deck,launch-1.0,h,"push"], [far_deck,end-0.65,h,"ramp"],
		[lerpf(far_deck,far_rail,0.5),end-1.0,h+1.1,"ramp"],
		[far_rail,lo,h+0.65,"grind"], [far_rail,hi-1.1,h+0.65,"ramp"],
		[lerpf(far_rail,far_deck,0.5),hi-0.6,h+1.1,"ramp"],
		[far_deck,hi-0.3,h,"cruise"], [near_deck,hi-0.3,h,"ramp"],
		[lerpf(near_deck,near_rail,0.5),hi-0.15,h+1.1,"ramp"]]
	for f in frames:
		var pos := [0.0,0.0]
		pos[axis] = f[1]
		pos[cross_axis] = f[0]
		nodes.append({"pos":pos,"height":f[2],"trick":f[3]})
	return nodes
