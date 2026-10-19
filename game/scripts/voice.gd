extends Node
## One voice at a time. Only explicitly approved, bundled recordings are loaded.
const FILE_ALIASES = {"traffic_start": "warning_baby_mode_in_traffic", "traffic_return": "warning_baby_in_traffic"}
const CUES = ["baby_mode", "begin", "baby_win", "traffic_start", "traffic_return", "baby_frog", "splatted", "sunken_frog", "frog_sunk", "bugsploded", "dartsploded", "watersploded", "gloopbutt", "frogbutt", "busted", "wormed", "wormsploded"]
var player: AudioStreamPlayer
var clips: Dictionary = {}
var queue: Array[String] = []
var enabled := true
var gesture_received := false
var history: Array[String] = []
var drowning_count := 0
var patrol_count := 0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.volume_db = -2.0
	add_child(player)
	player.finished.connect(play_next)
	rng.randomize()
	for cue in CUES:
		var path: String = "res://audio/" + str(FILE_ALIASES.get(cue, cue)) + ".ogg"
		if ResourceLoader.exists(path):
			clips[cue] = load(path)

func unlock() -> void:
	gesture_received = true
	play_next()

func clear() -> void:
	queue.clear()
	player.stop()

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		clear()

func say(cue: String) -> void:
	if not enabled or not gesture_received or cue not in clips:
		return
	queue.append(cue)
	play_next()

func busy() -> bool:
	return player.playing or not queue.is_empty()

func play_next() -> void:
	if not enabled or not gesture_received or player.playing or queue.is_empty():
		return
	var cue: String = queue.pop_front()
	player.stream = clips[cue]
	history.append(cue)
	if history.size() > 40:
		history.pop_front()
	player.play()

func death_cue(reason: String, cause: String) -> String:
	# A rare general line; all other deaths retain their specific vocabulary.
	if rng.randf() < 0.06:
		return "busted"
	match reason:
		"SPIKED!": return "busted"
		"SQUISHED!": return "splatted"
		"HIT!": return "dartsploded"
		"SPLASHED!":
			if rng.randf() < 0.18:
				return "watersploded"
			var cue := "sunken_frog" if drowning_count % 2 == 0 else "frog_sunk"
			drowning_count += 1
			return cue
		"CROAKED!":
			if cause in ["patrol", "seam_patrol"]:
				var cue := "wormed" if patrol_count % 2 == 0 else "wormsploded"
				patrol_count += 1
				return cue
			return "bugsploded"
	return ""
