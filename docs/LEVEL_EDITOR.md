# Build a maze

Choose **Level editor** from the menu. All four Baby Mode stages open in the same editor as your own maps. Choose **New Egypt** or **New Swamp** for an empty, enclosed 17 × 13 board.

1. Give your level a name. Choose its Egyptian ruins or Purple Swamp-Woods theme.
2. Select **Floor**, **Path**, **Wall**, or **Water**, then click or drag on the board. Walls block movement; water kills the frog. Floor and path are walkable. Move the start/exit first if you want to paint hazards over their old cells.
3. Place the **Frog start** and **Exit gate** on different cells. These tools clear the selected cell for safe placement.
4. Place pillars, trees, mushrooms, pots, critters, or dart traps. Each grid cell holds one object. Pillars, trees and traps block movement. Mushrooms and pots can be made solid in their inspector.
5. Choose **Select** and click an object to open properties below the palette. Scroll the panel to see all properties. **R** rotates by 90 degrees. Traps show firing interval; critters show behavior and speed.
6. For a patrol, select a critter, choose **Patrol route**, then click dry cells in travel order. Route points are numbered and connected. Include corners around walls; critters move directly between points and cannot pass through obstacles. **Loop route** repeats the waypoint sequence (enabled by default, including older saved levels). Turn it off to stop at the final waypoint. Include corners/return points as needed; the overlay shows the closing segment. **North–south loop** creates two endpoints along the selected critter’s clear column, stopping at walls, water, static scenery, spawn or exit. Choosing Patrol turns a bug into a worm; the shortcut does this automatically. **Clear route** removes waypoints. Patrol critters without routes wander.
7. Click **Playtest** or press **Space**. Play uses the PS1-style perspective camera following the frog. Move freely using WASD/arrows. The grid controls placement, not movement. Avoid critters, water and darts. Reach **EXIT** to win. Press **M** or **Map** to pause and inspect the whole maze from overhead; **M** or **3D view** returns to play.
8. Click **Back to editor** to retain the exact document. Play never changes authored positions or settings.
9. **Save** keeps a local copy. **Duplicate** creates and saves an independent copy. Load maps from the saved-level dropdown or play them from the main menu.
10. **Export JSON** downloads a map in the browser or opens a desktop Save dialog. **Import** accepts a file or pasted JSON. Imported maps are unsaved until you save them.

The palette also includes **Road**, **Car** and **Log**. Put cars on road and
logs on water; Select exposes length, speed and left/right direction. Logs
carry the frog across water, and cars are lethal. The finale's safe-bank
checkpoint is retained through map import/export.

Playtesting rejects invalid maps or maps with no connected ground/log-lane
route to the exit. This checks structural access, not moving-platform timing
or hazard fairness. Playtest with the actual frog and hazards active.

## Shortcuts

| Action | Control |
| --- | --- |
| Move | WASD/arrows; touch joystick on mobile |
| Retry | R or Retry |
| Pause/resume | Esc or Pause |
| Overhead map / return to 3D | M or Map / 3D view |
| Paint/place | Left click; drag terrain |
| Erase | Right click or Erase tool |
| Rotate selection | R |
| Playtest | Space |
| Undo | Ctrl+Z / Cmd+Z |
| Redo | Ctrl+Y / Ctrl+Shift+Z / Cmd+Shift+Z |
| Save | Ctrl+S / Cmd+S |
| Cycle unlocked headwear | Hat button |

## Save locations

Desktop saves use Godot's `user://library.json`. Browser saves use browser-local IndexedDB on the current site's origin. Clearing site data or switching hostnames can remove or separate saves. **Export JSON is the portable backup**; it contains map data without game code. Renaming and saving updates the current slot; Duplicate allocates a new slot. Imported maps allocate a slot on their first save.

The editor targets desktop mouse and keyboard. Mobile provides landscape gameplay and large touch controls; touch editing is not polished. Hiding the tab pauses gameplay; use Resume after returning.

## Extra terrain and patrols

**Cheese wall** blocks frogs, bugs and worms while darts pass through it. It is
blocked terrain for spawn/exit, patrol points and exit-route validation.

**Seam worm** is blue with gold bands. Place it at an open junction: the editor
snaps to the lower-right corner of the clicked tile. **Draw patrol waypoints**
follows the same corners. Use horizontal/vertical legs and include corners for
all turns, including the loop's final connection to its first waypoint. All four
tiles around each junction must be open and dry. No route means it waits in place.
It uses the same loop, speed and worm-death cues as ordinary patrol worms.

**Patrol car** belongs on Road. Choose East–west or North–south and its initial
direction. With no route, the car bounces between road ends or static blockers.
**Draw car patrol** adds road-cell points; include each corner and keep every
segment on connected road. Drawn routes repeat and override the axis. **Clear
car route** restores straight-axis patrol. Cars fit one road tile; ordinary
lane cars/logs retain their existing behavior. New terrain and patrol variants
save in version-1 JSON; older saved levels remain supported by this build.

Trees are ignored by the structural exit-path check because their trunks do not
occupy an entire tile. Actual movement still collides with their trunks. The
check remains structural, rather than a guarantee of safe hazard timing.
