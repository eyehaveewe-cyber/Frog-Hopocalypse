# NYC streetlife validation

The new native scene checks live in `game/tests/streetlife_integration.gd` and
are invoked by the full `bash tools/test.sh` runner. They exercise real model
hierarchies, scene movement, action transitions, elevated route data, frame-rate
invariance, swept contact, enemy deaths, retry, pause, the overhead map, editor
placement and JSON round trips.

`node tools/streetlife_browser_smoke.cjs` runs against the debug Web export on
port 8060. It uses real scrolling, mouse and keyboard input, with the opt-in
read-only diagnostic bridge. The checks inspect three rider variants, roaches,
city assets, movement and elevation, pause/map/editor freezes and portable JSON.
The run also starts a landscape phone viewport. Screenshots and exported maps
are written to ignored `build/test-results/`.

The complete native suite passed **147 checks with zero failures**, including
**39 streetlife checks**. The first run exposed two placement/route regressions;
shared solid-footprint routing and roach-aware patrol avoidance corrected them.
The final run is `/tmp/streetlife-final-native.log`.

A full ordinary-input plaza traversal reached `LEVEL COMPLETE!` with all three
skaters and all four roaches active. It took 11.17 simulated seconds, including
0.20 seconds waiting for a clear interval. The driver follows the physical grid
route, forecasts only the next short movement, waits while simulation continues,
and moves using the frog's normal input. It never teleports the frog or pauses
hazards. This proves an available live route, not a first-time human target time.

The streetlife browser sequence passed **12 checks with zero failures** in
Chromium with software WebGL rendering. It exercised 1280 x 800 desktop and
844 x 390 landscape phone viewports, and reported no JavaScript or Godot errors.
The log is `/tmp/streetlife-browser-final.log`.

Actual gameplay, overhead, editor and phone screenshots were inspected. The
rider silhouettes, articulated roaches and ramp/rail layout remain legible at
the intended low-resolution game rendering. The first inspection found a traffic-specific hint in the skating scene.
The final build now tells the player to watch rider loops and cross behind the
board; that corrected text was verified in the fresh gameplay capture.
The viewed screenshots are `build/test-results/nyc-skate-plaza-*.png`.
A successful scene/schema check does not establish visual animation quality or
human difficulty. Real iPhone/Safari, Windows execution and first-time human
playthroughs remain separate checks.

The measured support runner `bash tools/godot.sh --headless --script
res://tests/skater_contacts.gd` passed another 25 checks. It ran the real plaza
riders at 30, 60 and 120 Hz. Both grind riders' truck undersides contact the
rail with 0.000000-unit error at the corrected 0.605-unit origin height.
Planted sole/deck error remains 0.016500 units. The actual truck underside is
0.045 units above the origin; the earlier 0.08 estimate described its center.

The original browser suite passed all 16 checks, and the Midtown browser suite
passed all 11 checks after the streetlife additions. Together with the 12 new
streetlife checks, 39 browser checks passed. Final Web release, Windows release
and debug Web exports completed without Godot errors. Windows execution and
real iPhone/Safari behavior were not tested on those devices.

Visual review also corrected a floating roach wing seam and reauthored antenna
segments from shared endpoints. Updated roach and front-facing prop views were
inspected. The complete staged model evidence is in
`docs/assets/nyc_streetlife/asset.json`.
