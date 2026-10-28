# Brooklyn Skate Circle

`NYC 06 · Brooklyn Skate Circle` is another regular NYC campaign map. It keeps
all five traffic maps and introduces three skateboard riders and four roaches
in a purpose-built plaza. The requested "18 tile circular area" is interpreted
as an 18-tile diameter. The circle has a nine-tile radius around cell `[12,12]`.
A 25 × 25 canvas provides water margin and quiet pedestrian staging pads to the
north and south. These pads are outside the rider area.

Run `python3 tools/create_skate_plaza.py` to rebuild only this map. The generator
is the editable layout source; the JSON also uses the ordinary editor, local
save library and import/export format.

## Player experience

Watch a rider complete a short sequence, choose a gap, then cross the next
track. The southern landing gives a clear view of the perimeter rider before
the frog enters the circle. The bank mound divides the direct path and invites
a short west/east detour. Riders crossing the return path make the center feel
occupied rather than leaving tricks isolated on a distant decorative track.
The northern half combines the short grind line with a final perimeter crossing
before the gate.

The frog retains continuous movement at 4.2 world units per second, a 0.32-unit
collider, and visual hopping. The design does not assume that the player can
jump over a skateboard, mount a rail, or climb the ramps. Skate fixtures block
the frog at ground level while the riders follow their authored feature paths.
Slow roaches remain around bins and street furniture, away from the safe start.

The floor remains open enough for improvisation. A longer rim route reduces
exposure to the central bank rider; this is an intentional choice between a
shorter crossing and a longer, more cautious walk. The player is not required
to touch every hazard or follow a hidden timing script.

## Structure selection

| Candidate | Decision | Reason |
| --- | --- | --- |
| Tiny enclosed bowl with every rider crossing one choke | Reject | It would turn the requested variety into overlapping collision envelopes with little room to observe. |
| Three disconnected skate exhibits | Reject | Tricks could look lively while never interfering with the frog. |
| Broad circle with a perimeter circuit, central bank and shorter return loop | Keep | Distinct moving silhouettes use the same plaza and create separable crossing decisions. |

## Capability and support geometry

| Element | Authoritative or authored value | Consequence |
| --- | --- | --- |
| Tile spacing | 1.8 world units from `world.gd` | The requested circle spans 32.4 world units. |
| Frog speed and radius | 4.2 units/s and 0.32 units from `actor.gd` | Fixed furniture clearance includes the full movement envelope. |
| Rider speeds | 3.4, 3.0 and 3.7 units/s, proposed content values | All remain slower than the frog on unobstructed ground. |
| Rail support | Rail top 0.65; board truck underside 0.045 | Rider root travels at height 0.605 along a grind. |
| Entry/exit wedges | 1.8 units long, rise 0.605 | Grind approaches have actual sloped support rather than floating transitions. |
| Central banks | Two 4.0-unit wedges, rise 0.70 | Matching high ends form a continuous triangular mound. |
| Circle bounds | Nine-tile radius, route nodes and full segments audited | No rider or closing route segment leaves the authored skating area. |

Ramp models face local negative Z, with the high end toward negative Z. Positive
Y rotation 270 degrees points that high end east. A rotation of 90 degrees
points it west. The central banks use those opposing rotations and share an
apex at `[12,12]`. Their outer ground ends are at approximately X 9.777778 and
14.222222. The east rail is four world units long at `[18,12]`; the crosswise
north rail is 3.6 units long at `[10.5,8]`.

Each route node records a position, height and trick. A node's trick applies to
the segment leaving it. Heights interpolate linearly to the following node,
including the final-to-first segment. No segment teleports across the circle.
All three routes begin on the ground and return continuously to their starts.

## Riders and encounter beats

| Variant | Route identity | Signature moment | Player decision |
| --- | --- | --- | --- |
| 0 | Wide perimeter loop, clockwise from the southern crossing | Climb the short east wedge, grind north on the long rail, descend and carve the back arc | Enter after the near rider clears; use the open ring to watch its return. |
| 1 | Central bank line with a southern return loop | Ride east over the paired bank apex, then sweep back through the lower plaza | Pass around either end of the bank and choose when to cross the return. |
| 2 | Smaller counter-flow loop through the northern half | Climb and grind the crosswise rail, then cut back through the central crossing area | Watch the rail exit before committing to the northern approach. |

The three visual variants are supplied by the shared street-life kit. Route
shape and speed distinguish them as well as clothing, so they remain different
encounters when seen from the gameplay camera.

## Street furniture and roaches

The map uses all eight new street prop variants: bench, trash can, dumpster,
pizza cart, mailbox, traffic cone, manhole cover and newsstand. Their placement
leaves the rider lines clear and gives rest pockets recognizable identities.
The bench marks the quieter northwest rim; bins and dumpster mark the western
roach pocket; food cart and newsstand identify the southeast rest area. Rails
and ramps are additional functional kit pieces.

Four roaches use short, deterministic local patrol circuits. Two occupy the
western refuse area, one patrols near the food-cart area, and one moves around
the northwest mailbox approach. Speeds are 1.10–1.35 units per second. None
spawns on the frog or pursues from outside the camera's view.

## Validation evidence and limits

The generator audits a dry, 26-step route using fixed-prop footprints expanded
by 0.34 world units. It checks all rider endpoints and samples every continuous
segment, including loop closure, against the dry floor and circular boundary.
It also rejects any rider segment intersecting the fixed street furniture.
Functional skate features are deliberate exceptions because they support the
riders. The footprint table matches `streetlife_specs.gd`.

The actual Godot boundary validator loaded the generated JSON without an error,
and its shared reachability check returned true. The full integration runner
then walked the dry route using the real frog controller and collision. A
separate live traversal reached `LEVEL COMPLETE!` with all three skaters and all
four roaches active, using ordinary movement inputs and brief waits for moving
gaps. It completed in 11.17 simulated seconds, including 0.20 seconds of waiting.
No player teleport, enemy pause or hazard removal was used. The current-run log
is `/tmp/streetlife-native-agent2.log`; the combined runner passed 147 checks,
including 39 street-life checks.

The automated driver reads the rider schedule before committing to each step.
Its informed completion time is evidence of a workable route, not a target for
a first-time human player. Camera readability, visual animation acceptance and
browser/device performance belong to the visual and platform integration pass.
Static or automated success does not establish difficulty or fun.
