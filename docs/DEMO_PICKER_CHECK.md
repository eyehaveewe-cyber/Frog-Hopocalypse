# Movement demo picker check

The Tile Hop suite's old demo-picker assertion expected an unsaved playtest map to be replaced immediately. The later documented editor safeguard correctly asks **Save before leaving?** before running the pending demo selection. This was an outdated test expectation, not a game-code defect.

The native test now verifies that the current map remains intact while the choice is open, that **No · Leave without saving** is available, and that choosing it loads Big Hop Boulevard in ordinary Tile Hop mode. `XDG_DATA_HOME=/tmp/hopan-demo-picker-check bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/tile_mode.gd` passes **57 checks, zero failures**.

`tools/browser_demo_picker.cjs` uses actual Chromium clicks from the editor through the choice and confirmed demo load. [The real editor prompt](previews/demo-picker-unsaved.png) was inspected. This is Chromium evidence, not Safari or a physical phone test. No runtime code, saves or level assets changed.
