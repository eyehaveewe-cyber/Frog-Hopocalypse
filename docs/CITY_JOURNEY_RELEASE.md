# City Journey release

## What to play

Open **Levels → City Journey**. Blocks, Bridge & Central Park is available immediately. Finish it to unlock Skate Escape; the result screen offers the next level. The unlock survives reload alongside earlier clears, outfits and editor saves. Baby Mode remains the first set; all 35 levels are in the same game.

- **Blocks, Bridge & Central Park:** 49 × 59 cells, several city blocks, independently timed stop/go streets, roaches, an elevated skater bridge, park skateboarders, bush ambusher, pigeon flock, purse swing and a sliding rink with paired skaters. Five flags provide retry checkpoints. The wider southbound route and camera lookahead make the return easier to see.
- **Skate Escape:** 37 × 43 cells, three required ramp launches over walls, two optional grind rails and crossing riders. The frog visibly rides a board. Walls still collide: actual height determines whether a jump clears them.
- **Controls:** WASD/arrows or touch joystick steer. On ice or the board, hold Shift / Brake to slow down. Space / Jump ollies on the board. Approach gold ramps with speed; approach rails along their length to grind. M shows the paused overhead map; R retries the latest checkpoint.

The city is an authored game layout, not a reproduction of real Central Park. Park attacks use warnings, committed attack paths and recovery windows. They do not aim invisibly at the player's future position.

## Acceptance evidence

Native Godot 4.7.2 checks:

| Suite | Passing checks | What it establishes |
| --- | ---: | --- |
| `city_journey_validation.gd` | 97 | New schemas and both authored maps; existing bundled maps; malformed fields and undeclared wall shortcuts rejected |
| `city_journey_movement.gd` | 26 | Physical bridge/ramp clearance, ice momentum/braking, rail mount/exit, edge-triggered jump, 30/60/120 Hz comparisons |
| `city_park_hazards.gd` | 44 | Warning/attack/recovery contacts, dodges, paired skaters, jam clocks and localized traffic |
| `city_journey_routes.gd -- --both-phases` | 14 | Continuous start-to-exit traversals of both levels at two departure phases, hazards active |
| `city_journey_progression.gd` | 11 | Win-signal unlock, save/reload, older progress retained, checkpoint retry and return to ordinary walking |
| `one_game.gd` | 84 | All 35 campaign levels and shared editor/save integration |
| Existing integration / skater contacts | 75 / 25 | Existing game/result flow and rider collision behavior |

The full-route driver only supplies normal movement and reads hazard state to choose lines/timing. It does not teleport, stop hazards or disable collision. City runs travelled 264.53 world units in 69.73 simulated seconds, reached all five flags, traversed the 2-unit bridge and spent 257 physics frames on ice. Skate runs travelled 139.11 units in 26.18–26.93 simulated seconds, used all three ramps and both rails. These are successful automated routes, not expected first-time completion times.

**21 actual browser checks passed**, with no captured browser or engine console errors. Touch Brake reduced board speed to zero; releasing it and pressing Jump produced an airborne ollie. Browser evidence is saved in [city-journey-evidence](city-journey-evidence/). The browser harness uses actual menu, keyboard and touch inputs; the debug probe is read-only. A returning-player profile fixture unlocks the skate level for browser checks. Actual win-to-unlock and persistence are separately exercised by the native progression test. Browser screenshots show runtime renders rather than mockups. A continuous browser bridge-capture attempt ended in normal traffic collisions at the first jam; it did not complete the city route. Complete bridge/park/rink and skate traversals are native acceptance evidence, not claimed browser completions.

## Reproduce

```bash
bash tools/godot.sh --headless --editor --import --quit
bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/city_journey_validation.gd
bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/city_journey_movement.gd
bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/city_park_hazards.gd
bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/city_journey_routes.gd -- --both-phases
XDG_DATA_HOME=$(mktemp -d /tmp/hopan-journey-profile.XXXXXX) bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/city_journey_progression.gd
bash tools/test.sh
# Serve debug export at8115 and release export at8116, then:
NODE_PATH=/opt/codex/cua_node/lib/node_modules node tools/city_journey_browser.cjs
```

`tools/build_city_journey.py` regenerates the two authored maps deterministically. [Design rationale](CITY_JOURNEY_DESIGN.md) and [hazard timings](CITY_JOURNEY_HAZARDS.md) explain route decisions and data fields.

## Limits

The user's previous 1.6/10 assessment is retained as feedback, not superseded by test counts. A 7/10 or fifteen-attempt difficulty rating is not established. Browser testing uses Chromium software rendering and touch emulation; physical mobile performance and human difficulty remain open. No FPS claim is derived from geometry or native headless timings. Only the two new levels opt into the new traversal rules; earlier level files and RiverSim content are preserved.
