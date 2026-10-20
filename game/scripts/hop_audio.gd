extends Node
## Original CC0 synthesis. Separate short effects never queue or replace recorded voices.
var enabled := true
var unlocked := false
var palette := "soft"
var gain := 0.7
var ducked := false
var takeoff: AudioStreamPlayer
var landing: AudioStreamPlayer
var clips: Dictionary = {}
var generation := 0
var sequence := 0
var history: Array[String] = []
func _ready() -> void:
 takeoff=AudioStreamPlayer.new();landing=AudioStreamPlayer.new()
 add_child(takeoff);add_child(landing)
 for bank in ["soft","retro"]:
  for event in ["takeoff","landing"]:
   for variant in range(3):
    var key="%s_%s_%d"%[bank,event,variant]
    clips[key]=load("res://audio/hop/"+key+".wav")
 apply_gain()
func clear() -> void:
 generation+=1
 takeoff.stop();landing.stop()
func set_enabled(value: bool) -> void:
 enabled=value
 if not enabled:clear()
func set_gain(value: float) -> void:
 gain=clampf(value,0.0,1.0)
 apply_gain()
 if gain==0:clear()
func apply_gain() -> void:
 var db := -80.0 if gain<=0 else -8.0+linear_to_db(gain*(0.55 if ducked else 1.0))
 takeoff.volume_db=db;landing.volume_db=db-2.0
func play_event(event: String, voice_busy: bool = false) -> void:
 if not enabled or not unlocked or gain<=0:return
 ducked=voice_busy;apply_gain()
 var key="%s_%s_%d"%[palette,event,sequence%3]
 sequence+=1
 var player:=takeoff if event=="takeoff" else landing
 player.stream=clips[key];player.play()
 history.append(key)
 if history.size()>40:history.pop_front()
