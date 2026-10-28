# One Hopán game, Baby Mode first

The previous release joined two compiled games through links and an iframe. That did not meet the requested level organization. This release uses one executable, world, editor and profile.

The frog screen starts with **Play Baby Mode**, then **Levels**. The catalogue lists Baby Mode first, followed by Not as Hard as It Looks, Bonus, Tile Hop, Moves When You Move, New York City and NYC Streetlife. All 33 campaign levels are bundled. Existing unlock requirements remain visible. The plus button chooses an individual stage.

## Source reconciliation

The full outfit/editor/campaign branch is the base, with NYC and Streetlife's authored JSON, procedural city kit, roaches, skaters, lane traffic, validation and editor controls brought into that application. The original Baby and earlier campaign JSON files are unchanged. NYC uses the same equipped frog, completion handling and profile as the other sets. The NYC campaign entries remain separately selectable, without loading a second application.

Saved custom levels from both previous editors enter the same library. Existing browser mirror keys and disk files remain readable. An ID collision with different map content keeps both versions under separate IDs; repeated import does not create duplicates. Existing backups are not deleted. City completion fields are added to the existing profile rather than replacing Baby progress, outfits or rules.

The deployed package replaces the former second executable. Old `/classic/` links redirect to the one game. RiverSim and hosting settings are preserved.

## Verification

Run from the repository root with Godot 4.7.2 and matching templates:

```sh
bash tools/test.sh
XDG_DATA_HOME=$(mktemp -d /tmp/hopan-one.XXXXXX) bash tools/godot.sh --headless --script res://tests/one_game.gd
bash tools/godot.sh --headless --script res://tests/skater_contacts.gd
```

The integration suite has 75 passing checks. Two stale navigation assertions now handle the real unsaved-work prompt, and the preview assertion uses the existing camera offset of -2.0. The consolidation suite has 80 passing checks covering all 33 levels, city motion, profile round trip, conflicting save IDs and the shared editor. The skater contact suite has 25 passing checks.

`tools/one_game_browser.cjs` tests the real debug and release WebGL exports served on ports 8111 and 8112. It checks desktop and emulated mobile menus, Baby start, one page without frames, city and tile entry, saved outfit continuity, both old editor libraries, saving and immediate reload. Screenshots and the exact browser result are in `docs/one-game-evidence/`.

These checks do not constitute a complete human traversal of every campaign or a physical mobile-device test. Chromium uses software rendering here. No FPS claim is made.
