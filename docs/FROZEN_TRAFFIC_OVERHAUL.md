# Frozen Blocks: mandatory traffic crossings

The user's playtest found the former ice district too easy. It allowed a perimeter route around the moving hazards. The earlier automated success demonstrated that escape route rather than the intended challenge.

The new layout retains the map scale but changes its topology: four ice rooms connect through a five-cell spine. Water closes both sides of every room. Each room has eight ice skaters in two overlapping square circuits, with both directions crossing the full room width. Across the level there are 32 ice skaters and 12 roaches. Roaches occupy entrance braking areas, exits and edge waiting positions. Two checkpoint flags preserve runs spanning multiple rooms.

Ice skaters reuse the existing human rig with visible skate blades and hidden boards; they retain authoritative swept route collision. The outside patrol endpoints extend toward the ice edges so their collision envelopes cover the fractional-cell margins as well as tile centers. The frog still slides and can brake. The traffic is not frozen while the player waits.

Acceptance checks prove that removing any one of the four traffic gates disconnects start from exit, and that four skaters traverse each full-width gate. A separate read-only route sampler finds timing windows through all 16 individual traffic lines. Those local windows exclude roaches and do not prove a full uninterrupted controller playthrough. Existing skater contacts pass 25 checks; both new map/schema and browser rendering are checked.

The browser test uses actual menu selection and ordinary input, records the 32 rendered skaters, and tests that a straight rush fails against active hazards. Current human difficulty and complete-level success remain playtest gates. No 15-attempt or 7/10 claim is made. The old full-route script now follows the new central geometry rather than the removed perimeter; its old successful Frozen Blocks record is historical.

Run `python 3 tools/check_frozen_traffic.py` for the no-bypass and local window checks. Evidence is in `docs/frozen-traffic-evidence/`.
