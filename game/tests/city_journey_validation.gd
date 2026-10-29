extends SceneTree
## Run: bash tools/godot.sh --headless --script res://tests/city_journey_validation.gd
const Data = preload("res://scripts/level_data.gd")
var checks := 0
var failures: Array[String] = []

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func base() -> Dictionary:
	var map := Data.blank("City validation", "nyc", 25, 25)
	map.city_journey = {"movement":"walk", "ice":[{"rect":[14,14,20,20]}], "bridges":[{"rect":[9,3,11,13], "axis":"z", "ramp_cells":3, "height":2.0}]}
	map.park_encounters = [{"id":"bush", "kind":"ambusher", "pos":[4,4], "direction":[1,0]}]
	return map

func rejected(map: Dictionary, description: String) -> void:
	check(not Data.validate(map).is_empty(), description)

func check_existing_levels(path: String) -> void:
	var directory := DirAccess.open(path)
	for name in directory.get_files():
		if name.ends_with(".json") and not name.begins_with("city_journey_"):
			var old: Variant = JSON.parse_string(FileAccess.get_file_as_string(path + "/" + name))
			check(Data.validate(old).is_empty(), "Existing level remains valid: " + path + "/" + name)
	for name in directory.get_directories():
		check_existing_levels(path + "/" + name)

