extends RefCounted
## Per-level variations. Missing fields preserve every legacy map's rules.
static func charged(level: Dictionary) -> bool:
 return mode(level) == "charged"

static func mode(level: Dictionary) -> String:
 return str(level.get("rules", {}).get("long_hop", "free")) if level.get("game_mode", "hopan") == "tile" else "free"

static func collectible(level: Dictionary) -> bool:
 return mode(level) in ["fragments", "powerup"]

static func short_rule(level: Dictionary) -> String:
 match mode(level):
  "charged": return "%d short hops refill it" % charge_hops(level)
  "fragments": return "3 fragments = 1 long hop"
  "powerup": return "1 Hop seed = 1 long hop"
 return "Free long hops · no cooldown"

static func charge_hops(level: Dictionary) -> int:
 return int(level.get("rules", {}).get("charge_hops", 10))

static func cards(level: Dictionary) -> Array:
 var result: Array = []
 if level.has("city_journey"):
  if level.city_journey.get("movement") == "skate":
   result.append({"id":"city-skate-v1","title":"TAKE THE BOARD","body":"WASD / arrows steer and push. Shift or Brake slows you down. Space or Jump ollies. Approach ramps straight with speed to clear walls; approach a rail along its length to grind. Watch for other riders. Flags are retry checkpoints."})
  else:
   result.append({"id":"city-blocks-v1","title":"BLOCKS, BRIDGE & PARK","body":"Follow the marked route north, across the bridge, through the park and back south. Wait for traffic openings. Watch warning marks before park attacks. Ice carries your momentum: counter-steer or hold Shift / Brake. Flags save retry points. M opens a paused overhead map."})
 if level.get("game_mode", "hopan") == "tile":
  result.append({"id":"tile-v2", "title":"TILE HOPS", "body":"A direction hops one tile. Tap Long hop or press Space, then choose a direction to jump two. Shift + direction also works. Walls stop both."})
  if charged(level):
   var count := charge_hops(level)
   result.append({"id":"charge-%d-v1" % count, "title":"CHARGE YOUR HOPS", "body":"%d short hops recharge one long hop. Start charged. Checkpoint retries refill it." % count})
  elif mode(level) == "fragments":
   result.append({"id":"fragments-v1", "title":"GATHER YOUR HOP", "body":"Land on three triangle fragments to earn one long hop. Start empty. Carry one hop; extra fragments wait on the ground until you use it. Hopping over a pickup does not collect it. Retry restores your checkpoint's pickups and reserve."})
  elif mode(level) == "powerup":
   result.append({"id":"powerup-v1", "title":"ONE SEED, ONE LEAP", "body":"Land on a diamond Hop seed to earn one long hop. Start empty. Carry one; extra seeds wait until you use it. No timer or automatic refill. Retry restores your checkpoint's pickups and reserve."})
  else:
   result.append({"id":"free-long-hop-v1", "title":"FREE LONG HOPS", "body":"Long hop whenever the frog is ready. No charge needed."})
 if level.get("move_with_me", false):
  result.append({"id":"move-with-me-v1", "title":"MOVE WITH ME", "body":"Stop to freeze the hazards. They move when you move."})
 return result
