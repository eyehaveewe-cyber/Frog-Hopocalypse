# Placeable landmark scenery

This implements the user's large, coarse, walk-past background idea as actual
3D models. The five original procedural assets are a crouching Sphinx, an
Osiris-inspired statue, a pyramid, a giant moss tree and a giant heron. Their
shapes, proportions and vertex palettes are editable in
`game/scripts/landmark_models.gd`. No downloaded model, raster image generation,
photographic texture or external runtime dependency is used.

The existing frog, camera position/follower, ground textures, wall textures,
levels, hazards and unlock rules are preserved. Levels containing landmarks
raise the camera’s look target by 1.7 world units to leave silhouette headroom;
levels without them retain their existing framing. The exit preview blends
this offset as it sweeps, and overhead views use their normal framing. Scenery demos are separate editor maps, not new
mandatory campaign stages. This is a first integrated asset set, not a claim of
historically exact reconstruction.

## Use in the editor

1. Pick **Sphinx**, **Osiris statue**, **Pyramid**, **Moss tree** or **Heron** in
   the object palette. Place it on the course, on painted water, or in the
   surrounding water with **Background view** enabled.
2. Background view widens the overhead camera. Anchors may be up to 16 cells
   outside each map edge; the frog still cannot leave the playable rectangle.
3. Select the small gold ground pin to edit a tall model. The inspector changes
   model, 90-degree rotation and scale from 0.25× to 2×. Pins are editor-only and
   stay a usable size when the model is small. Erase / right-click removes the
   object. Undo, Redo, manual save, portable JSON and editor recovery retain it.
4. Landmarks are visual decorations, with no collision or damage. They cannot
   block an exit path, checkpoints, darts, actors or logs. Placement directly
   on the start, exit or checkpoint marker is prevented by the editor. Leave
   key lanes and landing views clear: large models can still visually obscure
   the frog or fill the camera when passed very closely.

Try **Editor → Scenery demos → Temple Shore / Heron Marsh → Playtest**.
These long shores contain distant and small course props, broad observation
decks and refuge flags. Walking into range reveals new scenery; moving closer
switches to the detailed model. Heron Marsh's first deck frames the large tree
and bird before the player walks underneath them. The full Map shows all six
landmarks in either demo using the cheaper mesh.

## Coarse appearance and rendering cost

The near material enlarges a 16×16 texture of broad grayscale patches over
vertex-colored surfaces. Nearest filtering produces the deliberately blown-up
look, without a full-screen blur. The far mesh drops small features and uses
painted directional shading with an unshaded material and no texture sampling.
The Android compatibility path is unshaded at both distances. Neither version
casts shadows, uses alpha foliage, normal maps, particles or per-object lights.

Each model/LOD is a cached, single-surface ArrayMesh. Copies reuse the geometry
and materials. Individual modeling pieces are merged into that mesh rather
than retained as dozens of render nodes. There is a maximum of 32 landmarks
within the existing 180-object map budget. This is a scene budget, not a proven
device-performance guarantee.

| Model | Near triangles | Far triangles | Reduction |
| --- | ---: | ---: | ---: |
| Sphinx | 334 | 108 | 68% |
| Osiris statue | 502 | 84 | 83% |
| Pyramid | 222 | 6 | 97% |
| Moss tree | 450 | 32 | 93% |
| Heron | 348 | 116 | 67% |

For one copy of each asset, far geometry is 346 rather than 1,856 triangles
(about 81% fewer). This measures geometry submitted by these models, not FPS,
whole-scene rendering work, load time, VRAM or battery life.

`game/scripts/landmarks.gd` swaps whole models using a shared ground anchor:

- Near transition: 56% of the level's draw distance, with a 1.2-world-unit
  hysteresis margin on either side.
- Beyond the draw limit: hide both versions. Previously hidden models reappear
  only after moving 1.2 units back inside the limit. This creates deliberate
  pop-in without repeatedly switching at one threshold.
- Update checks every 0.15 seconds; camera fitting/map changes also refresh it.
- Full Map and editor: all landmarks use far geometry, without distance hiding.
  The background-view setting only changes the editor camera.
- Generic terrain batching and per-piece draw-range settings exclude landmarks,
  preventing them from erasing the near/far logic or splitting a statue apart.

The debug `visible_triangles` / `visible_draws` fields count eligible geometry
and single-surface instances **before** the engine's frustum culling. They are
not hardware-profiler draw-call measurements. Editor ground pins are additional
small editor-only renderers; they are absent from gameplay.

## JSON and compatibility

```json
{
  "id": "shore_sphinx",
  "type": "landmark",
  "pos": [-2, 8],
  "landmark_kind": "sphinx",
  "landmark_scale": 1.0,
  "rotation": 180,
  "solid": false
}
```

The existing version-1 object list carries the new type. Its extended placement
bounds apply only to landmarks; actors and other objects stay within their
existing bounds. Model choices, scale, finite positions and budget are validated
before runtime use. Tile-mode anchors still use whole cells. Unknown model
names, invalid scales, out-of-range anchors and solid landmarks are rejected.
Old maps without landmarks are unchanged. Readers before this feature reject
the new object type: export custom maps before rolling back and retain the
feature source needed to read them.

## Evidence and limits

49 native checks cover five cached mesh pairs and attributes, triangle budgets,
both demos, regular/tile-mode and water/outside anchors, validation limits,
no-physics decoration, editor zoom/place/select/scale/Undo/Redo/erase, JSON,
near/far/hide transitions, threshold hysteresis, full-map behavior and camera
headroom isolated to scenery levels.
Existing editor recovery (23 checks) and level-rule behavior (35 checks) pass.

Seven browser checks exercise desktop keyboard approaches in both environments,
Map inspection, actual outside-water placement/Save/Undo, and Android-UA touch
movement with the compatibility renderer. Screenshots were inspected in
perspective and overhead at desktop and phone-landscape sizes. Results and
images are in `docs/previews/landmarks/`. Web release/debug and Windows release
exports build. Physical devices, Safari, actual GPU frame times and novice
visual recognition remain unverified. Automated Chromium uses SwiftShader and
cannot establish hardware frame-rate gains.

Source is isolated on `feature/landmark-scenery`, following the unpublished
per-level rules work. No merge or website deployment was performed. Revert the
feature commit for source rollback; retain exported landmark maps for a future
compatible reader. Existing campaign/audio files were preserved byte-for-byte.

## Reference grounding

- [Godot visibility ranges](https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html):
  simpler distant geometry/materials and hysteresis are relevant principles.
  This implementation uses a small CPU-managed mesh swap so that its state and
  whole-object pop-in are explicit in both normal and compatibility rendering.
- [The Met: Osiris](https://www.metmuseum.org/art/collection/search/566082) and
  [Museo Egizio: Osiris statuette](https://collezioni.museoegizio.it/en-GB/material/Cat_68/):
  crossed arms, crook/flail and the tall feather-flanked crown informed the
  recognizable silhouette. The in-game model is newly authored and stylized;
  museum imagery and geometry are not included.
