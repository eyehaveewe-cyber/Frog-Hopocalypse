# Phase 17: fragments before the first required gap

The 80-phase guide's Phase 17 says required pickups must be reachable before the first mandatory long gap. Previously, validation counted three fragments anywhere on a Tile Hop map. A map with all three across a water gap passed import even though its fragment rule starts with no long hop, making the exit unreachable.

For fragment-rule maps whose exit has a structural long-hop route but no short-hop route, validation now counts fragments reachable from the start by **short hops alone**. It requires three before accepting the map. The error tells the author to move fragments onto the starting side or open a short-hop route. The rule does not change movement, pickups, map format, editor recovery snapshots or older valid maps. This is a necessary first-gap check, not a complete solver for moving hazards, later gaps or pickup order.

The native regression failed before the change because the inaccessible map validated. It now checks rejection without replacing the current edit, a valid placement of three pre-gap fragments, and a valid short-hop alternative:

```sh
XDG_DATA_HOME=/tmp/hopan-phase17-check bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/first_gap_fragments.gd
```

`tools/browser_first_gap_fragments.cjs` imports the map through Chromium's real file picker, verifies the [editor error](previews/phase17-first-gap.png) and retained map, then imports a corrected map after the normal unsaved-change choice. The earlier Phase 15 fragment regression passed. Existing Moves When You Move (61 checks), Cramerton (14), Tile Hop rules (38) and five harder replay routes passed. The browser evidence is Chromium, not Safari or a physical phone. No Site or RiverSim content was changed.
