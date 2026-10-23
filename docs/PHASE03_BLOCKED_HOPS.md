# Phase 03: blocked Tile Hop feedback

The 80-phase guide's Phase 03, **Tune tile-mode movement**, asks that blocked moves be readable. The current Tile Hop controller already recorded a reason for a blocked wall/landing or unavailable long hop, but never showed that reason. Keyboard and touch attempts appeared to do nothing.

This bounded pass sends the existing reason to the game's status line when a hop is rejected and clears the stored reason after a legal hop. It changes no path, input permission, resource cost, animation or hazard beat. The first visible case is [a blocked wall hop in the actual Chromium playtest](previews/phase03-blocked-hop.png). The message is also available for unavailable long hops. Future Phase 03 work may still improve advance move prediction and facing readability; this pass does not claim the entire phase complete.

The native regression failed before the change because status stayed silent. It now confirms the message, no consumed hop/linked hazard beat, and a subsequent accepted hop:

```sh
XDG_DATA_HOME=/tmp/hopan-phase03-check bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/blocked_hop_feedback.gd
```

For actual Chromium input, export the debug Web build, serve `build/test-web` on localhost:8064, then run `HOPAN_TEST_URL=http://127.0.0.1:8064 node tools/browser_blocked_hop.cjs`. It imports a tiny map through the file picker, presses an arrow into a wall, checks unchanged hop and movement-linked beat counts, then moves into an open cell. This is Chromium browser evidence, not Safari or physical phone testing. Existing Tile Hop rules and Moves When You Move suites passed 38 and 61 checks. The broader `tile_mode.gd` suite stops at its editor demo picker and subsequent empty-map access on both this branch and unmodified source; that pre-existing test failure is unrelated to this feedback change.
