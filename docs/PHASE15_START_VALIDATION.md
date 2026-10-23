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
