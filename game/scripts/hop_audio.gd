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
var rng := RandomNumberGenerator.new()
var bags: Dictionary = {}
var last_variants: Dictionary = {}
var event_levels := {"takeoff":0.0,"landing":0.0}
var last_pitch_cents := 0.0
var history: Array[String] = []
func _ready() -> void:
 rng.randomize()
 takeoff=AudioStreamPlayer.new();landing=AudioStreamPlayer.new()
 add_child(takeoff);add_child(landing)
 for bank in ["soft","retro"]:
  for event in ["takeoff","landing"]:
   for variant in range(3):
    var key="%s_%s_%d"%[bank,event,variant]
    clips[key]=load("res://audio/hop/"+key+".wav")
 for variant in range(3):
  var key="long_takeoff_%d"%variant
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
 takeoff.volume_db=db+event_levels.takeoff;landing.volume_db=db-2.0+event_levels.landing
func play_event(event: String, voice_busy: bool = false, big: bool = false) -> void:
 if not enabled or not unlocked or gain<=0:return
 if event not in ["takeoff","landing"]:return
 ducked=voice_busy
 var group="long_takeoff" if big and event=="takeoff" else "%s_%s"%[palette,event]
 var key="%s_%d"%[group,next_variant(group)]
 sequence+=1
 var player:=takeoff if event=="takeoff" else landing
 var spread:=15.0 if big and event=="takeoff" else (40.0 if event=="takeoff" else 25.0)
 last_pitch_cents=rng.randf_range(-spread,spread)
 player.pitch_scale=pow(2.0,last_pitch_cents/1200.0)
 event_levels[event]=rng.randf_range(-0.9,0.0)
 apply_gain()
 player.stream=clips[key];player.play()
 history.append(key)
 if history.size()>40:history.pop_front()

func next_variant(group: String) -> int:
 var bag: Array = bags.get(group,[])
 if bag.is_empty():
  bag=[0,1,2]
  for i in range(2,0,-1):
   var j:=rng.randi_range(0,i)
   var saved=bag[i];bag[i]=bag[j];bag[j]=saved
  if bag[-1]==last_variants.get(group,-1):
   var saved=bag[0];bag[0]=bag[2];bag[2]=saved
 var variant:int=bag.pop_back()
 bags[group]=bag;last_variants[group]=variant
 return variant
