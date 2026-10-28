# NYC Streetlife: levels 4–6

These levels combine the systems taught in the first half of the new set.
They are authored arcade neighborhoods, not geographical reconstructions.
The shared generator is `tools/create_streetlife_set.py`; late layouts live in
`tools/streetlife_set_late.py`. Existing campaign maps are preserved.

The frog moves at 4.2 world units per second, cells span 1.8 units, and its
collision radius is 0.32. Skaters move more slowly than the frog, follow visible
closed loops, and do not chase. Ramp and rail supports use the same production
contract as Brooklyn Skate Circle: ramp rise 0.70, rail top 0.65, truck underside
0.045, and rider elevation 0.605 during grinds.

## Level 4: Banked Boulevard

The level separates two timing problems. A broad arrival sidewalk lets the
player read two opposing road lanes. Crossing leads to a banked court with
western and eastern gates. A hoodie rider climbs a physical bank, then returns
through both gate approaches. The western route avoids roaches; the shorter east newspaper corner shares
space with a slow patrol. Both gates require reading the bank rider.
The choice concerns where to enter the court rather than merely which color
prop to walk past.

The central bank is a genuine pair of opposing four-unit wedges. A full-width
wall above the court approach makes one of its side gates necessary. Traffic
spacings of 13 and 14 units leave readable gaps between taxis, sedans and buses.
Rest space separates the road from the next moving threat. Water gardens stop
the court from reading as another rectangular traffic map. Independent review
found a subcell wall-hug bypass of the west rider crossing. Moving the west
return node from `[6,11]` to `[5.6,11]` closed that narrow bypass. The revised
rider keeps at least 0.543710 world units from a solid wall face or corner,
above its 0.42-unit body radius.

## Level 5: Sanitation Courts

Three wall rows expose offset gates: west, east, then west again. This makes
local refuse courts into a longer lateral journey rather than a straight run.
Dumpsters and cans mark the roach patrol pockets, while the bench and mailbox
mark waiting areas. Four slow patrols occupy distinct courts instead of
forming one overlapping lethal cluster.

The final court contains a shorter rail line. Its rider climbs actual approach
wedges, grinds east, then returns west along the northern gate approach. That
return line crosses the exit route. An earlier draft kept the return in the
south of the court; the quiet northern sidewalk could then bypass the rider
entirely. Moving the return to row 7 makes it relevant to the next gate while
retaining observation space below it. This is a route-role revision, not an
increase in enemy speed.

The level has no traffic. It tests the player's use of space and local enemy
loops between the two mixed-system maps, with a static route of 50 cell steps.

## Level 6: Block Party

Two road pairs bookend a festival court. The southern road's north sidewalk
has a narrow party gate. A rider's return line spans the court immediately
beyond it, making the first skateboard crossing visible and relevant before
the player can spread into the plaza.

Inside, three routes create separate readable rhythms. A cap rider uses the
western rail, the hoodie rider crosses the paired central banks, and the punk
rider uses a northern grind line before sweeping back through the arrival
side. They have different routes and speeds rather than one stacked circuit.
The center fountain creates a short bank-side route and a longer grind-side
route. A pizza cart and newspaper corner identify rest pockets. The player can
choose a cautious path after the required arrival crossing; that freedom is
intentional.

The final road pair remains mandatory, with a clear staging sidewalk before
the gate. The climax comes from combining familiar road, board and roach rules
in a place the player can read, rather than removing every recovery space or
maximizing enemy counts.

## Static acceptance

The late generator checks unique IDs, valid dimensions and terrain, continuous
skater segments, dry roach points, furniture clearance, whole traffic rows and
required gate connectivity. Every nominated gate region disconnects the exit
when blocked. Footprint-aware shortest routes are 30, 50 and 26 cell steps.
The amount of walking is intentionally different from the encounter count.

Static audits do not establish camera readability, live timing or human
completion difficulty. Those belong to the shared Godot traversal and browser
review pass. Authored timings remain tuning values until those checks run.

## Engine traversal evidence

The final standalone set suite completed 52 checks with zero failures. It
loaded these exact JSON maps, physically traversed their layouts, and completed
all six maps through ordinary frog input with every authored hazard active.
This includes the revised Banked Boulevard return node at `[5.6,11]`.
The complete native regression suite then passed 217 checks.

| Late map | Simulated completion | Time waiting | Traffic pairs crossed |
| --- | --- | --- | --- |
| Banked Boulevard | 15.80 s | 3.08 s | 1 |
| Sanitation Courts | 23.77 s | 0.00 s | 0 |
| Block Party | 11.00 s | 0.00 s | 2 |

These are informed automated routes, not target times for first-time players.
The driver leaves hazards running while it waits; it does not teleport or
pause the world. The late generator also retains a conservative continuous
wall-clearance audit for the revised bank rider. Its lower bound is 0.521762
world units, above the rider's 0.42-unit body radius.
