# Phase 15: unsafe frog start

The 80-phase guide's Phase 15, **Make map validation useful**, calls for unsafe starts to produce actionable feedback while preserving the current edit. This pass covers one missing case: the editor allowed Road to be painted under the frog start, and `Data.validate()` accepted that map. A road can carry cars through the spawn cell.

Normal save, import and playtest validation now reports: “The frog start is on a road. Paint a safe floor or path there, or move the start off the road.” Failed save keeps the editor document. Editor recovery snapshots still accept unfinished drafts. Existing levels, traffic rules and editor tools are unchanged.

Reproduce with an isolated save library after `python3 tools/bootstrap.py` and `bash tools/godot.sh --headless --editor --import --quit`:

```sh
XDG_DATA_HOME=/tmp/hopan-phase15-check bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/start_validation.gd
```

Before the validation change, this test failed at its actionable-error assertion because `Data.validate()` returned an empty string. Afterward it passes the native Godot editor/save checks, including retained terrain and a corrected map. A debug Web export served on localhost:8060 also passed `node tools/phase15_browser.cjs` in Chromium: actual mouse input painted Road, Save displayed the message, the edit remained, and no save was created. [Editor screenshot](previews/phase15-unsafe-start.png). This is Chromium evidence, not Safari or a physical phone test.

The existing `bash tools/test.sh` suite reported 75 checks and three failures on both this branch and the unmodified v48 source: “Standard editor size remains available,” “Large maze survives export/import through the shared serializer,” and “Exit sweep returns to the frog before releasing play.” They are outside this bounded validation change.

## Follow-up: missing exit field

The same Phase 15 item names missing start/exit. Source review found both were rejected, but a JSON map with no `exit` field incorrectly reported that its exit “must be inside the level.” The validator now distinguishes an absent exit and tells the author to add an exit coordinate on a walkable tile to the JSON, then import again. Out-of-bounds exits keep their existing message. Object IDs and patrol references already have validation; this pass changes neither.

Reproduce with `XDG_DATA_HOME=/tmp/hopan-phase15-exit bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/missing_exit_feedback.gd`. Before the change, its actionable-message assertion failed with “The exit must be inside the level.” Afterward the native check passes, including rejection without replacing the current edited level and acceptance after adding an exit. The focused `tools/phase15_browser.cjs` check now imports a missing-exit JSON file through Chromium's real file picker and verifies the message and retained editor map. [Actual editor import screenshot](previews/phase15-missing-exit.png). These are native Godot and Chromium checks; no Safari or physical phone claim is made.

## Follow-up: impossible fragment requirement

Phase 15 also calls for impossible resource requirements to be caught. A Tile Hop map with a water gap requiring a long hop, the **three fragments** rule, and fewer than three fragments previously passed validation. It could be imported and started, but could not earn the hop needed to cross. A focused native test reproduced this before the fix: `Data.validate()` returned no error.

Validation now compares structural reachability with and without long hops. It raises a hard error only when a long-hop route exists, no short-hop route exists, and fewer than three fragments are placed. The message tells the author to place at least three fragments or open a short-hop route. A map with a short-hop route remains valid with no fragments; a structurally reachable map with three fragments also remains valid. This check does not claim that three fragments are reachable in the right order or that moving hazards are beatable. Such uncertain cases need playtesting rather than a hard rejection. Autosave snapshots continue to hold unfinished drafts.

Run `XDG_DATA_HOME=/tmp/hopan-phase15-fragments bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/impossible_fragments.gd`. The native check passes import rejection, actionable feedback, preservation of the current edit, and both valid alternatives. `tools/phase15_browser.cjs` also passed an actual Chromium file-picker import and captured the [editor feedback](previews/phase15-impossible-fragments.png). Existing `tile_tour_rules.gd` passed 38 checks and `your_move_set.gd` passed 61 checks. Chromium is not Safari or a physical device.

## Follow-up: invalid seam placement reference

Phase 15 also calls for invalid references to be caught. A seam worm's optional `seam_anchor` names its editor placement tile. Before this fix, an imported worm at corner `[5.5, 5.5]` could reference distant tile `[10, 10]`: the coordinates were individually valid, so import replaced the current map, but the editor selected and rotated the worm around the wrong tile. Validation now requires a provided placement tile to touch the worm's corner. The error says to move that tile beside the worm or remove the field. Older worms without `seam_anchor` remain valid and use the existing position-based fallback; correctly rotated worms retain their saved anchor.

Reproduce with `XDG_DATA_HOME=/tmp/hopan-phase15-anchor bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/seam_anchor_import.gd`. Before the fix, the test failed because validation returned no error. Afterward it passes rejection, current-edit preservation and valid/legacy cases. The existing seam-rotation suite passes 17 checks. The focused browser runner also passed a real Chromium file-picker import and captured the [editor error](previews/phase15-seam-anchor.png). This is Chromium evidence, not Safari or physical iPhone evidence.
