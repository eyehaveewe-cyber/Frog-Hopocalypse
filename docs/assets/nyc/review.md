# Independent NYC review

Review pass 7 inspected the runtime sources and actual Chromium/Godot screenshots on 2026-10-27. This is a project-specific judgment using Modelwright's construction/inspection gates and Levelwright's readability, recovery and layered-validation criteria. No historical accuracy is claimed.

## Inspected evidence

- `build/test-results/nyc-midtown-gameplay.png`, desktop 1280 × 800.
- `build/test-results/nyc-midtown-overview.png`, full-resolution paused map.
- `build/test-results/nyc-midtown-mobile.png`, landscape 844 × 390.
- `game/scripts/traffic.gd`, `nyc_art.gd`, `city_streets.gd`, `world.gd` and `level_data.gd`.

At the initial review checkpoint, gallery front/side/three-quarter captures were pending. The later canonical-view and rework sections record their inspection. Static pictures cannot establish wheel motion, traffic timing, frame rate, or player difficulty.

## Accepted observations

The four traffic families read distinctly at the actual gameplay scale. Yellow taxis have readable roof signs and checker bands; buses are longer, with repeated glazing and transit stripes; delivery trucks have a tall separated cargo box; sedans have a lower cabin. The broad sidewalks and dark asphalt make the nearest crossing legible, and the frog remains visible against the paving. No tall foreground building obscures the player.

The overview shows four separate avenue pairs with quiet medians between them. Divider openings alternate across the width, so the final map asks for lateral repositioning as well as timing. Crosswalk strips and tactile paving identify useful approach lines without blocking player choice. The landscape phone frame still presents the first crossing and several deeper traffic bands without hiding the frog under the HUD.

Code inspection finds the relative swept collision appropriate for straight X-axis motion, and seam copies avoid a road-wide phantom impact on loop wrap. Simulation is gated before traffic steps during pause/map/results/editing. Vehicle bodies merge by material and world batching excludes the whole moving traffic root, preserving wheel pivots.

## Rework requested

**Road approach context.** The initial overview shows taxis and buses driving over ocean outside the perimeter and passing through side walls. This is conspicuous in the same view intended to showcase the traffic. A NYC asphalt/city underlay with open road mouths, or screened/hidden vehicle approaches, would connect the moving ensemble to a believable street. Keep authored fountain/water tiles inside the map distinct.

**Theme switching consistency.** The editor can change a NYC map's theme while preserving traffic. Current surface selection gives road tiles grass/moss in another theme. Consider preserving asphalt for all road tiles, or explicitly constraining traffic to the NYC theme. The five requested maps are unaffected because they retain `nyc`.

## Gates still open

Close-up multi-view vehicle inspection and a post-rework city overview are required before approving the remaining visual ledger gates. Wheel rotation must be verified through runtime values or frame comparison, rather than inferred from symmetric tires. Browser checks can establish runtime behavior, while real-device performance and first-time human difficulty remain separate playtests.

## Canonical model views

All twelve files in `previews/` were rendered by the repeatable Godot Web gallery and inspected individually: `taxi_front.png`, `taxi_side.png`, `taxi_threequarter.png`, the same three suffixes for `sedan`, `bus`, and `truck`. `previews/capture.json` records the render viewport, renderer and zero captured errors.

Taxi, sedan and bus pass the production-tier visual gate for this game's deliberately boxy style. Front views show complete glazing, lamps, bumpers and wheel stance. Side/three-quarter views show distinct cabin/body proportions, door/window assemblies, wheel spokes and model-specific details. Taxi roof signs/checker bands and bus doors, route pixels and transit stripes remain readable. The geometry is simple by design and suitable to the game's small on-screen scale; no realism claim is made.

Truck proportions and major cab/cargo assemblies are present, but `truck_side.png` reveals horizontal depth-fighting streaks along the cargo box's lower edge. Source inspection confirms coplanar body/cargo side faces: both widths are 1.08 and their height ranges overlap. Reject that unit until the surfaces are separated. A proposed small correction is a 1.10-wide cargo box, consistent with the declared 1.1 visual/collision width. Re-render the three truck views and verify the lower cargo edge is stable before closing this issue.

## Rework inspection and final acceptance

The corrected truck front, side and three-quarter images were recaptured and inspected. The lower cargo edge is now clean in `previews/truck_side.png`; the horizontal depth-fighting streaks are gone. `previews/truck_threequarter.png` confirms the adjusted cargo shell and inset panel remain connected and readable. The native source checkpoint is `checkpoints/07_truck_coplanar_rework.gd.txt`. This closes the rejected cargo construction unit.

Refreshed desktop gameplay, overhead and landscape-phone images were inspected after the road-context revision. The retained copies are `tests/nyc-midtown-gameplay.png`, `tests/nyc-midtown-overview.png` and `tests/nyc-midtown-mobile.png`. Asphalt approaches now extend into covered lane mouths; vehicles remain visibly on the road rather than floating over the water backdrop. Perimeter walls no longer visually obstruct road entrances. The authored fountain water and safe median structure remain clear. This closes the approach-context issue. Road surfaces also retain asphalt when changing the editor theme.

The actual wheel-motion measurement in `tests/native-integration.log` reports a 0.100-second step changing the first taxi wheel's local Z angle from 0.000000 to -1.310345 radians. The same run validates four named pivots on every simulated vehicle, 105 total native checks, and complete live traversal of all five maps with traffic and AI active. The retained browser log records 11 NYC checks and zero JavaScript/Godot errors, including opposing movement, pause, retry, editor export and a landscape phone viewport. The export log records the actual Web/Windows/debug builds.

The package passes the applicable production-tier gates for Hopan's deliberately boxy PS1 art direction. It contains editable procedural source, separate construction checkpoints, all twelve canonical renders, independent critique, meaningful rework, native motion/collision evidence and in-game visual evidence. No remaining critical model, integration or readability omission was found in the inspected scope. This approval does not establish Windows execution, real iPhone/Safari performance, sustained frame-rate targets, or first-time human difficulty.