func run() -> void:
	var map := base()
	check(Data.validate(map).is_empty(), "Valid walking bridge, ice and ambusher schema")
	map.city_journey.parks = [{"rect":[3,3,14,16]}]
	check(Data.validate(map).is_empty(), "Valid park grass rectangle")
	map.city_journey.parks[0].rect = [14,16,3,3]
	rejected(map, "Reject reversed park rectangle")
	for value in [null, [], "skate", 4]:
		var bad := base(); bad.city_journey = value
		rejected(bad, "Reject non-object city journey: " + str(value))
	for rect in [[1,1,30,3], [4,4,2,2], [1,1,2], [1,1,2.5,4], [1,1,NAN,4]]:
		var bad := base(); bad.city_journey.ice[0].rect = rect
		rejected(bad, "Reject invalid ice rectangle: " + str(rect))
	for value in [0, -1, NAN, INF, 9]:
		var bad := base(); bad.city_journey.bridges[0].height = value
		rejected(bad, "Reject invalid bridge height: " + str(value))
	map = base(); map.city_journey.bridges[0].ramp_cells = 6
	rejected(map, "Reject overlapping bridge ramps")
	map = base(); map.city_journey.bridges[0].axis = "north"
	rejected(map, "Reject unknown bridge axis")
	map = base(); map.city_journey.ramps = [{"from":[2,2],"to":[4,4],"rise":0.8}]
	rejected(map, "Reject diagonal launch ramp")
	map = base(); map.city_journey.rails = [{"from":[2,2],"to":[2,2],"height":0.65}]
	rejected(map, "Reject zero length grind rail")
	map = base(); map.city_journey.rails = [{"from":[2,2],"to":[2,6],"height":0.65}]
	check(Data.validate(map).is_empty(), "Valid cardinal grind rail")
	map = base()
	map.objects = [{"id":"bridge-rider", "type":"skater", "pos":[9,6], "speed":3, "route":[{"pos":[9,6],"height":2},{"pos":[11,6],"height":2},{"pos":[11,10],"height":2},{"pos":[9,10],"height":2}]}]
	check(Data.validate(map).is_empty(), "Bridge rider can use the actual two-metre deck")
	var floating := map.duplicate(true)
	floating.city_journey.erase("bridges")
	rejected(floating, "Reject elevated rider without a supporting bridge")
	floating = map.duplicate(true)
	floating.objects[0].route[2].pos = [13,10]
	rejected(floating, "Reject elevated skater route leaving bridge footprint")
	floating = map.duplicate(true)
	floating.objects[0].route[1].height = 3
	rejected(floating, "Reject rider floating above a real bridge")
	map = base()
	map.city_journey.buildings = [{"rect":[3,8,5,10],"height":4.0}]
	rejected(map, "Reject building scenery blocking a playable path")
	for y in range(8,11):
		for x in range(3,6): map.tiles[y][x] = "wall"
	check(Data.validate(map).is_empty(), "Building shell fits existing blocked footprint")
	map.city_journey.buildings[0].height = INF
	rejected(map, "Reject unbounded building height")
	for kind in ["ambusher", "pigeons", "purse", "ice_duet"]:
		map = base(); map.park_encounters[0].kind = kind
		check(Data.validate(map).is_empty(), "Accept supported park encounter " + kind)
	for direction in [[1,1], [0,0], [2,0], [NAN,0], [1], "north"]:
		map = base(); map.park_encounters[0].direction = direction
		rejected(map, "Reject invalid hazard direction: " + str(direction))
	map = base(); map.park_encounters.append(map.park_encounters[0].duplicate(true))
	rejected(map, "Reject duplicate park hazard IDs")
	map = base(); map.park_encounters[0].phase = INF
	rejected(map, "Reject nonfinite park phase")
	map = base(); map.park_encounters[0].radius = -1
	rejected(map, "Reject negative duet radius")
	map = base()
	for x in range(3, 9): map.tiles[18][x] = "road"
	map.traffic = [{"row":18,"columns":[3,8],"direction":1,"speed":3,"spacing":9,"vehicles":["taxi"],"jam":{"stopped":3,"moving":4,"phase":0}}]
	check(Data.validate(map).is_empty(), "Traffic accepts a bounded street span with stop/go timing")
	var bad := map.duplicate(true); bad.traffic[0].jam.stopped = 0
	rejected(bad, "Reject zero jam stop window")
	bad = map.duplicate(true); bad.traffic[0].jam.moving = NAN
	rejected(bad, "Reject nonfinite jam move window")
	bad = map.duplicate(true); bad.traffic[0].columns = [8,3]
	rejected(bad, "Reject reversed traffic span")
	bad = map.duplicate(true); bad.tiles[18][5] = "floor"
	rejected(bad, "Require continuous road inside declared street span")
	# A low wall separates two regions. Only the declared directional launch
	# grants structural access; removing or invalidating it must close the route.
	map = Data.blank("Ramp link", "nyc", 15, 15)
	map.spawn = [7,11]; map.exit = [7,3]
	for x in range(1,14): map.tiles[7][x] = "wall"
	map.city_journey = {"movement":"skate", "ramps":[{"from":[7,11],"to":[7,9],"rise":0.8,"landing":[7,5]}]}
	check(Data.validate(map).is_empty() and Data.reachable(map), "Declared valid launch connects separated ground regions")
	bad = map.duplicate(true); bad.city_journey.ramps[0].erase("landing")
	check(not Data.reachable(bad), "Ramp without declared landing cannot bypass a wall in structural check")
	bad = map.duplicate(true); bad.city_journey.ramps[0].landing = [8,5]
	check(not Data.reachable(bad), "Invalid diagonal landing grants no structural shortcut")
	bad = map.duplicate(true); bad.city_journey.movement = "walk"
	rejected(bad, "Walking cannot claim skateboard launch reachability")
	bad = map.duplicate(true); bad.tiles[5][7] = "water"
	rejected(bad, "Declared ramp landing cannot be water")
	bad = map.duplicate(true); bad.spawn = [7,3]; bad.exit = [7,11]
	check(not Data.reachable(bad), "Launch connection is directional")
	# Existing shipped content uses no new fields; preserve its validator contract.
	check_existing_levels("res://levels")
	for name in ["city_journey_01_blocks_park.json", "city_journey_02_skate_escape.json"]:
		if FileAccess.file_exists("res://levels/" + name):
			var authored: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://levels/" + name))
			var error := Data.validate(authored)
			check(error.is_empty(), "Authored new level validates: " + name + " " + error)
			if error.is_empty(): check(Data.reachable(authored), "Authored new level has a structural route: " + name)
	print("CITY JOURNEY VALIDATION: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
