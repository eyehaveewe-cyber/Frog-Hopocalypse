# Faster park encounters, Frozen Blocks and expanded Skate Escape

The user asked for quick animation-led attacks, a repeating bird-seed routine, overpass rail hoppers, an entire ice level, and a substantially larger skateboard course with manual grinding and traffic.

## Player-visible changes

Knife anticipation/strike/recovery is now **0.22 / 0.18 / 0.75 seconds**, compared with **0.85 / 0.62 / 1.8** previously. Purse timing is **0.24 / 0.22 / 0.85 seconds**, compared with **0.9 / 0.65 / 1.9**. Both use the character's wind-up instead of painted attack paths. The purse is attached to the right arm, with torso follow-through, a connected strap and contact position derived from the same arm transform as the visible bag.

The pigeon keeper cycles through **seed toss (0.28s), swoop (0.32s), feeding (0.55s), departure (0.25s), return (0.45s), perch (0.38s)**. Visible seed scatters before the birds arrive. The birds hop/peck over that patch, fly onward, circle behind the keeper, perch and repeat. Swoop and feeding occupy dangerous space; the airborne departure and return do not create an invisible ground attack. The existing skating duet's motion is retained.

The overpass has two riders, one on each side. They grind the side rails, jump onto the deck, cross and jump onto the opposite railing. Each lap chooses a different take-off point with a saved authored seed so retries and tests are reproducible. Their actual route positions drive swept collision; animation does not teleport them between rail and deck.

**Frozen Blocks** follows the city/park stage. Its **49 × 61** map has **2,461 open cells**, four dry islands with skateboarders, six roach patrols and three duet pairs on ice. Open-water barriers require alternating approaches. Ice remains slippery outside the tan islands, while the islands restore dry footing. The earlier park rink and its duet remain in place.

**Skate Escape** grows from **37 × 43 to 61 × 61**, with **1,100 open cells versus 453** (143% more usable ground). It contains six skaters, six roach patrols, six traffic lanes, three wall launches, long practice rails and two **2.6-unit raised rails above a four-lane highway**. The large courts give room to choose a line, brake and reposition; traffic, ponds and solid props interrupt those lines.

## Controls and progression

Hold **G / Grind** near an aligned rail while moving to latch. The gold rail is thicker and its approaches are visible. Once latched, releasing G retains the grind; **Space / Jump** leaves it and **Shift / Brake** releases/slows it. Passing a rail without pressing Grind does not attach automatically. The button changes to `GRINDING · Jump off` when latched. Highway rails have real sloped entry/exit supports; ground-level cars remain dangerous.

The menu order is **Blocks, Bridge & Central Park → Frozen Blocks → Skate Escape**. First-stage completion unlocks both later levels, preserving existing skate access. Internal saved indices remain city0/skate1/ice2, so earlier skateboard clears, outfits and level-builder saves retain their meaning. Next-level actions and stage numbering follow the displayed order. There are 36 campaign levels in the same game, with Baby Mode first.

## Verification

The native suites cover 104 validation checks, 49 park/hazard checks, 26 traversal checks, 16 new-feature checks, 15 progression checks, 86 all-campaign/editor checks, 75 existing integration checks and 25 existing skater contacts. The feature suite verifies manual latching, physical jump release, a highway grind above actual buses/trucks, dry island footing, continuous rail-hop seams and consistent seeded motion at 30/60/120 Hz.

**20 full-route checks pass**: all three current maps complete continuously from two departure times, using ordinary movement and read-only hazard forecasts. Hazards remain active; the driver does not teleport or disable collision. Recorded runs:

| Level | Simulated completion | Verified route behavior |
| --- | --- | --- |
| City / park | See `native-routes.txt` | Both rail hoppers active, all five flags, actual bridge height and rink sliding |
| Frozen Blocks | About 93s | Ice travel with active roaches, island riders and duet pairs |
| Expanded Skate Escape | About 32–33s | Three physical wall launches, manual highway grind and active traffic |

Browser evidence is in [ice-skate-evidence](ice-skate-evidence/): 24 campaign/UI/input checks and 6 imported motion/control checks pass, with no captured engine/browser errors. An [eight-second actual browser recording](ice-skate-evidence/park-cycle.webm) shows the quick park cycle. A visual check caught and fixed an animation scale reset that had enlarged the seed models. Normal campaign screenshots are distinguished from the small imported animation/control fixtures. Those fixtures exercise production modules through the normal editor file-import and Playtest controls; they are not claimed campaign completions. Native complete-route evidence and browser UI/input evidence serve different purposes.

## Reproduce

```bash
python3 tools/build_city_journey.py
bash tools/godot.sh --headless --editor --import --quit
bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/city_journey_routes.gd -- --both-phases
bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/ice_skate_features.gd
bash tools/godot.sh --headless --script res://tests/city_park_hazards.gd
bash tools/godot.sh --headless --script res://tests/city_journey_validation.gd
bash tools/test.sh
# Serve debug export at 8115 and release export at 8116:
NODE_PATH=/opt/codex/cua_node/lib/node_modules node tools/city_journey_browser.cjs
NODE_PATH=/opt/codex/cua_node/lib/node_modules node tools/park_motion_browser.cjs
```

Human difficulty is uncalibrated. Successful forecast-assisted routes do not establish a seven-out-of-ten rating or a human attempt count. Browser checks use software-rendered Chromium and touch emulation; physical mobile performance and subjective animation feel remain for playtesting. The scenery is an original game layout. RiverSim and other hosted routes are preserved during publication.
