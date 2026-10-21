# Lane entrances and exits — guide phase 07

This single substantive pass continues `fb52f0bdea60db1e6c345cc44219009634c5f510`,
preserving both Mexico and Honduras kits. It follows the actual
[Pharoah Frog Hopan 80-Phase Implementation Guide](https://chatgpt.com/api/library/files/libfile_20ce1be11938819192b93ed1d52dca49/download),
version 1, read in full (12 pages) for this pass.

## Selection and acceptance, established before implementation

The guide's human register H07 explicitly requests lane tunnels. Phase 07
proposes entrance/exit structures outside useful reaction space. The ordering
of the eighty phases is AI-origin planning, not an adopted automatic queue.
Font selection, inversion semantics, physics contracts and human difficulty
judgments remain open; this pass makes no decision on those gates.

**Player problem:** cars and logs wrap between lane ends in open space without
an entrance or exit structure. **Noticeable improvement:** theme-matched portal
mouths and covered approaches give that motion a visible setting, using existing
levels rather than adding quota maps.

Acceptance: all portal art remains outside the playable interior; the cover
includes the longest mover's wrap seam; existing car/log speeds, collision,
carrying, water deaths, safe spawn and authored map data remain unchanged;
normal and tile movement behave correctly; Mexico/Honduras remain usable.
Actual camera views and active routes must be checked. This is implementation
evidence, not a claim that human readability or comfort has been certified.

## Implementation

`lane_tunnels.gd` generates a pair for each **continuous full-width car/log lane**
with a wall at both map borders. Each pair starts at the outer edge of the first
and last interior cell, extending outward over the whole wrap seam. The longest
car/log determines cover depth. Shared rows get one pair, not one per mover.

The roof and side walls use Egyptian stone, Swamp stone, Mexico stucco or Honduras
vine-covered stone. Opening trim supplies depth without a black billboard or
back wall. Road decks and water at the wall cells visually join the lane to the
mouth. Those wall cells retain their **original collision and map data**; these
are entrances for lane objects, not a newly traversable map edge for the frog.

Tile cars/logs and patrol cars reverse at endpoints instead of wrapping, so they
retain visible endpoints and receive no misleading entrance tunnel. Partial
road/water rows and deliberately authored playable border cells are untouched.
This does not add new lane behavior or relocate any hazard.

Screenwright's asset-production workflow informed the visual-only scope and
camera checks. Original procedural box meshes/materials use existing caching
and static batching. No new shader, texture download, collision shape, save
field, pickup or UI control was added. The added tunnel state in the browser
probe is debug-only; release exports expose no probe.

Baby Mode's Little Frog Crossing gains eight lane pairs. The existing Honduras
Jungle River showcase gains its culvert pair. Open those maps normally to play;
the editor automatically shows the same scenery. No campaign layouts were edited.

## Checks and durable previews

- 16 focused native checks pass: all four kits, interior bounds of every mesh,
  no added collision, correct exclusions, shared-lane sizing, actual car/log
  wrapping, unchanged speed, editor/game boundary colliders and map preservation.
- 18 existing crossing/reward regression checks pass, including complete active
  traffic/log finale traversal at arrival phases 0, 100 and 220, log carrying,
  open-water death, lethal cars, checkpoint reset and saved hat progress.
- Five harder tile routes and five checkpoint retries complete with active
  hazards. The 26-check Honduras route/save regression also passes.
- Four browser theme checks pass without console/page errors: Egypt, Swamp and
  Mexico desktop retro, and Honduras Android-UA touch compatibility. Actual
  editor/play/map controls run; the overhead map pauses lane simulation.
- Pinned Godot 4.7.2 Web/Windows release and debug Web exports build. Windows
  was exported, not executed. Physical phones/Safari, human readability and
  physical-device performance remain unverified.

[Egypt play](previews/lane-tunnels/egypt-play.png) ·
[Swamp play](previews/lane-tunnels/swamp-play.png) ·
[Mexico play](previews/lane-tunnels/mexico-play.png) ·
[Honduras touch compatibility](previews/lane-tunnels/honduras-play.png) ·
[Browser results](previews/lane-tunnels/results.json) ·
[Native checks](previews/lane-tunnels/native.log) ·
[Crossing regression](previews/lane-tunnels/crossing-regression.log) ·
[Tile route regression](previews/lane-tunnels/tile-regression.log).

```sh
XDG_DATA_HOME=/tmp/hopan-tunnel-check bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/lane_tunnels.gd
XDG_DATA_HOME=/tmp/hopan-crossing-check bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/lane_crossing_regression.gd
bash tools/build.sh --with-browser-test
python3 -m http.server 8068 --directory build --bind 127.0.0.1
# In another terminal with local Playwright and Chromium:
node tools/lane_tunnels_smoke.cjs
```

## Shared Site safety

Existing URL: https://hopan.fiiendward.chatgpt.site. The official Sites source
helper opened the latest source before edits were considered. It advanced the
local checkout from v28 source `4a942e7365c3e6e1b3f7738683b22bbd28c9d128` to
`00c64e4822d60709b417e98e49fa8dcbc9d75c28`, containing RiverSim 0.4.0 changes in
`riversim/build.json`, `riversim/index.html` and `riversim/index.pck`.

Saved v29 has no deployment ID in the native version history; v28 has a confirmed
successful deployment. Live RiverSim byte inspection from this executor fails
with CONNECT 403. The user is handling RiverSim, so publishing this latest source
could inadvertently publish their pending work; reverting to the stale source
could erase it. A coordination question is pending. No Site files have been
staged or modified by this pass. All 16 protected RiverSim/adapter/header hashes
for both sources are recorded in the [shared-Site inspection](previews/lane-tunnels/shared-site-inspection.json).

The final Site check and outcome are recorded separately with the packaged
preview. Do not use the standalone frog export to overwrite the whole Site:
it excludes RiverSim. Cramerton remains blocked by unreadable Test1.json, whose
layout has not been guessed or retried. No PR merge or ongoing update loop occurs.
