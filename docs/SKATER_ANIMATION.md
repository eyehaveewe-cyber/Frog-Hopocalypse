# Skate enemy motion contract

The skate controller runs in Godot 4.7.2 and owns translation along a closed,
authored XZ route. The child model owns pose only. There is no mocap, chase AI,
root motion, random attack, or independent animation translation.

Routes use grid `pos`, world-unit `height`, and an outgoing-segment `trick` of
`cruise`, `push`, `grind`, or `ramp`. Consecutive grid points, including the final
point back to the first, must have nonzero horizontal distance. `setup(obj,
world)` converts the points through `world.cell_position`. Height interpolates
linearly over the actual segment, so authors supply physical ramp and rail
supports. The controller adds no undocumented airborne arc. `speed` measures
horizontal world units per second.

The rider faces local -Z. `Board` and `RiderRoot` are root children. The rider
has `Body`, `Head`, `ArmL/R` shoulder pivots and `LegL/R` hip pivots. Wheels under
the board use names beginning `Wheel_` and rotate around local X. The board deck
is about 0.18 units above the actor origin. The actual truck mesh is centered at local Y 0.08 and is 0.07 units tall,
so its underside is 0.045. Rail top 0.65 therefore uses actor elevation 0.605,
placing that underside exactly on the rail. A 0.7-unit ramp uses authored heights through its
physical surface.

The push stroke animates the trailing leg while the other foot stays on the
deck. Cruising uses a smaller stroke. Grinding extends the arms with bounded
balance sway. Ramps lower the pelvis and compress the stylized legs to preserve
deck contact. Heading turns ease visually while collision follows the actual
path. Pose phase comes from traveled distance. The entire visual follows ramp pitch, so the deck and planted feet stay in the
same support plane while the torso counterleans. Wheels rotate by travel divided
by their 0.065-unit radius. Pausing or entering the map/editor stops both route
and pose because the world stops calling `step`.

`sample_at_distance` returns `position`, `segment`, normalized `progress`,
`height`, and `state`. `distance` is cumulative horizontal travel;
`segment_progress` is normalized within the current segment. The most recent
`step` records `sweeps` with `from`, `to`, and normalized frame times `t0`, `t1`.
Every route corner crossed during an ordinary tick gets its own sweep. Player
motion is interpolated to that sweep's time interval and tested in relative
coordinates with a combined 0.74-unit radius. Board origins above the frog's
0.78-unit clearance do not hit the frog, matching visible overhead clearance.
Normal plaza rails and ramps remain below this threshold and remain dangerous.

A diagnostic time jump longer than a whole circuit still computes its final
pose with modulo loop distance in bounded work. Its impact check conservatively
tests complete route occupancy rather than attempting thousands of repeated
sub-frame sweeps. That fallback can report an early impact in a huge debug skip;
ordinary physics ticks use exact per-segment relative timing. No full-map phantom
closing chord is created when a loop wraps.

Godot 4.7.2 headless loaded the controller and instantiated the actual skater
model. A direct runtime check passed one 1.0-second step versus sixty 1/60-second
steps within 0.00001 units, detected a swept contact between endpoint poses,
left the route center clear, observed wheel rotation, and advanced a 10,000-second
diagnostic jump with bounded sweep count and a finite modulo-loop pose. Those
checks ran through the real controller and procedural model, not a mathematical
substitute.

Rendered acceptance and world integration are separate checks. Source loading
and these runtime checks do not establish silhouette, deck-contact quality,
target frame rate, or player readability.

A second native pass ran the actual model for ten simulated seconds at 30, 60,
and 120 steps per second. Each run reached push, ramp and grind segments. Final
positions agreed within 0.00001 units. The maximum planted shoe-sole penetration
relative to the grip-tape plane was 0.016500 units at every rate, below the
0.025-unit inspection budget. That measurement uses the actual local transform
chain and shoe mesh bounds. Both feet are measured during ramp/grind; the planted
front foot is measured during pushing. A pushing trailing foot intentionally
leaves its support. The test also motivated moving slope pitch from the board
alone to the entire visual and correcting the wheel radius to the modeled 0.065.

## Reproduce support measurements

Run `bash tools/godot.sh --headless --script res://tests/skater_contacts.gd`.
This standalone check loads the authored Brooklyn skate plaza and its actual
procedural skaters and rail meshes. It runs every rider for 40 simulated seconds
at 30, 60 and 120 Hz, measuring transformed mesh bounds. Interior rail samples
exclude the rail-end handoff where one truck can still be supported by the
approach ramp.

The corrected 0.605-unit grind routes passed **25 checks with zero failures**.
The two rail riders produced 63/83 interior truck samples at 30 Hz, 126/165 at
60 Hz, and 251/327 at 120 Hz. Maximum rail-top to truck-underside separation
was 0.000000 at each rate. All three riders retained maximum planted sole
error 0.016500 against the actual grip-tape mesh top. Their final route positions
at 60 and 120 Hz agreed with 30 Hz within 0.00001 units. The middle rider uses
ramps rather than a grind, so it has no rail-contact samples.

The native result log for this pass is `/tmp/skater-rail-contact-proof.log`.
