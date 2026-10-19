# Tile Hop and movement-linked time

Tile Hop unlocks after clearing all four Not as Hard as It Looks stages. The editor's
**Movement demos** button exposes all demos for immediate authoring and testing.
The existing Baby Mode, human-made stages and original Shelby layout are unchanged.
Tile progress is a separate optional field in the existing version-1 profile.

## Controls and rules

- Arrows/WASD or the touch joystick: one cardinal tile per hop. Holding a direction
  repeats hops. Short key presses are queued so a release before the next physics
  frame still counts.
- Hold Shift with a direction, or arm **Long hop** before using the joystick:
  two tiles. The button resets after an accepted hop.
- A long hop clears a non-wall object, enemy, dart or one-tile water gap in the
  middle. Walls and cheese walls stop both hop types. The landing must be clear;
  unsupported water still drowns the frog. Takeoff and landing remain vulnerable.
- A hop interpolates for 0.34 seconds with a visible jump arc. The frog is 1.5×
  its original visual size in Tile Hop. Single hops do not grant airborne immunity.
- Critters, lane cars, road patrol cars, logs and darts advance in cardinal
  one-tile beats, with interpolation between their tile positions. Seam worms
  retain their edge-junction grid. Tile mode uses one common beat rather than
  individual continuous speed fields; the inspector explains this. Dart emitters
  use whole beats per shot (existing fractional intervals round up).
- Normal Tile Hop advances hazard beats every 0.62 seconds while you can wait.
  **Move with me** instead advances exactly one beat per accepted hop, freezes
  between actions, and does not spend a beat for a blocked hop.
- In regular Hopán, **Move with me** advances hazards, projectiles, their timers,
  logs and the level clock only during actual frog displacement. Pressing against
  a wall does not run the world. Water texture time follows the same rule in the
  full graphics path. Death/victory presentation and narration remain responsive.

The editor saves `game_mode` (`hopan`/`tile`), `move_with_me` (boolean) and
`draw_distance` (10–30 tiles) in ordinary portable level JSON. Enabling tile mode
snaps legacy off-center objects to their owned grid cells; Undo restores the old
layout. Checkpoints, saves, hats, sound and map inspection remain available.

## Authored demos

| Demo | Size | Purpose | Time rule |
| --- | --- | --- | --- |
| Big Hop Boulevard | 17 × 49 | Four timed courts: copper rails, adjacent traffic, a bounded free-shift arena, and separated dart/bug/road crossings. | Hazards run while idle. |
| Your Move Crossing | 21 × 41 | Sideways water and traffic crossings, route-dependent clock phases, and a water-gated four-way spike vault. | One valid hop advances one beat. |
| Your Move Garden | 17 × 33 | Demonstrate the same freeze-on-rest rule with regular continuous Hopán movement. | Hazards run during actual movement. |

The regular movement demo joins the immediate Bonus set after Shelby. The two
Tile Hop demos form their own unlocked set. HUD hints appear near authored teaching
points; they do not rely on tiny world-space text. Checkpoints provide recovery.
`tools/generate_movement_demos.py` reproduces the three editable JSON layouts.

## Scale, perspective and draw distance

The supplied Frog Frenzy screenshot informed a lower following camera, larger
foreground cells and a more prominent frog; existing Hopán textures and models
remain. Regular Hopán's frog is visually enlarged to 1.12×. The camera follows
2 world units ahead of the frog, from a relative offset of (0, 4.6, 8.0), with
existing 58° desktop / 63° touch field of view. These are project choices, not
measurements claimed from the reference game.

The editor offers a 33 × 49 tour preset; JSON supports up to 64 × 64. Large maps
batch static geometry into six-tile spatial chunks. The default 18-tile visibility
range is shorter than the demo maps. Full graphics coarsens distant texture UVs
and uses a grain cutout near the draw limit, with the existing haze. Compatibility
mode retains unshaded materials and range culling without adding custom shaders.
Map/editor views restore full range. Dynamic flags stay outside static batching.

This uses Godot's [visibility-range controls](https://docs.godotengine.org/en/stable/classes/class_geometryinstance3d.html#class-geometryinstance3d-property-visibility-range-end).
It is render culling, not world streaming: collision and simulation state stay
loaded. Large-map memory/frame rate on a physical phone has not been measured.

## Verification

Native coverage includes 45 new mechanics/editor/culling checks and existing
menu (19), voice (19), and checkpoint/sound (24) regression checks. The three
complete routes reached the real exit with hazards active:

- Big Hop Boulevard: 35 hops, 15.08 seconds of simulation.
- Your Move Crossing: 42 hops / 42 hazard beats, 14.70 seconds of simulation.
- Your Move Garden: 11.87 seconds of continuous movement simulation.

These times measure scripted controller traversal, not first-time player pace.
Browser checks exercise actual keyboard/touch controls and inspect the rendered
views. Desktop software rendering cannot establish physical Android/iPhone
performance or Safari compatibility. Existing cleanup warnings in some native
regression processes are retained in the logs rather than counted as assertions.

The two tile levels were redesigned with Levelwright. See [encounter layouts,
spike-ball rules and playtest evidence](TILE_LEVEL_REDESIGN.md). Spike balls
telegraph and then slam multiple cells; other hazards retain their tile beats.
