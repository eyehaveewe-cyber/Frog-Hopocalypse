# NYC Streetlife: six-level set

Six new regular maps form a separate NYC Streetlife itinerary. They preserve the
three original maps and the six earlier NYC maps. The set moves from slow
roach patrols through readable board circuits and supported rails, then combines
those skills with traffic and offset neighborhood courts.

Run `python3 tools/create_streetlife_set.py` to rebuild only these six JSON maps.
The main recipe owns levels 01–03, `streetlife_set_late.py` owns 04–06, and
`streetlife_set_common.py` supplies the shared feature constructors and audits.
There is no randomness. These are content-authoring commands, not environment
setup commands.

## Design choice

Three structures were considered:

| Candidate | Decision | Consequence |
| --- | --- | --- |
| Six open skate circles with increasing enemy count | Reject | Reuses the prior plaza's main decision and makes variety depend on density. |
| All hazards in every level from the start | Reject | New players must read roaches, moving boards and traffic simultaneously before any clear example. |
| A neighborhood itinerary that teaches, varies and combines the kit | Keep | Each level gives the same movement rules a new spatial job and saves the mixed encounter for the finale. |

The solution promise is mixed. The player must learn to watch a moving route
before crossing it, and must find the intended passages through walls or water.
Within those constraints, crossing position and timing are open choices. A
longer quieter branch is intentional when it has a different cost from the
short route. Walking an empty outer perimeter must not erase the level's main
encounter.

This is Levelwright's project-specific design synthesis. It does not attribute
these six layouts or a universal level-design rule to a named designer.

## Capability ledger

| Measured project rule | Value | Layout consequence |
| --- | --- | --- |
| Cell pitch | 1.8 world units | All quoted route steps are grid distances, not seconds. |
| Frog speed | 4.2 world units/s | One unobstructed cell-center step takes about 0.43 s. |
| Frog radius | 0.32 world units | Clearance audits inflate actual rotated prop footprints by 0.34. |
| Frog movement | Continuous X/Z movement; hopping is cosmetic | No route requires jumping a vehicle, mounting a bank or climbing a rail. |
| Early skater speeds | 2.5–3.0 units/s | A board is readable and slower than the frog in open space. |
| Late skater speeds | 3.2–3.7 units/s | Challenge comes from route combinations and geometry, not outrunning the frog. |
| Rail top / truck underside | 0.65 / 0.045 world units | Rail routes use an actor origin of 0.605. |
| Bank support | Physical wedge, authored length and rise | Every elevated sample is checked against an actual support surface. |
| Camera | Following perspective, paused overhead inspection | Broad waiting landings precede the important decisions. |
| Recovery | Retry restarts the current map | Quiet starts allow a route to be observed before commitment. |

The scene retains its existing low-resolution PS1 presentation. New props use
shared static batching; moving actors keep their articulation. The set adds no
new control, jump, pursuit, item or checkpoint mechanic.

## Six distinct places

| Level | Intended memory and player action | Space, asset role and relief | Hazards |
| --- | --- | --- | --- |
| 01 · Stoop Patrol | Follow behind a roach through one alley, then change sides for the next. | Two offset three-cell gates join broad stoop landings. Dumpsters and bins identify refuse approaches; the mailbox and bench mark quieter waits. | Two slow roach patrols, no boards or traffic. |
| 02 · Newsstand Weave | Enter a moving perimeter, choose a side of the newsstand island, then cross the board again to leave. | A central island creates an orbital court. The west branch gives more room; the shorter east branch meets a second counter-flow loop. Newsstands mark the island ends rather than hide the riders. | Two ground-level rider loops and a side-pocket roach. |
| 03 · Ferry Railwalk | Use the east pier, walk around a bank end, then cross behind the returning rail rider. | Water separates the forecourt from the ferry gate. The only pier is broad enough to choose an end of the supported rail, while cart and benches identify the safe forecourt. | One supported grind loop and two local roach patrols. |
| 04 · Banked Boulevard | Finish the road crossing, observe a complete bank circuit, then choose a side gate. | A two-lane avenue opens into a separate bank court. Two side gates share the rider return, while fountains and a newspaper corner distinguish the branches. A wide sidewalk separates road timing from board timing. | One bank rider, one roach and two traffic lanes. |
| 05 · Sanitation Courts | Change crossing lines through refuse courts, then time the grind return. | Three offset service gates connect different courts. Dumpsters define the alley mouths; benches and mailboxes identify wider recovery pockets. This removes traffic for a different late-set rhythm. | Four local roaches and one grind rider. |
| 06 · Block Party | Cross into the party, negotiate the moving plaza, rest near the fountain, then cross home. | Traffic bookends an interlocking skate court. A narrow arrival passage makes the first board line relevant. Fountain and support geometry create a short east bank route and a longer west grind-side route. | Three distinct riders, three roaches and four traffic lanes. |

All ten street/skate prop variants are used across the set. Their physical roles
stay consistent: furniture is a ground obstacle when solid; rails and banks
support riders and block the ground-bound frog; manholes are flush dressing.
The player can recognize a waiting pocket or obstacle without reading a new
rule in each map.

## Revision from the first draft

The initial Stoop Patrol and Newsstand Weave both used offset horizontal gates.
Although their hazards differed, they asked for too similar a spatial response.
Newsstand Weave was rebuilt around a central island and a moving outer perimeter.
It now offers a west/east route choice inside the encounter and requires an
entry and exit crossing. Its static clearance route changed from 28 to 22 steps.
This is a topology revision, not a claim that fewer steps are inherently better.

The early set then has three different organizing relationships: an offset
alley journey, an orbit around an island, and a water-separated pier. The late
set combines these skills through an avenue/court transition, offset service
courts and a traffic-bookended gathering.

## Static evidence

| Level | Dimensions | Clearance route steps | Roaches | Riders | Traffic lanes |
| --- | --- | --- | --- | --- | --- |
| Stoop Patrol | 17 × 17 | 24 | 2 | 0 | 0 |
| Newsstand Weave | 21 × 19 | 22 | 1 | 2 | 0 |
| Ferry Railwalk | 23 × 21 | 32 | 2 | 1 | 0 |
| Banked Boulevard | 25 × 23 | 30 | 1 | 1 | 2 |
| Sanitation Courts | 25 × 25 | 50 | 4 | 1 | 0 |
| Block Party | 25 × 25 | 26 | 3 | 3 | 4 |

The generator passed all six static audits. It verifies dimensions, dry starts
and exits, IDs, footprint-aware route clearance, mandatory named passages,
continuous dry rider loops, ordinary furniture avoidance, and traffic-row
geometry. Blocking a declared required passage disconnects start from exit.
That proves the passage's topological role, not that a moving enemy always
occupies it.

For every elevated rider sample, the auditor finds a matching ramp surface or
rail contact. It also compares its ground footprint table with the actual
`streetlife_specs.gd` definitions so a future collider change fails visibly.

Static reachability and support checks cannot establish a live winning route,
actual controller clearance, camera readability, timing comfort or fun. The
native and browser integration results belong in
[the set validation record](STREETLIFE_SET_VALIDATION.md). First-time human
playthroughs remain the test of pacing and difficulty.

## Inspected views

[Newsstand Weave courtyard](images/streetlife-set/newsstand-weave.png) shows the
wider west route and shorter east route around the central island.
[Block Party](images/streetlife-set/block-party.png) shows the separated traffic
approach and moving skate court. Final desktop and landscape phone captures for
all six maps were inspected; the full capture set is generated by
`tools/streetlife_set_browser.cjs`.
