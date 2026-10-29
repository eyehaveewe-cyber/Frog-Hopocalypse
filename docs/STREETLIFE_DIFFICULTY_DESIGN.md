# NYC Streetlife difficulty pass

The user called the previous sets 1/10 and requested 7/10, described as roughly 15 attempts rather than 50. This pass targets that harder learning experience. No human attempt count has been measured. The levels retain their filenames, names, campaign ordering, ordinary continuous controls, existing city props and supported skate tricks.

## What changes during play

| Level | New decision | Dry shortest route before / after, cells |
| --- | --- | --- |
| Stoop Patrol | Five offset alley mouths require watching the nearby roach, crossing, then changing sides on the next landing. |24 /42 |
| Newsstand Weave | The outer-wall bypass closes. Choose the narrow west rider alley or the wider east crossing with overlapping circuits. This is the shorter relief level. |22 /22 |
| Ferry Railwalk | Loading gates alternate sides before the pier; a second board crosses the same pier. Pass the supported rail at an end, then change sides in the north forecourt. |32 /46 |
| Banked Boulevard | Line up before a denser two-lane crossing. Both bank gates are patrolled. Another change of line guards the exit. |30 /44 |
| Sanitation Courts | Narrow refuse gates alternate sides. Read two patrols at the delivery court and two boards around the supported grind line. |50 /54 |
| Block Party | A traffic approach leads to a board crossing the entry. Choose a bank route, negotiate the upper circuits, then cross the final avenue and exit alley. |24 /48 |

The route lengths in this table measure tile topology only. The runtime solver includes solid prop footprints, so its paths are 42, 24, 46, 44, 56, 48 cells. Neither measure proves difficulty. The content has more mandatory hazard intersections, not a new global speed multiplier. Fixed landings between challenges provide observation and recovery space. Start positions remain safe, and immediate retry still uses the existing game behavior.

The frog remains 4.2 world units per second with a 0.32-unit collider. One tile is 1.8 units. A one-tile alley therefore leaves 1.16 units beyond the frog's collision diameter. Roaches use authored loops, and skaters use the actual supported rail and bank routes. Roads retain individually usable gaps. The level validator checks every rider segment, including loop closure, against water, walls and ordinary solid props.

## Verification

```sh
python3 tools/redesign_streetlife_set.py
XDG_DATA_HOME=/tmp/hopan-streetlife-qa bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/streetlife_difficulty_routes.gd
```

The generator was run twice with identical hashes for all six JSON files. It edits only the six Streetlife layouts. The native runner completes all six levels at three initial waits, 0, 0.75 and 1.5 seconds, for 18 continuous traversals and 72 passing checks. It steers through the ordinary controller with all hazards active. No player teleport, hazard pause, deleted enemy or invulnerability is used. Its informed routes forecast existing patrol and vehicle motion before moving. Completion ranges from 10.12 to 29.10 simulated seconds, including waits.

The test also accepts `-- --naive` to follow its route without observing hazard timing. Ten departure phases, 0 to 4.5 seconds in 0.5-second intervals, completed 38/60 runs on the previous content and 8/60 on the new content. Per-level results are in [the diagnostic](streetlife-difficulty-diagnostic.json). This driver already knows a route and uses no human perception. It is evidence that ignoring timing is less successful, not an estimate of player attempts, fun, camera readability or reaction demands.

For the recorded baseline, the same test loaded the six files from the previous published source tree, remote commit `5806a698e989ce7e06e9ef226452917e58c3fc86`, materialized into `/tmp/streetlife-baseline/`, with `-- --naive --baseline`. `--baseline` is a development-only input to the test, never the game.

[Native trace](streetlife-difficulty-native.txt) records every current result. Browser appearance is part of the combined NYC pass. First-time human play is still needed to tune toward the user's 15-attempt target; software-rendered browser checks cannot establish physical mobile playability or a measured frame rate.
