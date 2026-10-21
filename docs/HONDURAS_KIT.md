# Honduras jungle-river starter kit

This is one bounded implementation pass on the human-authored theme-pack
roadmap in the [original design brief](game-design-brief.md#7-world-art-and-theming),
continuing the pushed Mexico kit at `4f8162c85632eacb737acbcc7ea233df762fec6f`.
It does not adopt the proposed editor v0.2, alter campaign difficulty or bypass
human playtesting decisions. There is no reset-triggered update loop.

## Problem, intended improvement and acceptance

Authors could build river layouts but could not give them the planned Honduras
jungle identity: the available kits offered palms/violet foliage or courtyard
cacti. This pass adds reusable broadleaf vegetation, vine-covered masonry and
jungle ground, visible in the actual editor and perspective game, together with
a river showcase using the established moving-log mechanic.

Acceptance was set before implementation: the kit must look distinct in both
views; normal save/load, portable JSON and Undo/Redo must preserve it; existing
collider and moving-platform behavior must remain intact; and the real frog
must cross a moving log and reach the exit. Existing maps and saves must remain
usable. Automated completion does not establish novice fairness or enjoyment.

## Asset production decisions

Screenwright's asset-production skill guided this implementation. The actual
Mexico game/editor preview, procedural art source, theme loader and 1.8-unit
tile size were inspected before choosing the new assets. The following are
project-specific design choices, not universal standards or measured human
preferences:

| Family | Implementation and purpose |
| --- | --- |
| Ground and path | Broad green/earth clusters contrast with light stone paths, making the two river banks readable. |
| Walls and columns | Vine clusters on muted stone; simple stepped columns supply a different silhouette from Egypt and Mexico. Wall textures keep the existing filtered mipmapped path. |
| Trees | Five deterministic height/rotation/texture variants with clustered broadleaf crowns. Approximately 1.5-unit crown width stays inside a 1.8-unit tile; tree collision retains its narrow trunk footprint. |
| Decoration | Fern pots reuse the existing non-blocking decoration default and optional Solid property. |
| River | Existing water/log visuals and simulation are reused; no movement or hazard timing changes. |

All geometry and textures are original procedural assets, retained as editable
GDScript. The stepped forms are stylized modular scenery, not reconstructions
of Copán monuments or copies of cultural carvings. This is a starter kit;
historically researched landmarks and a full themed campaign are not claimed.
No downloaded art, transparent foliage, extra animation or new shader features
were added. Shared mesh/material caches and static batching remain in use;
physical-device performance has not been measured.

## Try it

Choose **Level editor → New Honduras**, or change an existing map with
**Honduras · Jungle river** in the theme picker. **Jungle tree / Stepped column /
Fern pot** use the existing tree / pillar / decoration object types and their
collision/selection/rotation rules.

Open **Scenery demos → Jungle River · Honduras → Playtest** for the editable
17 × 13 sample. Follow the paved lower bank to the center, ride the slow log
over the river, then continue along the upper bank toward the exit. The sample
introduces no campaign slot, unlock, reward or checkpoint. Returning to the
editor keeps the authored log position and layout.

Honduras maps use version-1 JSON with `theme: "honduras"`. Save/duplicate/export,
theme switching and new-map recovery identity use the existing editor systems.
Old Egypt/Swamp/Mexico saves remain valid. Earlier readers that lack the new
theme ID will reject Honduras documents; retain portable exports when changing
builds. Tree canopy is visual, and the coarse exit-path check still ignores tree
trunks; run a real playtest to check clearance.

## Verification and preview

- 26 focused native checks pass, including actual continuous-controller travel
  over the moving log with water hazards/carrying/collisions active, exit victory,
  wall blocking, untouched return to editor, save/load, JSON and theme Undo/Redo.
- All 28 existing Mexico kit checks pass on the same source, covering its full
  controller route and save behavior as well as old Egypt/Swamp acceptance.
- Web release, Windows release and debug Web export build with pinned Godot
  4.7.2. Windows was exported, not executed.
- The standalone release reaches its first rendered frame without reported
  console/page errors; its debug probe is absent. [Release evidence](previews/honduras-kit/release-results.json).
- [Browser results](previews/honduras-kit/results.json) cover actual editor
  controls, save, showcase loading, keyboard movement and overhead view in retro
  and compatibility rendering. These are Chromium/SwiftShader checks.

[Perspective](previews/honduras-kit/play.png) ·
[Editor](previews/honduras-kit/editor.png) ·
[Compatibility](previews/honduras-kit/compat-play.png) ·
[Native evidence](previews/honduras-kit/native.log) ·
[Playable Web ZIP](../artifacts/hopan-honduras-kit-web.zip).

The 10,731,251-byte ZIP contains the entire standalone Web folder, built from
`d9abac7d232fb978acb9b26e7ab657fd06b6aa38`. All archived export files match the
build exactly, and CRC checks pass. [Manifest and SHA-256](../artifacts/hopan-honduras-kit-web.json).
Serve the unpacked folder over HTTP as described in PLAY.txt; opening the HTML
as a file cannot load WASM. The ZIP includes the Mexico kit but excludes RiverSim
and Site hosting adapters, so it must not replace the entire Site directory.

Reproduce with an isolated save directory:

```sh
XDG_DATA_HOME=/tmp/hopan-jungle-check bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/honduras_kit.gd
bash tools/build.sh --with-browser-test
python3 -m http.server 8068 --directory build --bind 127.0.0.1
# In another terminal with local Playwright/Chromium:
HOPAN_THEME=honduras node tools/mexico_kit_smoke.cjs
```

Physical phones/Safari, hardware performance, subjective visual comfort and
first-time human navigation remain unverified. This pass adds authoring assets
and a testable sample; no human-playtest gate has been treated as resolved.

No merge or deployment occurred. The public Site remains v28. RiverSim, hosting
adapters, campaign layouts, audio and movement rules are untouched. The branch
starts from `4f8162c85632eacb737acbcc7ea233df762fec6f`; returning to that commit
removes this pass while retaining the Mexico kit. Test1/Cramerton remains blocked
by its attachment-host CONNECT 403; no attachment retry or guessed layout was used.
