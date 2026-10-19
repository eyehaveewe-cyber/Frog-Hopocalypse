extends RefCounted
## Per-level variations. Missing fields preserve every legacy map's rules.
static func charged(level: Dictionary) -> bool:
 return level.get("game_mode", "hopan") == "tile" and level.get("rules", {}).get("long_hop", "free") == "charged"

static func charge_hops(level: Dictionary) -> int:
 return int(level.get("rules", {}).get("charge_hops", 10))

static func cards(level: Dictionary) -> Array:
 var result: Array = []
 if level.get("game_mode", "hopan") == "tile":
  result.append({"id":"tile-v1", "title":"TILE HOPS", "body":"Hop one tile with a direction. Use Shift or Long hop to jump two. Walls stop both."})
  if charged(level):
   var count := charge_hops(level)
   result.append({"id":"charge-%d-v1" % count, "title":"CHARGE YOUR HOPS", "body":"%d short hops recharge one long hop. Start charged. Checkpoint retries refill it." % count})
  else:
   result.append({"id":"free-long-hop-v1", "title":"FREE LONG HOPS", "body":"Long hop whenever the frog is ready. No charge needed."})
 if level.get("move_with_me", false):
  result.append({"id":"move-with-me-v1", "title":"MOVE WITH ME", "body":"Stop to freeze the hazards. They move when you move."})
 return result
