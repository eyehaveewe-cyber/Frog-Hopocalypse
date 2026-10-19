# Tile Hop encounter redesign and spike balls

This implements the user's Levelwright request: replace the two open tutorial
layouts with more demanding, readable encounters and room to inspect them. The
level-set names, filenames, unlock after NAHAIL, progress indices and map sizes
remain unchanged. This is Levelwright design synthesis applied to measured Hopán
rules; no external designer's rule or human playtest result is being claimed.

## Experience and layout

| Level | Spatial idea | Encounters and choices | Recovery |
| --- | --- | --- | --- |
| Big Hop Boulevard, 17 × 49 | Four clockwork courts linked by bends | Isolated copper rail; two approach gates into adjacent traffic lanes; water jump to a rail at a turn; a water-bounded free-shift court; separated dart, bug, road and final-rail crossings | Four flags outside all spike tracks, with observation banks before commitments |
| Your Move Crossing, 21 × 41 | Actions change the timing of an S-shaped route | Opening rail; sideways water bridge; compulsory sideways crossing of vertical road patrols; sheltered versus exposed entry into a dart/rail court; two water-gated vault entrances and an inside water shortcut | Four flags in refuge spaces; stopping gives unlimited planning time |

The first contains 377 dry traversable cells, nine hazards (four spike balls,
three cars, one bug and one turret), and eleven scenery objects. The second has
354 dry cells, eight hazards (four spike balls, two patrol cars, one bug and one
turret), and fourteen scenery objects. Counts describe contents, not a universal
measure of difficulty: swept tracks and choices matter more than spawn density.

The original levels allowed long stretches of straight travel around their
hazards. Walls now form encounter boundaries and turns. Water bounds the
four-way spike arenas while allowing a frog's long hop to enter or leave.
Quiet banks and flags have a job: preview a track, align a landing, or choose a
crossing. The final vault has a longer sheltered route and a shorter outer-bank
line; a blind straight rush can intersect the marked spike destination.

## Capability ledger and fairness

Existing measured constants remain: cell 1.8 world units, one-/two-cell cardinal
hops taking 0.34 simulation seconds, ordinary hazard beats every 0.62 seconds.
Walls and cheese walls stop both jump types; water or scenery can be cleared in
the middle of a long hop. Takeoff and landing stay vulnerable.

Spike balls are an explicit exception to ordinary one-cell hazard travel:
- A copper strip and endpoint ring mark the **locked next destination** throughout
  the hold. There is no flashing warning or random turn during the actual slam.
- The full straight segment is traversed in 0.16 simulation seconds. Swept
  relative collision catches a frog between endpoints, including at low sample
  counts. A holding ball is also dangerous to touch.
- The airborne middle of a long hop can clear a spike, just like other enemies.
- The default tile hold spends two hazard beats, then launches on the next beat.
  In Move with me, those are accepted hops; idle and blocked hops do nothing.
- In ordinary Hopán, hold values are seconds. Movement-linked time pauses both
  the hold and any ongoing slam when actual frog movement stops. Pause, Map and
  Exit Preview retain their existing world-freeze behavior.
- Static walls, cheese, scenery and water stop spike travel. Other moving enemies
  do not serve as walls. Free movement is deterministic per object ID on reload.

## Editor and portable JSON

**Spike ball** is available in the existing tool grid. Its inspector offers:
- **Free cardinal shifts**: one to four N/E/S/W checkboxes and a 1–5-cell maximum
  range. Each hold locks one clear cardinal target, stopping before barriers.
- **Slam patrol route**: Draw route, compact Loop checkbox, and Clear route.
  Waypoints use dry, clear, whole-cell cardinal segments. Add corners before
  turning. Loop must close cardinally; disabling it leaves the ball at the final
  destination as a contact hazard.
- A 1–6 hold value, labeled beats in tile mode and seconds in regular mode.

Version-1 JSON adds object `type: "spike_ball"`, `behavior: "free_shift"` or
`"slam_patrol"`, `pause`, `range`, `directions`, `waypoints` and `patrol_loop`.
Angles follow the existing editor convention: 0 north, 90 west, 180 south,
270 east. Old maps continue to load. Maps containing the new object require
this version's reader; export recovery copies before rolling back to v21.
Undo, manual saves, editor recovery and portable round trips include the object.
Its model is original procedural geometry, instanced into four material groups.

## Observed validation

26 focused spike checks pass: holds and target locking, full-segment and swept
collision, long-hop protection, nonlooping endpoints, four-direction movement,
barriers, deterministic targets, normal/linked timing, editor routes, undo,
JSON numbers, and both redesigned schemas. Existing tile rules pass 45 checks;
editor recovery and spinner behavior pass 23 checks.

Actual controller routes run with hazards active, no invincibility or teleports:

| Route | Hops | Simulation seconds | Result |
| --- | ---: | ---: | --- |
| Boulevard, initial phase | 61 | 26.35 | Complete; all four flags |
| Boulevard, 1.55-second later approach, observe traffic from bank | 61 | 29.40 | Complete; all four flags |
| Your Move, sheltered vault approach | 70 | 24.50 | Complete; all four flags |
| Your Move, water shortcut and outer-bank vault approach | 67 | 23.45 | Complete; all four flags |

A blind vault centerline was caught by the spike at (17,7); using its outer bank
completed the shorter route without changing hazard timing or disabling damage.
The regular Your Move Garden also completes unchanged, in 11.8667 simulation
seconds. Runs use the real 1/60-step controller/physics checks; `--fixed-fps 60`
is an accelerated test clock, not a device-performance measurement. Initial
baseline routes also passed with normal real-time synchronization.

Five desktop browser checks pass using actual keyboard/mouse inputs: first live
rail jump, full-map inspection, linked freeze and third-hop launch, placement and
direction masks, and a saved drawn route entering playtest. Perspective, both
maps, and the editor were inspected. See TILE_REDESIGN_VALIDATION.json for final
production checks and publication. Physical devices, Safari, first-time human
comprehension, enjoyment and formal photosensitivity evaluation remain untested.
