# NYC difficulty pass

The user rated both city sets at 1/10 and requested 7/10, describing that as roughly 15 attempts to clear a level. Their 10/10 reference was roughly 50 attempts. This pass targets that substantial increase across all six New York City levels and all six NYC Streetlife levels.

The attempt count is a design target. It is not a measured human success rate. Automated routes establish that the real controller can finish with hazards running; they do not establish how quickly an unfamiliar player learns the route.

## Design contract

Use the existing continuous movement, traffic, patrol and skateboard systems. Make crossing position, route choice and commitment matter. Preserve safe starts and places to observe the next hazard. Keep the six district identities in each set, their level paths and campaign indices, and the common retry and save behavior. Other campaigns retain their layouts and unlock rules.

New York City's detailed decisions and traversal evidence are in [NYC_DIFFICULTY_DESIGN.md](NYC_DIFFICULTY_DESIGN.md). Streetlife's are in [STREETLIFE_DIFFICULTY_DESIGN.md](STREETLIFE_DIFFICULTY_DESIGN.md).

Levelwright supplied the spatial-design workflow. The implementation uses measurements from this project's controller and collision system. It does not attribute the resulting layouts to an external designer.

## Human calibration

Start each city level without reading its test route. Count attempts through the first clear and note the cause of each failure. Distinguish learning a route from learning a timing window. A repeated failure should reveal a useful next action.

If a level falls well below the requested roughly 15 attempts, identify the safe bypass or encounter that failed to demand a decision. If it approaches the user's 50-attempt ceiling, inspect visibility, waiting positions and crossing windows before increasing recovery costs. The count alone is insufficient: deaths from hidden hazards or an unreadable camera need correction even when the total happens to match the target.

Physical mobile-device handling and first-time human difficulty remain open until played on those devices by a person.

## Verification

The two route suites completed all twelve levels from three departure phases, for 36 full traversals and 144 passing checks. The existing Brooklyn contact suite passed 25 checks. The shared-game suite passed 80 checks, including all 33 campaign loads, city progression reload and editor-library preservation. The integration suite passed 75 checks. There were no recorded engine warnings or errors in those successful runs.

```sh
bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/nyc_difficulty_routes.gd
XDG_DATA_HOME=/tmp/hopan-streetlife-qa bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/streetlife_difficulty_routes.gd
bash tools/godot.sh --headless --script res://tests/skater_contacts.gd
XDG_DATA_HOME=/tmp/hopan-city-profile-qa bash tools/godot.sh --headless --script res://tests/one_game.gd
bash tools/test.sh
```

The twelve level names, dimensions, starts, exits and campaign indices match the preceding unified-game source. The other 21 campaign layouts are unchanged. Browser evidence is collected in [nyc-difficulty-evidence](nyc-difficulty-evidence/).

The exported browser build passed 41 checks with no captured browser or engine errors. All twelve selectable layouts match their source tiles and objects. The checks cover paused overhead maps, ordinary movement, wall contact, failure and retry, saved city/Baby progression and outfits, touch joystick/map input in both sets, and normal release startup without the debug probe. Seven screenshots record actual desktop and mobile-emulated rendering. The first harness run read a menu diagnostic before it refreshed; a bounded wait fixed the harness, and the complete rerun passed.

```sh
NODE_PATH=/opt/codex/cua_node/lib/node_modules node tools/nyc_difficulty_browser.cjs
```

The script expects the debug web export at `http://127.0.0.1:8115/` and normal release at `http://127.0.0.1:8116/`. It uses Chromium with software rendering. Full-route completion was tested natively; browser checks do not claim full-route human completion, physical mobile performance or an achieved fifteen-attempt difficulty.
