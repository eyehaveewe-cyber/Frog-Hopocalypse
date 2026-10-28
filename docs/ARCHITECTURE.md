# Systems and level data

Godot 4.7.2, GDScript, Compatibility rendering, single-threaded web export. Entry scene: `game/main.tscn`.

| Component | Responsibility |
| --- | --- |
| `scripts/main.gd` | Menus, editor, history, local library, import/export, mobile controls, playtesting |
| `scripts/level_data.gd` | JSON validation, numeric normalization, serialization, static route check |
| `scripts/world.gd` | Shared world construction, simulation, projectiles, hazards/victory, camera/effects |
| `scripts/roach.gd` | Shared critter motion with a distance-driven six-leg gait and antenna animation |
| `scripts/skater.gd` | Closed elevated skate routes, pushing/grinding/ramp poses and per-corner swept collision |
| `scripts/nyc_streetlife_art.gd` | Ten city/skate props, segmented roach and three articulated rider variants |
| `scripts/streetlife_specs.gd` | Authoritative rotated ground footprints used by runtime collision and route checks |
| `scripts/traffic.gd` | Deterministic lane traffic, moving wheel pivots, swept relative collision and wrap seams |
| `scripts/nyc_art.gd` | Editable original NYC vehicles, street props and skyline, merged vehicle body meshes |
| `scripts/city_streets.gd` | Crosswalks, road markings, curbs, drain grates and traffic signals |
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

The abbreviated tile row is illustrative. Valid documents contain exactly `height` rows of `width` tile names. Themes: `egypt`, `swamp`, `nyc`. Terrain also accepts `road`. Objects: `pillar`, `tree`, `mushroom`, `decoration`, `critter`, `emitter`. Limits: 5–25 cells per side, 180 objects, 64 waypoints per critter. The editor creates 17 × 13 maps; imported sizes within the limits use the shared loader. Trap rotation: 0° north, 90° west, 180° south, 270° east. Intervals: 0.5–10 seconds; critter speed: 0.3–5 units/second.

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

## NYC traffic extension

Version 1 maps may carry `traffic`, a list of up to 12 straight horizontal lanes, and `crossings`, up to eight interior grid columns. Older maps omit both. Each lane uses a unique interior whole-number `row`, `direction` of -1 or 1, `speed` in world units per second from 2 to 8, `spacing` from 7 to 20 world units, `offset` from zero to less than spacing, and a nonempty `vehicles` list drawn from `taxi`, `sedan`, `bus`, `truck`. All interior cells of a traffic row must be road, without objects, spawn or exit.

For example, `{"row": 6, "direction": 1, "speed": 3.2, "spacing": 12, "offset": 2, "vehicles": ["taxi", "bus"]}`. Runtime spreads an integer number of vehicles around a loop including off-map approach space, so actual center spacing is at least the authored spacing. Vehicles translate continuously without random spawns. Crosswalks indicate useful crossing lines; traffic keeps moving. Signals at road ends show green to the vehicles.

The runtime sweeps the frog relative to each vehicle's moving axis-aligned footprint. A seam copy handles wrapping without sweeping a phantom vehicle through the entire map. Contact produces `FLATTENED!`. Retry restores all lane phases. Traffic stops during pause, overhead map, editing, and results. Named wheel pivots rotate at distance divided by tire radius. World static batching excludes traffic; each vehicle merges stationary body geometry by material and keeps wheel assemblies separate.

NYC JSON generation and static audits are in `tools/create_nyc_maps.py`. Authored traffic settings survive ordinary editor save/import/export. The terrain palette supports roads and the theme picker supports NYC; lane parameter authoring is currently through JSON or the generator.

## Streetlife and skate routes

Object types also include `roach`, `skater` and `city_prop`. Roaches use the
existing wander/patrol contract and collision rules, with articulated legs driven
by distance traveled. Street props specify a string `variant` from the editor's
NYC prop picker and an optional `solid` flag. Rail/ramp `length` is 1–5 world
units; ramp `rise` is 0.2–1.2 units. The frog remains on the ground, so solid
skate fixtures are obstacles for the frog while supporting authored riders.

Skaters use numeric `variant` 0–2, speed 2–5.5 world units/s, and a cyclic
`route` of 4–32 nodes. Each node records a grid `pos`, physical world-unit
`height` in 0–1.2, and outgoing `trick` of `cruise`, `push`, `grind` or `ramp`.
The object's position equals the first node. The importer checks every segment
for dry floor, including loop closure, and rejects zero-length segments and
solid street furniture intersections. Optional `skate_area` specifies a center
and diameter in tiles. Routes must remain within this disk, at most 18 tiles
across. Brooklyn Skate Circle uses that full diameter.

Skaters follow continuous routes without chasing or teleporting. The controller
records time-stamped sub-frame sweeps at every corner, then tests relative frog
motion against the moving rider envelope. Contact produces `SKATED!`. Ground
translation, physical elevation and visual articulation have separate owners.
Pause, map view, editor and result states freeze all enemy motion and poses.
Retry reconstructs their deterministic starting phases. `Data.find_route` uses
the same rotated ground footprints as static prop collision, so editor
reachability and physical traversal do not route through long ramps or rails.

The palette supports roaches, skaters and NYC props. The inspector selects prop
and rider variants, speed and solidity. Placing a skater creates a validated
small loop; custom ramp/rail routes and elevations can be authored in JSON.
Portable saves preserve all these fields.

## Level sets

The bundled catalog preserves the nine original maps and appends six NYC
Streetlife maps. Set JSON declares `level_set: "nyc_streetlife"`, `set_index`
from 1 to 6, and a short player-facing `hint`. The importer validates these
metadata fields before the UI uses them. The shared loader, editor and save
library still consume the same version-1 map format.

`start_streetlife_set` launches the first set entry. `next_builtin_index` bounds
progression within the original campaign or the six-level set, so the final
original map cannot silently enter the new set. The sixth set victory offers
`Replay NYC Streetlife`; it never advances beyond the set. Menu entries also
allow individual practice. Retry restores the current map's original hazard
phases and retains its authored hint.

`tools/create_streetlife_set.py` is the deterministic content entry point.
`streetlife_set_common.py` contains geometry, support and required-gate audits;
`streetlife_set_late.py` authors the three combined-system layouts. Existing
content generators remain separate. `game/tests/streetlife_set_integration.gd`
checks the six layouts and live traversal, then activates the real progression
buttons. The browser runner uses actual menu scrolling and controls to select
and inspect all six levels.
