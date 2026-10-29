# NYC difficulty revision

The user rates the previous two NYC collections at 1/10 and requests 7/10, defined as roughly fifteen attempts to clear a level, with fifty attempts representing 10/10. This pass targets that learning effort through crossing decisions and less forgiving timing. Fifteen attempts is a design target, not a measured result. First-time human playtests are still needed to calibrate it.

Levelwright's foundations and puzzle/action workflows informed the revision. The preserved capability envelope is continuous movement at 4.2 world units per second, a 0.32-unit frog radius, and 1.8-unit cells. The hop animation does not let the frog jump traffic or water. Existing level filenames, names, campaign order and progress keys remain unchanged.

## The six NYC courses

| Course | Changed decision |
| --- | --- |
| Central Park | The pond approach now leads through two opposing traffic pairs, separated by a central garden gate. Choosing one bank no longer removes most of the level's timing challenge. |
| Brownstone Blocks | A second avenue pair follows the west stoop gate and a transverse roach patrol. The exit arcade is on the east side, requiring another choice of crossing line. |
| East River Piers | Two narrower patrolled boardwalks offer different approaches between the service roads. A western arcade and third avenue pair precede the final sidewalk. |
| Broadway After Dark | West, east and central arcade openings replace the open edge bypasses. Two sidewalk patrols interrupt a continuous sprint between the existing three traffic pairs. |
| Midtown Rush Hour | West, east, west and center median gates require successive lateral repositioning. Mixed vehicle streams leave shorter gaps, while safe sidewalk rows remain between pairs. |
| Brooklyn Skate Circle | Barriers at the central waist close the outer promenade. The frog must enter the rider circuits and choose a west pocket or east rail crossing. A north-approach patrol adds a final timing decision. The original rail/ramp support geometry and rider tricks remain intact. |

The alternative of increasing every speed alone was rejected. The courses still need places to observe traffic, and changing approach lines makes information from one attempt useful on the next. New scenery is not required for the challenge. Existing props whose ground became road, water or a closed arcade were removed from those positions.

## Measured changes

The traffic runtime distributes an integer number of vehicles around its loop. The figures below use that actual count, rather than treating the requested spacing as the final interval. Clear time is `(actual center interval - longest vehicle length - frog diameter) / lane speed`, taking the smallest value in each course. It describes an individual lane gap, not an entire two-lane crossing window.

| Course | Lanes, before → after | Runtime vehicle count, before → after | Minimum clear time, before → after |
| --- | ---: | ---: | ---: |
| Central Park | 1 → 4 | 3 → 18 | 4.68 → 1.46 s |
| Brownstone Blocks | 2 → 4 | 6 → 18 | 3.75 → 1.43 s |
| East River Piers | 4 → 6 | 12 → 28 | 3.28 → 1.32 s |
| Broadway After Dark | 6 → 6 | 24 → 33 | 2.19 → 1.11 s |
| Midtown Rush Hour | 8 → 8 | 37 → 44 | 1.23 → 0.85 s |

In the same forecast-aware test driver, Broadway's route increased from 30 to 44 grid steps and Midtown's from 46 to 56. The driver's informed zero-phase completion times changed from 15.75 to 21.78 seconds for Broadway and 22.05 to 30.73 seconds for Midtown. These numbers establish additional traversal and timing demands; they do not estimate human attempts or FPS.

## Runtime checks

```sh
python3 tools/redesign_nyc_set.py
bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/nyc_difficulty_routes.gd
bash tools/godot.sh --headless --script res://tests/skater_contacts.gd
```

The authored transformation changes only the six NYC JSON files. Applying it twice produced byte-identical JSON in every file. It can be reapplied to the preceding unified-game source to obtain this revision.

The route suite passes **72 checks across eighteen complete traversals**. Each course is loaded independently with initial departure waits of 0, 0.75 and 1.5 seconds. The driver supplies ordinary movement input, waits outside dangerous groups of cells, and predicts traffic and skater motion before crossing. Traffic, roaches and skaters remain active throughout; the frog is never teleported. Each run reaches `LEVEL COMPLETE!`. The fixed-fps headless runner advances the ordinary 60 Hz simulation without wall-clock throttling.

| Course | Successful informed completion times across the three phases |
| --- | ---: |
| Central Park | 9.77–13.70 s |
| Brownstone Blocks | 19.27 s |
| East River Piers | 17.18 s |
| Broadway After Dark | 21.78–27.67 s |
| Midtown Rush Hour | 30.73 s |
| Brooklyn Skate Circle | 10.95–15.17 s |

Full route output is in [nyc-difficulty-native.txt](nyc-difficulty-native.txt). Brooklyn also passes the existing **25 skater contact checks** at 30, 60 and 120 Hz. Actual rail contact error remains below 0.00001 world units; the existing maximum shoe-to-board error is 0.0165 units. Those checks preserve the real supported tricks, not only route-point positions.

During tuning, the route test exposed a disconnected Midtown final gate beside the fountains; the final gate now opens into dry center ground. The first Brooklyn driver also tried waiting inside a rider path. The driver now groups a crossing through rider cells and waits outside that path. A short north patrol initially gave the conservative driver no acceptable interval, so the final patrol covers a wider, readable stretch with a usable return gap.

The baseline replay completed all five traffic courses at all three phases. Its old Brooklyn route hit the driver's conservative thirty-second wait limit, so no before/after Brooklyn completion-time claim is made. That timeout does not prove the older level impossible.

These automated successes prove available routes and functioning recovery opportunities, not that the requested fifteen-attempt difficulty has been achieved. Normal-camera browser captures and control checks are recorded with the combined release evidence. Physical mobile controls and first-time human difficulty remain open.
