> Historical v37 implementation: this native-grid redraw did not match the
> selected image closely enough and is superseded by the
> [exact-source correction](EXACT_SPLASH_CORRECTION.md).

# #6 Wrapped Gold, with occasional #4 Layered Cloth

User-approved direction: use #6 as the title-screen hat, and try a chance of
loading a slightly different #4 screen. This pass adapts those generated concept
shapes to the existing editable 384×216 / 216×384 code-art grid. It preserves the
original frog face, body and scenery rather than inserting the concept sheet's
different rendering of those features. All six exports differ from the original
only within the hat bounds, verified by pixel comparison.

#6 has a domed crown and continuous brow band; #4 has a lower fitted crown and
folded cloth sides. Side cloth now composites behind the raised eyes, stripes
are closed shapes contained inside the cloth silhouette, and crown highlights
and underside shadow are continuous. Separate cloth, frog and crown passes are
editable in the script, PNG layers and OpenRaster files. Screenwright and
Motionwright were read; this is a static-illustration contact/layering correction,
not a new animation or a change to the gameplay frog's model or equipment.

The implementation chooses #4 on 15% of launches and #6 otherwise. **15% is a
provisional implementation choice**, not a user-specified balance requirement.
A separate local cosmetic RNG rolls once at startup. Returning from gameplay,
opening settings and resizing do not reroll. It does not consume gameplay/voice
RNG, write profile state, or alter saves, unlocks, levels, sound or hop timing.

Compare on the existing website with `?splash=6` and `?splash=4`; native user
arguments `--splash=6` / `--splash=4` do the same. Invalid values use the ordinary
random selection. Each selection has desktop, compact landscape and portrait
art. Reload without an override to try normal chance selection; its result is
not a promise that every seventh load changes.

Validation completed:

- 17 native checks: exact probability boundary, both overrides, invalid override,
  all six texture/layout mappings, stable selection on menu returns, unobstructed
  Baby Mode entry and unchanged profile/equipment/sound state.
- 15 existing menu cycling checks pass.
- Six Chromium scenarios: both overrides on desktop and phone-size landscape and
  portrait; actual mouse/touch starts Baby Mode and returns to the same title.
  Desktop resize retains selection. No console/page errors.
- Six pixel comparisons: every changed pixel lies within the hat region.
- Godot 4.7.2 Web release, debug Web and Windows release exports built. Windows
  not executed; physical iPhone/Safari/Edge and OpenRaster editor import untested.

[Native checks](previews/hat-implementation/native.log) ·
[Menu regression](previews/hat-implementation/menu-regression.log) ·
[Browser checks](previews/hat-implementation/browser-results.json) ·
[Pixel preservation](previews/hat-implementation/art-preservation.json)

| | Desktop | Landscape | Portrait |
| --- | --- | --- | --- |
| #6 | [View](previews/hat-implementation/6-desktop.png) | [View](previews/hat-implementation/6-landscape.png) | [View](previews/hat-implementation/6-portrait.png) |
| #4 | [View](previews/hat-implementation/4-desktop.png) | [View](previews/hat-implementation/4-landscape.png) | [View](previews/hat-implementation/4-portrait.png) |

Shared Site baseline is v36, RiverSim **0.4.4-playable**, source
`7d9423c0f62773d7a0c7fee3a59c4f3bdab70cca`. Its 14 RiverSim files, three unrelated
files, hosting manifest and compressed engine remain byte-for-byte intact in
published **v37**. Both staged compressed release overrides reached their first
frame without errors, with the debug probe absent. Native Sites confirmed a
successful production deployment on October 21, 2026. Only tested Hopán root
output was overlaid; no intervening Site version was observed before deployment.
[Publication and v36 rollback record](HAT_SPLASH_PUBLICATION.json). Hosted runtime
inspection remains limited by the executor proxy.
