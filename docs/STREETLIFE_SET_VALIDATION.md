# NYC Streetlife set validation

The six-map set uses the ordinary campaign loader, level editor and JSON format.
`game/tests/streetlife_set_integration.gd` checks each map's set identity and
round trip, walks its real static collision route, then attempts a full ordinary-
input playthrough with every authored hazard active. The driver predicts only
nearby movement windows and waits while the world continues to simulate. It
commits across complete road bands rather than waiting between opposing lanes.
No route teleport, disabled enemy, paused hazard or result assignment supplies
live completion.

The suite separately exercises genuine victory handling and the actual next-
level buttons. It checks that the sixth level ends the set and that the previous
campaign does not silently spill into this one. Direct result triggering is used
only for these menu contract checks, never as live route evidence.

`tools/streetlife_set_browser.cjs` uses real scrolling and input against the
opt-in read-only debug probe. It launches the set, opens all six maps, checks
pause and map inspection, exports the finale and starts it in an 844 x 390
landscape phone viewport. Gameplay and overhead captures are written to
`build/test-results/streetlife-set/`.

The finalized native set suite passed **52 checks with zero failures**. The
complete project integration suite passed **217 checks with zero failures**.
Every set map was physically walked through its real solid collision, and each
also reached `LEVEL COMPLETE!` with all authored traffic, riders and roaches
active. The standalone set log is `/tmp/streetlife-set-native-final.log`; the
combined run is `/tmp/streetlife-set-full-final.log`.

| Level | Simulated completion | Time waiting for a clear interval | Traffic bands crossed |
| --- | --- | --- | --- |
| Stoop Patrol | 14.73 s | 4.58 s | 0 |
| Newsstand Weave | 9.25 s | 0.00 s | 0 |
| Ferry Railwalk | 13.58 s | 0.00 s | 0 |
| Banked Boulevard | 15.80 s | 3.08 s | 1 |
| Sanitation Courts | 23.77 s | 0.00 s | 0 |
| Block Party | 11.00 s | 0.00 s | 2 |

These are informed automated routes, not target times or a difficulty ranking.
A zero wait can result from favorable arrival phase and route choice. The
runner commits beyond complete roach patrol rows before stopping, so a wait
never intentionally parks the frog in the approaching patrol's path.

The native suite also pressed each actual next-level action and the final
replay action. Levels advance in set order, the sixth offers completion and
replay, and completing the prior campaign does not start this separate set.

The finalized browser sequence passed **20 checks with zero failures** and no
JavaScript or Godot runtime errors. It exercised direct set start, all six level
selection entries, complete pause and overhead-map freezes, an actual retry clock
reset, finale JSON export and the landscape phone encounter. The final log is
`/tmp/streetlife-set-browser-final.log` and the machine-readable map roster is
`build/test-results/streetlife-set/browser-summary.json`.

All six gameplay and overhead captures were refreshed after the orbital level-2
revision and the level-4 return-path correction. The final level's 844 x 390
phone capture was also refreshed. The inspected views show distinct layouts,
readable ground paths, new street props and moving enemies at the actual game
camera. These images are available to the independent set reviewer in
`build/test-results/streetlife-set/`.

Static route connectivity, automated live completion and human playtesting are
distinct claims. Real Safari/iPhone and Windows execution require those platforms.

The final menu keeps both `Start NYC Streetlife · 6 levels` and the level editor
action above the long individual-level selector. After this menu adjustment,
the complete six-level browser runner passed all 20 checks again, and the
original gameplay/editor browser regression passed all 16 checks. Both logs
reported no JavaScript or Godot runtime errors. Final browser logs are
`/tmp/streetlife-set-browser-final.log` and
`/tmp/streetlife-set-original-browser-final.log`.

Web release, Windows x86-64 release and debug Web exports completed without
Godot errors. A direct packed-data comparison confirmed that all six debug Web
level JSON payloads match the final authored files byte-for-byte.
