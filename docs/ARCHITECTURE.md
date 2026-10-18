# Systems and level data

Godot 4.7.2, GDScript, Compatibility rendering, single-threaded web export. Entry scene: `game/main.tscn`.

| Component | Responsibility |
| --- | --- |
| `scripts/main.gd` | Menus, editor, history, local library, import/export, mobile controls, playtesting |
| `scripts/level_data.gd` | JSON validation, numeric normalization, serialization, static route check |
| `scripts/world.gd` | Shared world construction, simulation, projectiles, hazards/victory, camera/effects |
| `scripts/actor.gd` | CharacterBody3D movement, wandering/patrols, animation |
| `scripts/art.gd` | Original mesh kits, shared resources, static MultiMesh batches, hat attachment |
| `scripts/pixel_textures.gd` | Original deterministic 32 × 32 terrain, masonry, water, bark, leaf and frog textures |
| `shaders/retro_surface.gdshader` | Vertex snapping, vertex lighting, distance haze and stepped water animation |
| `shaders/retro_screen.gdshader` | World-only 5-bit-per-channel color quantization and ordered dithering |
| `shaders/night_sky.gdshader` | Moon and star backdrop |
| `levels/*.json` | Bundled maps using the custom-level format and loader |

Cells span **1.8 world units**. The frog moves at **4.2 units/second**, with a **0.32-unit** sphere collider, continuously in X/Z space. Critters use **0.38-unit** colliders; lethal contact uses a 0.67-unit combined envelope. World solids occupy physics layer 1; actors collide with solids. Actor contact kills rather than pushing. Invisible outer colliders retain actors when borders are painted out.

Projectiles travel at 7 units/second. Each tick raycasts their swept segment against solids, then checks the unobstructed segment against the frog. Darts cannot kill through walls. Retry reconstructs actors, emitter clocks and projectiles from authoring data. The editor document is independent of the runtime copy.

## JSON version 1

```json
{
  "version": 1,
  "name": "My maze",
  "theme": "egypt",
  "width": 17,
  "height": 13,
  "tiles": [["floor", "wall", "water", "path"]],
  "spawn": [1, 11],
  "exit": [15, 1],
  "objects": [
    {
      "id": "scarab-1", "type": "critter", "pos": [5, 5],
      "rotation": 0, "solid": false, "behavior": "patrol", "speed": 1.6,
      "waypoints": [[5, 5], [8, 5], [8, 8], [8, 5]]
    },
    {
      "id": "trap-1", "type": "emitter", "pos": [10, 5],
      "rotation": 90, "solid": true, "interval": 2.5
    }
  ]
}
```

The abbreviated tile row is illustrative. Valid documents contain exactly `height` rows of `width` tile names. Themes: `egypt`, `swamp`. Objects: `pillar`, `tree`, `mushroom`, `decoration`, `critter`, `emitter`. Limits: 5–25 cells per side, 180 objects, 64 waypoints per critter. The editor creates 17 × 13 maps; imported sizes within the limits use the shared loader. Trap rotation: 0° north, 90° west, 180° south, 270° east. Intervals: 0.5–10 seconds; critter speed: 0.3–5 units/second.

The importer validates before replacing the document. Whole JSON numbers are normalized to integers, preserving grid-coordinate equality after loading. All saves use the same serializer. The local library is written to a temporary file and renamed into place.

## Presentation modes

Gameplay uses a perspective camera looking north with a fixed viewing angle and a smoothed position following the frog. Movement remains in the same world directions as the editor. The 3D SubViewport is reduced to roughly 240 vertical pixels at desktop sizes and nearest-scaled; UI text and buttons render separately at interface resolution. Surface textures use nearest filtering. The world-only post shader applies ordered dithering and 5-bit RGB color, while the surface shader adds gentle projected vertex snapping and depth haze.

The overhead map sets `world.map_view`, pauses simulation and disables the low-resolution/postprocessed presentation. The editor uses the same full-resolution orthographic view and grid picking; pointer coordinates are converted between the displayed viewport and the actual render size. Swapping views never changes the level document or collision logic. The shared JSON format supports a future bonus 2D mode, which is not implemented in this change.

## Demo authoring

`tools/create_demo_maps.py` records handcrafted layouts. `game/tests/author_demos.gd` reconstructs them through the actual painting, object-property and saving operations, then writes the editor documents to `game/levels`.

To intentionally rebuild content:

```sh
python3 tools/create_demo_maps.py
XDG_DATA_HOME=/tmp/hopan-author-data bash tools/godot.sh --headless --script res://tests/author_demos.gd
```

This is a content command, not environment setup: it changes bundled JSON. All three demos were built through this path. Moonlit Oasis starts the frog near the foreground center and offers two zigzag routes through canals, a connecting causeway, palms and a perimeter loop. Egyptian ruins offer a lower cross-courtyard route and winding upper route, with a timed dart lane. Violet Mire replaces central passages with water pockets and dry loops. Lower paths provide a safe starting stretch before enemies.
