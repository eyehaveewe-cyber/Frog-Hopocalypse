# Moves When You Move

Published as [Hopán v48](https://hopan.fiiendward.chatgpt.site).
[Publication and v47 rollback](YOUR_MOVE_PUBLICATION.json).

A separate five-stage Tile Hop set. Clear Not as Hard as It Looks to expose both
Tile Hop sets, then choose **Moves When You Move → +**. The new set does not
replace the original five Tile Hop maps, Cramerton or the existing Bonus entries.
All five maps use the existing `move_with_me` rule. An accepted hop spends one
hazard beat, including a long hop. Stopping does not advance hazards; blocked
hops do not spend beats. Safe sideways movement changes the next crossing.

The user's requested reward is an **hourglass-themed pyramid hat**. Clearing all
five distinct stages unlocks and equips it. Entering the set, replaying one stage
or clearing only four does not unlock it. Hat cycles through earned hats. Progress
and equipped headwear persist in the existing profile and browser backup.

## Levelwright design

The player problem is to predict the next hazard step while choosing where to
land. Safe banks and turn pockets provide room to change the phase by moving.
The fifth stage combines dense traffic directions, paired lanes and narrow
medians. Its difficulty is an intended hard finale, not a measured human rating.

Two structures were considered. A succession of straight road strips makes each
next beat easy to compare but repeats the same solution. Connected courts and
switchbacks ask players to carry the same rule through changed approach angles,
pickup detours and directional hazards. The set uses the latter, reserving the
long paired-lane road for the finale. This is Levelwright synthesis applied to
this game's measured cardinal hops and swept collision system, not an external
consultant review or a claim of user-authored layouts.

| Stage | Player decision | Rules and content | Verified fresh route |
| --- | --- | --- | --- |
| One Step Ahead | Choose a side step or a two-tile crossing before moving a car | Free hops; offset east/west and north/south roads | 42 hops, 2 long |
| Needle Clock | Cross the firing row on the right move; use the outer rail bank | Free hops; dart and cheese courts, spike rail | 44 hops |
| Shard Switchyard | Collect fragments while changing the patrol phase, then spend the reserve on a canal | Six fragments, two canal gates, patrol roads and a rail | 74 hops, 2 long |
| Stillwater Circuit | Land where a log moves next, then carry seeds to water/traffic crossings | Jungle waterway, two seeds, side channel and rail | 62 hops, 2 long |
| Rush Hourglass | Plan a landing across paired lanes; cross perpendicular patrol roads and a final double road | Ten short hops recharge a long hop; fourteen vehicles | 92 hops |

Every level has one late checkpoint. It restores the real resource snapshot and
resets hazards through the existing retry behavior. Each suffix was independently
routed and replayed from that reset phase. No checkpoint was added to older maps.
The finale is completable without spending a long hop; a charged hop is a tactical
option rather than an emergency power-up that the solution silently requires.

Map dimensions range from 17×25 to 25×35. The camera keeps the existing perspective
and draw-distance behavior. Signs describe actions and choices at the relevant
banks. No collision, movement timing, hazard speed rules or audio changed.

## Implementation and verification

`tools/design_your_move_set.py` deterministically writes the five new maps plus
fresh and checkpoint route fixtures. `tools/your_move_traffic.py` predicts cardinal
car beats and swept collisions to find legal traffic approaches. That predictor
only helps construct witnesses. The acceptance runner makes ordinary movement
requests and advances the actual Godot world, including projectiles, spike balls,
logs, traffic, pickups, checkpoints and finish signals. It has no teleport,
invincibility, state rewind or collision edits.

Run in isolated test storage:

```sh
XDG_DATA_HOME=/tmp/hopan-yourmove-check bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/your_move_set.gd
```

The focused run passes 61 checks. Both fresh and checkpoint routes complete for
all five maps. Idle snapshots before and during routes verify freeze behavior.
Reward gating, profile reload, old campaign clears, editor-save preservation,
set restart behavior, single-hat visibility and full hat cycling are checked.
The 25 existing set-menu and 15 skin checks pass and cover the previous result behavior, Baby Mode
reward and purple skin.

The hat is original procedural low-poly art. Four quiet cyan glass panels and
opaque gold edges enclose a small hourglass, with amber sand chambers. The frame
sits above the frog's eyes. It uses no blinking effects or external assets and
adds no collision. It follows the existing hat socket and frog motion.

Browser evidence and screenshots live in [previews/your-move](previews/your-move/).
Legacy browser profiles without the new field migrate without losing previous
sets, skin or hats. Browser tests use actual menu, keyboard and touch input;
completed-profile seeding is used only to inspect the earned hat and persistence.
The native five-stage completion verifies earning it. Chromium phone emulation
is not a physical iPhone, Safari or Edge test. Human difficulty and pacing
playtesting remains necessary.

Shared-site publishing preserves every current RiverSim and unrelated hosted
file byte-for-byte, with a new baseline check before preparing the final archive.

Production release bytes start the new set through real keyboard menu input.
The release screenshot shows One Step Ahead, the correct 1/5 set header and
the earned hourglass hat. No debug probe or browser errors are present. All five
new overhead maps and the hat were visually inspected. Sites confirmed v48
publication succeeded. All 14 current RiverSim 0.4.12 files and four unrelated
hosted files match the v47 baseline, including in the final archive. A rollback
to v47 is recorded; inspect intervening shared content before using it.
