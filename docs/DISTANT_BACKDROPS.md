# Distant monuments

The independent **Distant backdrop** editor tool puts fixed, giant cutout art on
an extended sea horizon. Existing placeable landmarks remain fully modeled near
and far scenery. This branch does not change course geometry, hazards, unlocks
or audio, and is not deployed.

Open **Level editor → Scenery demos → Horizon · 1x / Horizon · 80x**. These two
Temple Shore copies have identical tiles, spawn, exit, existing landmarks, camera
and clipping; only the new art scale differs. Preview images and measured browser
results are in [previews/backdrops](previews/backdrops/).

| Comparison | Preview |
| --- | --- |
| 1× | [Unmagnified](previews/backdrops/1x.png) |
| 80× | [Monumental](previews/backdrops/80x.png) |
| Walking | [Approach](previews/backdrops/80x-approach.png) |
| Touch compatibility | [Emulated phone](previews/backdrops/touch-80x.png) |
| Foreground depth | [Open](previews/backdrops/occlusion-open.png) · [Tree occlusion](previews/backdrops/occlusion-foreground.png) |

Validation: [native/build record](BACKDROP_VALIDATION.json) and
[browser measurements](previews/backdrops/results.json).

## Authoring

Choose **Background view**, then **Distant backdrop**. Place the gold ground pin
in the surrounding water or on the map. Select Sphinx, Osiris-inspired statue,
pyramid, moss tree or heron. **x art scale** is 1–100 (default 80), and
**backdrop distance** is 128–2048 world units (default 480). Scale and distance
are independent of course size and existing landmark scale. Select, erase,
Undo/Redo, local Save and portable JSON use the existing editor workflow.

Each pin sets a bearing from the map center. Its cutout is placed at that bearing
and distance, facing the map center, with its feet at sea level. It never moves
or rotates with the camera. Approaching it gives natural world-space parallax;
foreground course meshes occlude it. It is distant postcard scenery, so walking
around it does not reveal a fully modeled back. Map/editor views show small
thumbnails at the ground pins instead of the giant cards.

The portrait baseline is 1.5 units high: 80× gives 120 units. That suggests about
394 feet **only if** one artist world unit is interpreted as a meter. This is an
artistic scale cue, not a measured physical scale. A fixed sea plane grounds the
feet beyond the finite detailed ocean. Only backdrop maps extend the camera far
plane and use 66° desktop / 70° touch perspective with a higher look target to
keep the frog and monuments in view. Ordinary levels retain their framing and
draw ranges.

## Rendering tradeoffs

Five original procedural landmark models are baked offline into tightly cropped
RGBA PNGs, at most 124 pixels on an axis. Nearest sampling and palette steps
retain the enlarged coarse appearance. The five base RGBA8 images total 196,912
texel bytes before engine allocation/import overhead. Materials are shared,
unlit, alpha-scissored and depth-tested; no runtime blur, dynamic baking,
shadows, lights, collision or camera-facing updates are added.

Each visible card has two triangles. The demo has four card triangles plus two
for an opaque, flat horizon sea. Map views hide both. The map cap of four cards
bounds the eligible geometry but does not guarantee cheap fill: magnification
increases the screen area, and texture fetch/discard and depth work still cost
GPU time. The sea also covers screen area. A six-triangle opaque far pyramid can
be cheaper than a cutout when fill-bound; this layer trades texture work for a
much lower geometry count than the detailed giant models, not universally lower
render time. It does not change existing landmark LOD or ordinary draw-distance
culling.

`Backdrops.stats()` reports clipped projected quad-rectangle pixels, summed
before foreground occlusion. This is a conservative fill-area indicator for the
demo, not exact opaque coverage, draw-call timings or FPS. The native 250×188
comparison measured 1 vs 4,374 rectangle pixels at 1×/80×, with identical six
total horizon/card triangles and camera far 808.2. Browser measurements and
viewport sizes are retained in the preview results. Real GPU/mobile FPS and
Safari remain unverified. Alpha scissor and normal depth behavior follow
[Godot material documentation](https://docs.godotengine.org/en/stable/classes/class_basematerial3d.html);
performance caveats follow [Godot's 3D performance guide](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html).

## Source and rollback

See [bake source](../art-source/backdrops/README.md). Schema: `type: "backdrop"`,
`backdrop_kind`, `backdrop_scale`, `backdrop_distance`, `pos`, `solid: false`.
The existing map version stays 1; previous readers reject the new object type.
Keep exported custom backdrop maps before reverting the feature commit. Revert
this commit on its branch for source rollback; existing course maps and sounds
need no migration. No main rewrite, merge or site publication is part of this
change.
