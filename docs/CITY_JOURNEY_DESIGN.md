# City Journey: city blocks, Central Park and Skate Escape

This implements the user's requested large city trip followed by a skateboard level. It adds two levels to the same game and leaves the original 33 level files intact. The first journey is immediately available; clearing it unlocks Skate Escape.

The user rated the previous NYC revision only 1.6/10 and described Baby Mode as several times harder. This design therefore adds spatial commitments and new movement interactions instead of presenting another increase in traffic speed as a difficulty solution. Human difficulty remains uncalibrated; automated completion does not establish fifteen attempts or a 7/10 rating.

## Chosen structure

Three structures were considered: a broad street grid with free routes, a sequence of disconnected encounter rooms, and one connected trip around city blocks. The connected trip was selected because it makes the requested up/across/down movement a place the player can understand. The free grid allowed a direct start-to-exit shortcut that omitted the park; separate rooms lost the city-block experience.

`City Journey 01 · Blocks, Bridge & Central Park` is **49 × 59 cells**, using the existing **1.8 world-unit cell**. Its map footprint is 88.2 × 106.2 world units, with **971 open cells**. These are source geometry measurements, not a real-world scale claim. The street and park layout is an original illustrative city, not a geographic reconstruction of Central Park.

| Section | Player decision and visible consequence |
| --- | --- |
| Westside jam | Two locally bounded streets stop and resume on different phases. The frog can choose a gap and cross while stopped, but a red signal does not guarantee a protected pedestrian phase. |
| Delivery block | Two roach loops occupy different sidewalk lanes. The player repositions before taking the right turn toward the bridge. |
| Overpass | A real raised deck crosses above two moving traffic lanes. Cars occupy the ground; a skater occupies the deck. Ramp, side guards and rider height correspond. |
| Alley and park entrance | A narrow bush-side approach introduces the visible ambusher wind-up. The next checkpoint prevents repeatedly replaying the whole westside on a park mistake. |
| Central Park | Pond edges create alternating openings. Skateboard loops cross the usable ground; pigeon and purse attacks have fixed directions and warnings. Choosing a line and waiting for an attack to finish matter more than running straight north. |
| Eastside and rink | The route turns south onto a wider promenade. Ice retains movement, while a skating duet occupies the rink center. The camera looks toward travel to improve the downward view. |
| Return streets | Wider approaches and slower, more widely spaced vehicles make the return easier than the westside. The finish unlocks the skateboard level. |

Browser overview inspection showed that the initial park floor inherited gray city concrete and read as a paved plaza. An explicit `city_journey.parks` rectangle now identifies the Central Park lawn area `[5,5,43,17]`; the renderer applies grass only to its floor tiles, preserving paths, ponds, hazards and collision.

There are five checkpoints, before/after the bridge, at the park entrance, before the southward return, and after the rink. Local traffic segments wrap outside their lane ends; city blocks prevent those streets joining the outbound and return sidewalks into a park-skipping shortcut.

## Skate Escape

`City Journey 02 · Skate Escape` is **37 × 43 cells**, with **453 open cells**. Its central verb is retaining enough rolling speed to use ramps, then braking or steering into the next approach. The frog visibly rides a board. Three barriers require actual elevated traversal; the level does not simply disable wall collision.

| Feature | Takeoff / lip / landing, in grid coordinates | Purpose |
| --- | --- | --- |
| First ramp | `[9,35]` → `[9,33]` → `[9,29]` | Establish a straight run-up and a full-width barrier. |
| East ramp | `[23,24]` → `[25,24]` → `[29,24]` | Require a right turn, approach alignment, and braking after landing. |
| North ramp | `[30,14]` → `[30,12]` → `[30,8]` | Combine the established run-up with a skater's landing-court circuit. |
| West grind | `[5,28]` → `[5,24]` | An optional straight rail route through the first court. |
| North grind | `[29,21]` → `[29,16]` | An alternate approach line leading toward the final run-up. |

Ramps rise 0.8 world units; rails are 0.65 units high. These are authored gameplay dimensions. The actual controller and continuous traversal tests must verify the resulting jumps rather than relying on a ballistic estimate alone. Checkpoints follow each required jump. Other park users have closed routes that cross approaches without camping on the center of a landing.

Controls remain arrows/WASD for movement. In the new traversal system, Space ollies and Shift brakes. Rail entry follows its direction from an endpoint. Player instructions appear at each relevant approach. Existing ordinary levels retain their movement behavior.

## Source and verification boundaries

Run `python3 tools/build_city_journey.py` to reproduce both maps. The generator has no random seed or external asset dependency and writes only the two new JSON files. Every map includes a `journey_route` waypoint list for reproducible traversal acceptance. Those waypoints are test/design data, not an autoplay player aid.

Levelwright's foundations and scale/production references informed the separation of route topology, physical controller checks and visual checks. The inspected existing controller uses 4.2 world units per second for ordinary movement and a 0.32-unit collider radius. Source counts and topology are not evidence of frame rate, human difficulty, successful jumps or readable camera framing. Runtime and browser results belong in the release evidence, including any unresolved limitation.
