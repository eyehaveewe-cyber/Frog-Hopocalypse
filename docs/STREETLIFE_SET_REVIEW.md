# NYC Streetlife set review

This is an independent review of six new maps, separate from the original NYC
maps and Brooklyn Skate Circle. The review compares the authored intention,
actual coordinates, static routes and, when available, rendered game views.
It does not claim first-time human playtesting.

## Set progression

The set has a useful sequence of different spatial decisions. Stoop Patrol
starts with two slow insect crossings and no skateboard or traffic pressure.
Newsstand Weave makes the player enter and leave a broad outer rider circuit,
then choose the roomier west walk or the shorter east route with a second loop. Ferry Railwalk introduces a supported grind
line on the only broad pier across a river. Banked Boulevard separates an
avenue crossing from a later bank-side decision. Sanitation Courts requires
longer lateral movement through three differently placed court gates. Block
Party combines traffic bookends with a central choice around a fountain and
several skate routes, with safe space between systems.

The maps use the new assets as readable physical features. Newsstands identify
passage edges, refuse furniture identifies roach pockets, and ramps/rails
actually constrain the frog's ground route while supporting the elevated rider.
The set does not require the frog to climb ramps or jump over boards.

## Static findings

| Map | Inspected coordinates and behavior | Judgment |
| --- | --- | --- |
| 01 Stoop Patrol | Mandatory south gate X3–5 at row10 and north gate X11–13 at row5. Slow lateral roaches cover their corresponding approach rows11 and6. Broad landings separate the two reads. | Keep. A focused first lesson. |
| 02 Newsstand Weave | A central island X7–12/rows7–11 separates the wider west route from the shorter east route. The outer rider follows X5–15/rows4–14, crossing the required south entrance and north exit. A second rider occupies only the east choice. | Keep. A genuine route-cost choice replaces the first draft's repeated offset-gate structure. |
| 03 Ferry Railwalk | Water rows8–12 leaves only pier X14–19. The horizontal rail at row10 has matching entry/exit banks; its return loop occupies the pier rather than a detached display island. | Keep. The support geometry and water jointly define the route. |
| 04 Banked Boulevard | Two avenue rows15–16 precede a bank court. The divider at row10 has west gates6–7 and east gates17–18; both reach a rider circuit. | Keep after the west return-node revision described below. |
| 05 Sanitation Courts | Gate positions switch from X5–7 at row18 to X17–19 at row12 and X6–8 at row6. Water and refuse furniture create distinct courts rather than a single straight corridor. | Keep. Longer traversal follows a deliberate side-switching purpose. |
| 06 Block Party | Two-lane traffic bands at rows19–20 and5–6 bookend the party. The narrow row18 arrival gate X12–13 feeds toward the row17 rider segment spanning X12–17. A central fountain divides bank-side and grind-side choices. | Keep. Combined pressure has clear separators and rest areas. |

A separate grid audit removed all cells touched by any authored roach/skater
patrol envelope, using combined frog/enemy radii of 0.67 and 0.74 world units.
No patrol-free grid route remained in any of the six maps. This is evidence
against an obvious grid perimeter bypass; it is not proof about every continuous
subcell route or moving hazard phase.

The final clearance-aware shortest static route lengths are 24, 22, 32, 30,
50 and 26 cell steps. These are layout measurements, not player completion
times. Newsstand Weave has a different central-island topology from its first
draft; its two sides have a real distance/rider-pressure tradeoff.

## Critique and revision

In the first Banked Boulevard draft, the west rider edge from `[6,11]` to
`[7,8]` crosses row10 at X6.333. The two-cell gate allows the frog center near
X5.68 after wall clearance. A player may therefore hug the west wall, enter
outside the rider polygon, and continue north without crossing that rider.
The traffic challenge still remains, so this does not break progression.

The author moved the west return node from `[6,11]` to `[5.6,11]`, shifting
the row10 crossing to about X6.067 and covering that wall-hug route with the
combined rider/frog envelope. The rider still clears the wall by 0.543710
world units, beyond its 0.42-unit body radius. The west remains roach-free,
while the east has a nearby refuse patrol; both now preserve the board timing
choice. A grid-only blocked patrol audit would miss the original continuous
route.

A separate author revision moved Sanitation Courts' returning rider from the
southern court to row7, across the northern exit approach. This gives its grind
line a role in the winning route instead of leaving it as a detached display.

## Engine and rendered evidence

The final native run completed 217 checks with zero failures, including 52
checks for this set. All six maps reached the exit through ordinary frog input
with traffic, skaters and roaches active. The controller did not teleport the
frog or stop hazards during traversal. Recorded informed-driver times were
14.73, 9.25, 13.58, 15.80, 23.77 and 11.00 simulated seconds. Waiting time is a
property of those chosen routes and phases, not a human difficulty target.

The progression checks exercised actual next-level callbacks for levels1–5,
completion and replay at level6, and separation from the older campaign.
The measured native log is `/tmp/streetlife-set-full-final.log`.

All six initial desktop gameplay and overhead views and the finale's 844×390
phone view were inspected. Passage openings, water boundaries, short walls,
street furniture and enemy silhouettes were readable. The final island version
of level2 was then re-inspected in both gameplay and overview. Its wider west
choice and second east rider are visible, while its outer circuit still crosses
the entrance and exit.

The final refreshed level4/5 gameplay and overview views were also inspected.
The bank court still has readable gates after its small route revision, and the
Sanitation Courts' northern return remains visible in the same space as the
exit approach. The finale's refreshed 844×390 phone view keeps the frog,
upcoming traffic pair, party entrance and three rider silhouettes visible.
No remaining access, composition or immediate readability blocker was observed.

The final browser sequence completed 20 checks with zero failures and no
JavaScript or Godot runtime errors. It loaded all six maps through actual menu
input, froze their encounters in map view, exported the final map and launched
the finale in the phone viewport. Evidence is
`/tmp/streetlife-set-browser-final.log` and the current files
`build/test-results/streetlife-set/level-N-gameplay.png`,
`level-N-overview.png` for N1–6, and `level-6-mobile.png`.

## Acceptance

The six-level set is accepted for this implementation. The set uses the new
assets in different spatial roles, introduces systems before combining them,
and preserves intentional crossing choices. The revised level2, level4 and
level5 resolve repetition, a narrow unintended bypass and a detached hazard
respectively. All authored winning paths have been demonstrated with live
hazards, and all six game views were inspected.

Rendered inspection establishes visible composition and readability in the
captured views. Automated informed routes establish available solutions, not
first-time human difficulty or sustained real-device performance. Those remain
future playtesting concerns, not evidence fabricated by this review.
