# New York City street kit

Production tier, original stylized assets for the existing PS1-style Godot game. Dimensions below are proposed game units, not measurements of real vehicles. One map cell measures 1.8 units. Traffic faces +X and rotates as one assembly; wheels rotate about their local Z axis.

Taxi and sedan: 2.6 long, 1.1 wide. City bus: 4.4 long, 1.1 wide. Delivery truck: 3.5 long, 1.1 wide. Collision is a runtime proxy supplied by traffic.gd; these visual assets contain no physics bodies. All four require separate wheel pivots, readable windshield/cab proportions, bumpers and front/rear lamps. The taxi needs a roof sign and checker band. The bus needs repeated passenger windows, doors, a route display, and a contrasting lower band. The truck needs a cab, cargo body and rear roll-up door.

The city perimeter should read as New York through stepped masonry buildings, rooftop water towers, fire escapes, yellow street furniture and illuminated billboards. No claim of exact architectural or vehicle historical accuracy. Structures sit beyond map boundaries; the near edge remains open for the following camera. Existing object IDs are retained for editor/save compatibility: pillar becomes a streetlamp, tree becomes a street tree, mushroom becomes a hydrant, decoration becomes a subway entrance, emitter becomes a street utility trap.

Pass gates: save dominant proportion blockout, add assemblies and moving wheel hierarchy, add restrained small detail/materials, then render front/side/three-quarter views and inspect in the game. Source checkpoints document actual construction. Independent visual inspection and final runtime integration must be recorded after they run.
