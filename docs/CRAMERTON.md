# Cramerton — the completed Test1 Bonus map

Play **Bonus → + → Play · Cramerton**. It is available immediately, including on
profiles that have not unlocked the Tile Hop campaign. It is appended after
Shelby and Your Move Garden, preserving their existing completion indices.

## Author's layout and design

The re-uploaded Test1.json is now readable. The unchanged 21,849-byte source is
retained at [level-source/cramerton/Test1.json](../level-source/cramerton/Test1.json).
Its SHA-256 is `ec86e69e8cac53f09ef602cf28ed212d9f111556282a99ec2036dae967e4b521`.
Library's native readable copy is `libfile_ed562615b7b88191b86fd284456583e8`.
The former retrieval blocker is resolved; the older Your Move Garden demo was
never Cramerton and has not been replaced.

Levelwright's level-design workflow was applied to the actual supplied map.
The purpose is to extend the author's canal and fragment logic into a substantial,
turning city route. Acceptance requires preservation of that opening, real
resource-aware playthroughs, one late checkpoint, and immediate Bonus access.

All 169 cells of the lower-left 13×13 opening, every original non-floor cell,
all 11 original object dictionaries, the 33×49 dimensions, spawn, exit, theme
and fragment rules are retained. A deterministic generator asserts these
contracts and writes a [preservation record](../level-source/cramerton/preservation.json).
The bundled derivative removes only the editor autosave ID so it cannot reuse
the author's local editor slot. The original file retains that ID unchanged.

The opening now leads through five additional districts:

- **Customs Yard:** gather across a reversing north/south patrol road, then
  spend the earned long hop on the canal. Corners provide safe observation.
- **Switcher Canal:** collect along a bank, hop north, then turn west past a
  spike-ball rail instead of continuing along an empty straight corridor.
- **Needle Arcade:** weave around a divider while a west-facing dart shooter
  fires through its cheese. The lower bank permits waiting before crossing.
- **Cramerton Square:** one late checkpoint, a fountain and another earned
  canal crossing. Restarts restore the checkpoint's fragment snapshot.
- **Governor's Walk:** a dogleg street tests the last reserve against traffic,
  then bends toward the original exit.

There are 21 fragment pickups, seven earned long hops in the verified route,
51 total objects, six district signs, and exactly one checkpoint at `[8,16]`.
The original spike balls, short road and car are unchanged. No movement rules,
collision tolerances, hop timing, hazard behavior, saves or other maps changed.

## Verification

`python3 tools/build_cramerton.py` deterministically reproduces the map and
preservation proof. `python3 tools/plan_cramerton_route.py` reproduces a legal
153-hop witness, including seven long hops and verified safe-bank pauses.
That planner handles fragment consumption and pickup capacity; it is not used
as a substitute for testing moving hazards.

`XDG_DATA_HOME=/tmp/hopan-cramerton-check bash tools/godot.sh --headless
--fixed-fps 60 --script res://tests/cramerton.gd` passes 14 focused checks.
The actual movement requests advance real physics, collisions, cars, darts and
spike balls. There are no teleports, hazard edits, invincibility or state rewinds.
Both the full route and the checkpoint retry reach the exit. Tests also check
schema, Bonus ordering/access, existing editor saves and prior Bonus progress.
The fixture's pauses demonstrate viable crossings, not required player timings.

Browser checks exercise the real expanded Bonus picker and start Cramerton
through desktop mouse and landscape phone touch input. The exported terrain
and all object dictionaries must match the tested JSON exactly. Screenshots,
native output and browser results are in [previews/cramerton](previews/cramerton/).
Chromium emulation does not establish physical iPhone/Safari or Edge behavior.
Human playtesting is still needed to judge pacing and difficulty; the tests
establish legal movement, resource sufficiency and survivable crossings.

Build command: `bash tools/build.sh --with-browser-test` (Godot 4.7.2). Windows
is exported but not executed here. Shared-site publication must preserve every
current RiverSim file, the hosting adapter and unrelated assets byte-for-byte.
