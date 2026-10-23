# Phase 69: v47 profile compatibility check

The 80-phase guide's Phase 69 asks that a prior save retain completion and hats across a content update. This focused check uses the pre-Moves When You Move source commit `0e6f93f` (v47) as the historical format and the current source after `ed743c0` as the reader.

The v47 `save_profile()` stores completed stage **indices** in `baby_mode`, `not_as_hard`, `bonus` and `tile_hop`, plus the equipped hat, skin and most recently cleared stages. Comparing the v47 and current `main.gd` constants shows those four level arrays have the same paths and order; the new `sync` collection is appended separately. No ID migration is needed for this representative update.

`game/tests/prior_profile.gd` writes a v47-shaped `user://profile.cfg`, starts the actual current Godot scene, and checks four Baby Mode clears, two Not as Hard clears, three Bonus clears, one Tile Hop clear, replay positions, the earned and equipped baby hat, and the purple skin. It then saves and reloads with the current code and checks that progress again. The new Moves When You Move set starts empty as expected.

Run with isolated storage:

```sh
XDG_DATA_HOME=/tmp/hopan-phase69-profile bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/prior_profile.gd
```

Result: **PASS**. This is a native Godot profile test, not a Chromium, Safari, or physical-device test. It covers one v47 save shape and the current content order; it does not prove compatibility for every older save or asynchronous browser storage state. No source change was warranted by this result.
