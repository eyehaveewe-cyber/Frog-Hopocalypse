# NYC validation

The NYC checks extend the existing native integration runner and add a browser
runner at `tools/nyc_browser_smoke.cjs`. Run the complete native suite with
`bash tools/test.sh`. Build debug Web with `bash tools/build.sh --with-browser-test`,
serve `build/test-web` on port 8060, then run the original browser smoke suite and
`node tools/nyc_browser_smoke.cjs`.

The native NYC checks cover campaign registration, traffic JSON round trips,
invalid imported lanes, opposing movement, mixed traffic, pause/map/editor
freezing, deterministic retry, actual vehicle death, relative swept collision,
wrap seam collision and a real frog crossing a lane with traffic active. The
existing runner also physically walks each bundled map's dry route with hazards
paused. A separate live-route runner, `game/tests/nyc_routes.gd`, uses ordinary
frog movement and waits for clear gaps while traffic and critter AI remain active
for the full route in every NYC map. These checks establish feasible traversal;
they do not establish human difficulty or enjoyment.

The browser checks use actual menu scrolling, mouse and keyboard events against
the debug build. They check the fifth NYC level's moving traffic, pause and map
inspection, retry, editor preservation, portable JSON export and a landscape
phone viewport. Screenshots and exported JSON go in ignored `build/test-results`.
The diagnostic bridge is read-only and opt-in in debug builds.

Native execution passed with Godot 4.7.2 on the cloud Linux runtime. The combined
suite completed **105 checks with zero failures**, including **38 NYC integration
checks** and **15 live-route checks**.
The full dry route in every one of the eight bundled maps was physically walked
with the real frog controller and static collision. The dedicated road fixture
also crossed a live lane successfully with vehicles and impact detection active.
All five NYC maps reached `LEVEL COMPLETE!` with traffic and AI active. Simulated
completion times ranged from 8.43 to 22.05 seconds for the automated driver, with
up to 3.03 seconds spent waiting for gaps. These are automation observations,
not first-time player completion targets. The final native log is
`/tmp/nyc-final-native.log`.

Every simulated vehicle has all four named mechanical wheel pivots. A measured
0.100-second traffic step rotated the first taxi's front-left wheel from
0.000000 to -1.310345 radians. The check inspects the real pivot before and after
movement rather than inferring rotation from the procedural source.

The NYC browser sequence passed **11 checks with zero failures** in Chromium with
software WebGL rendering and Playwright 1.62.1. It executed both a 1280 × 800
desktop viewport and an 844 × 390 landscape phone viewport. The sequence reported
no JavaScript or Godot runtime errors. The execution log is
`/tmp/nyc-agent-browser-final.log`.

Desktop gameplay, overhead inspection and landscape phone screenshots were
visually inspected. The four vehicle silhouettes remain distinct at the game's
low resolution, and crosswalks, medians and the frog are readable. The first
inspection exposed traffic approach vehicles driving over the water backdrop.
The revised build adds asphalt approaches and covered ramp/tunnel entries.
Updated desktop gameplay, overhead and landscape phone screenshots were inspected
after the final browser run. The approaches now carry the vehicles into covered
entries, resolving that visual defect. No remaining visual blocker was observed
in those views.
Real iPhone/Safari, Windows execution and human difficulty testing remain separate
platform and playtest checks.

The original browser regression suite also passed all 16 checks after the NYC
menu/theme additions. Web release, Windows x86-64 release and debug Web exports
completed without Godot errors. Vehicle inspection rendered front, side and
three-quarter views for all four types with `node tools/capture_nyc_gallery.cjs`.
The independent review found coplanar truck panels; widening the cargo shell
to 1.10 units removed the flicker, verified by three fresh truck captures.
The final render evidence and editable stage ledger are in `docs/assets/nyc/`.
