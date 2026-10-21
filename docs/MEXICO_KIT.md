# Mexico courtyard starter kit

This repository-only pass implements the Mexico theme-pack item from the
human-authored original [design brief](game-design-brief.md#7-world-art-and-theming).
That brief requests colorful courtyards, walls, plazas and cactus gardens in a
subsequent release. This is a reusable starter kit, not a new campaign or a
claim that the complete theme roadmap is finished. The proposed editor v0.2
was not used as an adopted requirement. No consultant review was requested.

From the main menu choose **Level editor → New Mexico**. The theme dropdown
also changes an existing map; Undo/Redo restore both the map and picker.
**Scenery demos → Courtyard Gardens · Mexico → Playtest** opens a calm, editable
17 × 13 showcase with a central water court, two paved outer approaches and
cactus beds. It is an asset showcase, not the blocked Test1/Cramerton expansion.

The modular kit contains original terracotta floors, pale plaza paving,
teal-trimmed stucco walls, painted columns, flower pots and five deterministic
cactus silhouettes. Walls use the existing filtered mipmapped rendering path;
there are no fine dark mortar lines in stucco. Geometry uses shared cached
meshes/materials and existing static batching. There are no added animations,
runtime downloads or third-party assets.

The palette's **Cactus / Painted column / Flower pot** names correspond to the
existing tree / pillar / decoration object types. Existing collider sizes,
solid toggles and tile-mode rules apply. Cactus arms are visual canopy; the
trunk collider retains the tree's narrow footprint. Trees/cacti remain excluded
from the coarse exit-path test, so an actual playtest is still required.
Other objects remain available and use the shared asset library.

Mexico levels use portable version-1 JSON with `theme: "mexico"`. Existing
Egypt/Swamp maps retain their data and appearance. An older build that only
accepts Egypt/Swamp will reject a Mexico map; keep exports when switching builds.
New Mexico maps retain the existing new-map recovery/autosave identity. Imported
or showcase maps still require a manual save, as in the current editor.

## Evidence

- 28 focused native checks pass: actual continuous-controller route to the exit,
  physical wall collision, untouched return-to-editor document, local save/load,
  portable JSON, theme switching with Undo/Redo, palette names, recovery identity
  and legacy theme acceptance.
- The existing 26-check editor-leave/road-fragment regression passes.
- Browser checks pass in retro and compatibility modes using actual editor
  controls, save, showcase loading, keyboard movement and overhead-map controls;
  no console/page errors were reported. [Results](previews/mexico-kit/results.json).
- Pinned Godot 4.7.2 Web release, Windows release and Web debug exports build.
  Windows was exported, not executed. Physical phones/Safari, performance on
  hardware and subjective comfort are unverified.

Run native checks with an isolated save directory:

```sh
XDG_DATA_HOME=/tmp/hopan-mexico-check bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/mexico_kit.gd
bash tools/build.sh --with-browser-test
python3 -m http.server 8068 --directory build --bind 127.0.0.1
# In another terminal, using the local Playwright/Chromium installation:
node tools/mexico_kit_smoke.cjs
```

[Perspective preview](previews/mexico-kit/play.png) ·
[Editor preview](previews/mexico-kit/editor.png) ·
[Compatibility preview](previews/mexico-kit/compat-play.png) ·
[Native evidence](previews/mexico-kit/native.log) ·
[Playable standalone Web ZIP](../artifacts/hopan-mexico-kit-web.zip).

The standalone ZIP must be served as an entire folder over HTTP. It contains
the frog game only, and must not replace the entire existing Site export because
it does not contain RiverSim. See the ZIP's PLAY.txt and SOURCE.json.

No Site publication or main merge occurred. The existing public Site stays at
v28. All bundled campaign layouts, sound/rules, Site adapters and RiverSim stay
unchanged. Rollback for this isolated branch is its starting commit
`0c8849a268188afa639d68f37e6fdad05b038bfc`.
Test1/Cramerton is still blocked by the attachment host's CONNECT 403; its
layout has not been guessed and that failed transfer was not retried this pass.
