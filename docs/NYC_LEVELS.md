# New York City regular maps

Five authored NYC maps follow the three original maps in the regular campaign.
The fifth NYC map is the requested traffic centerpiece. These are arcade
interpretations of city districts, not geographical reconstructions.

`python3 tools/create_nyc_maps.py` rebuilds only the five `nyc_*.json` files,
then checks terrain, solid-object placement, safe start/exit positions, lane
geometry, available vehicle gaps and route connectivity. The generator is the
editable layout source. The JSON remains usable by the ordinary level editor,
save library and import/export flow.

## Capability and layout contract

| Constraint | Value and provenance | Design consequence |
| --- | --- | --- |
| Cell spacing | 1.8 world units, `world.gd` | Roads are whole grid rows. |
| Frog movement | 4.2 units/s, `actor.gd` | One lane-center step takes about 0.43 s before interruptions. |
| Frog radius | 0.32 units, `actor.gd` | A one-cell passage leaves 1.16 units beyond the frog diameter. |
| Movement | Continuous cardinal/diagonal steering; hopping is visual | No layout assumes jumping over traffic, walls or water. |
| Camera | Following perspective during play; paused overhead map | Safe plazas let players inspect and choose a crossing line. |
| Vehicle lengths | Taxi/sedan 2.6, bus 4.4, truck 3.5 world units | Long vehicles have wider center spacing or lower speed. |
| Vehicle width | Approximately 1.1 units, kit/runtime contract | Gap audit includes the frog's full 0.64-unit diameter. |
| Traffic | Horizontal, deterministic, opposite directions by pair | No surprise turning or random speed changes. |
| Recovery | Immediate retry from the map start | Every pair has a safe median; no unbroken three-lane crossing. |

All roads extend across the interior width and end at the boundary. Every road
row separates the start from the exit, so walking around an avenue cannot
remove the traffic challenge. Crosswalk columns are marked at the west, center
and east approach positions. Crosswalk markings identify routes; they do not
promise that moving cars will stop for the frog.

## Structure choice

Three structures were considered during design:

| Candidate | Decision | Reason |
| --- | --- | --- |
| One long eight-lane highway | Reject | Too little recovery and poor visibility from the following camera. |
| Free city grid with traffic avoidable in alleys | Reject | A safe perimeter route could erase the requested traffic centerpiece. |
| Avenue pairs separated by distinct park, waterfront and plaza routes | Keep | Teaches traffic in stages, preserves regular maze navigation, and provides places to watch the next gap. |

The chosen solution promises expression in *where and when* to cross each
avenue. The mandatory insight is that a safe median is a useful planning stop.
Side routes and alternate crossing positions are intentional. No particular
frame-perfect timing sequence is required by the layout.

## The five maps

| Map | Purpose and signature action | Structure and relief | Traffic |
| --- | --- | --- | --- |
| NYC 01 · Central Park | Walk around the pond, then learn to wait for one taxi lane. | A pond splits the southern approach into two banks; a broad north garden leads to the visible gate. | 1 lane, speed 2.6, center spacing 13.5. |
| NYC 02 · Brownstone Blocks | Choose a stoop alley, cross opposing traffic, then weave through two north-block openings. | Three-cell stoop masses create lateral choices below the road; offset two-cell block passages prevent a straight finish. | 2 lanes, speeds 3.0–3.1, spacing 12.5–13.5. |
| NYC 03 · East River Piers | Cross a service road, choose either bank of a large basin, then read a bus lane. | Two avenue pairs bracket a waterfront detour. The water basin changes the useful crossing position for the upper avenue. | 4 lanes, speeds 3.2–3.8, spacing 12.5–14.0. |
| NYC 04 · Broadway After Dark | Choose crossing positions between three differently paced avenues. | Wide theater plazas, two fountain pools and open median gates invite movement along the avenue before committing. | 6 lanes, speeds 3.3–4.4, spacing 11.5–13.0. |
| NYC 05 · Midtown Rush Hour | Read a wide field of mixed traffic, change crossing lines on each median, and thread the final fountain approach. | Four avenue pairs alternate with two-cell-deep medians. Flank gates, a central gate, then flank gates prevent one straight sprint. | 8 lanes, speeds 3.2–5.3, spacing 9.5–11.5. |

Midtown's traffic includes yellow taxis, sedans, buses and delivery trucks,
moving simultaneously in both directions. Smaller taxi/sedan streams provide
the faster lanes; longer buses occupy slower lanes with larger gaps. Its
spectacle comes from the number of moving, recognizably different vehicles and
the surrounding city kit. Density does not require removing the player's
recovery spaces.

Midtown's north-to-south bands:

```text
exit / twin fountain approach
wide north sidewalk
westbound bus / eastbound fast taxi
safe median: west or east passage
westbound mixed / eastbound taxi
safe median: central passage
westbound bus and truck / eastbound mixed
safe median: west or east passage
westbound bus / eastbound taxi and delivery
wide south sidewalk / start
```

## Spatial critique and revision

The first Midtown blockout left a common open column through all three median
dividers. Its shortest route could hold one horizontal position through every
avenue, undermining the changing-crossing-line purpose. The revised dividers
extend to both interior edges and use alternating flank/center openings. The
shortest grid route increased from 34 to 46 cells while preserving two-cell
openings and safe rows for lateral travel. Brownstone and waterfront divider
edges were also closed to preserve their intended route decisions.

## Evidence and limits

The generator's static audit passed for all five maps. Shortest dry routes with
traffic treated as traversable terrain are 20, 30, 34, 30 and 46 cell steps.
Blocking any one traffic row removes start-to-exit reachability in every map.
There are no three consecutive road rows, solid props on roads, unsafe
start/exit tiles, or duplicate object IDs.

The gap audit checks the longest vehicle named in each lane against its speed
and center spacing. It proves a nonzero, individually usable single-lane gap,
not that two independently phased lanes always admit an immediate crossing.
Waiting and choosing crossing position are part of the intended challenge.

`game/tests/nyc_routes.gd` then completed 15 checks with zero failures in the
actual Godot runtime. All five maps reached the exit with traffic and critter
AI active, driven by ordinary controller input. No route teleports or hazard
pauses were used. The runner chooses sidewalks, forecasts a clear interval for
an entire avenue pair, waits at a safe cell, then crosses. It also waits before
the short unavoidable brownstone patrol corridor.

| Map | Simulated completion time | Time waiting for a clear interval |
| --- | --- | --- |
| Central Park | 8.42 s | 0.00 s |
| Brownstone Blocks | 15.00 s | 2.28 s |
| East River Piers | 17.33 s | 2.92 s |
| Broadway After Dark | 15.75 s | 3.03 s |
| Midtown Rush Hour | 22.05 s | 2.52 s |

These are automated, informed routes rather than first-time human completion
targets. Physical success establishes available routes and usable timing gaps.
It does not establish camera readability, target-device performance or fun.
Real-device and first-time human playthroughs remain necessary for a final
difficulty judgment.
