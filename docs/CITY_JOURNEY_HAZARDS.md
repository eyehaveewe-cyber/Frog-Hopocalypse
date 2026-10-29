# City Journey hazard behavior and evidence

The two new City Journey maps reuse existing traffic, roaches and skateboarders. `park_hazards.gd` adds original procedural park figures and visible attack warnings. These are stylized game encounters, not a simulation of real park behavior.

| Encounter | Warning | Active attack | Safe recovery |
| --- | --- | --- | --- |
| Bush ambusher | 0.85 seconds; raised arm and yellow lunge path | 0.62 seconds; figure leaves the bush with a small cartoon knife | 1.8 seconds; figure retreats |
| Purse swing | 0.9 seconds; raised arm and yellow swing arc | 0.65 seconds; bag sweeps an authored arc | 1.9 seconds |
| Pigeon keeper | 1.1 seconds; yellow flight corridor | 1.65 seconds; seven flapping birds fly forward | 2.3 seconds |
| Ice duet | Continuous, visible paired motion | Two skaters orbit opposite sides of the rink center | The center and outside of their orbit remain alternatives |

The three attacks activate only while the frog is within six world units. Their directions remain fixed after the warning, so stepping off the indicated path works. Warning and recovery are harmless. The `phase` property offsets animation; duet phase also offsets its orbit. It does not silently pre-arm an offscreen attack. Park contact sampling uses intervals no longer than 1/60 second and relative swept player/attacker positions. Raised bridge players above the low attack envelope remain clear.

The city route places the ambusher beside the two-cell park entrance, the flock across a pond-side opening, and the purse beside the eastern park turn. The duet occupies the return rink. Authored placements were inspected against the tile map; normal-play/browser verification must establish how those warnings actually read on screen.

## Traffic jams

A lane may specify `jam: {stopped, moving, phase}` in seconds. Red stops the cars; green resumes the authored lane speed. Car gaps remain physically clear while stopped, while the car bodies still collide. These are traffic signals, not a promise of protected pedestrian crossings. Two phases can require a median wait.

Jam travel integrates the stop/go clock analytically, including a frame that crosses a light change. The new jam mode derives positions from absolute travel instead of accumulating float32 transforms. Existing lanes without a `jam` retain their previous movement. Optional inclusive `columns: [first, last]` confines traffic to a street segment, with three world units of off-street wrap margin at either end. Cars above/below the actual bridge deck use vertical clearance in collision checks.

## Reproducible checks

```bash
bash tools/godot.sh --headless --script res://tests/city_park_hazards.gd
```

The focused native suite passes **44 checks**: distant idle, visible harmless warning, actual attack collision, sidestep escape, safe recovery, bridge separation, moving duet formation and contact, jam timing across a phase boundary, unchanged continuous-lane formula, localized street wrapping and stopped-car collision. Jam motion runs at 30, 60 and 120 Hz and agrees with expected 16-unit travel over its seven-second cycle within 0.0001 world units.

This is deterministic mechanic evidence. It does not establish browser performance, human difficulty, attack readability on a particular screen or completion of the full campaign. Those are separate integrated acceptance checks.
