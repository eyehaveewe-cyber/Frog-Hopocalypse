# Independent NYC streetlife review

Review pass 7 used Modelwright's actual construction/render gates and Levelwright's spatial readability criteria on 2026-10-27. It inspected the fifteen browser-rendered canonical views under `previews/`, the actual Brooklyn Skate Circle desktop gameplay/overview/editor and landscape-phone frames, and the procedural source/controller contracts.

## Scope and accepted observations

The segmented roach has a clear head/thorax/abdomen, paired wing covers, six independently named legs and long antennae. Its low body is distinct from the humanoid skaters in the actual game frame. The cap-and-stripe, teal hood, and purple vest/mohawk riders have different head silhouettes and clothing structures. Front/side/three-quarter views show complete boards, four wheels, separate torso/head/shoulder/hip pivots, shoes, hands and basic facial features. Their deliberately boxy geometry matches the established game style.

The ten props are distinct in `props_threequarter.png`: slatted bench, open trash can, lidded dumpster, striped pizza cart, rounded mailbox, cone, manhole, newsstand, raised rail and wedge ramp. The front/side prop sheets overlap rows, so they provide supplementary silhouette evidence; the quarter sheet and source assembly review establish the complete inventory. The gallery is a construction view, not an animation proof.

The actual overhead scene shows the eighteen-tile circular skating floor, safe arrival/exit stems, three distinct skating routes and perimeter street furniture. The following-camera and landscape-phone frames keep the frog visible and separate the low roaches from upright riders. Ramps and rails remain identifiable from the overhead view. Static/footprint validation and live traversal results are separate from the visual judgment.

## Rework requested at the first inspection

1. **Rail contact contract.** The board Truck mesh center is y=.08 with height=.07, making its underside .045. The brief and authored rail route use .08 as if it were the underside. At rail top .65 and actor elevation .57, the truck underside is .615, penetrating the rail by .035. Use an actual underside measurement and align the rail-origin elevation, or revise the geometry. The shoe/deck penetration measurement does not test this separate contact.
2. **Floating wing seam.** `roach_side.png` shows a small gap below the long black wing seam. The seam's bottom is .3465, above the centerline of the paired offset ellipsoids, approximately .324. Lowering the seam onto the shells/abdomen, or filling the inner shell bridge, will attach it visibly.
3. **Plaza guidance.** The traffic-free plaza currently displays a generic NYC message about traffic lanes/cars. Provide skating/roach guidance so the instruction matches the encounter the player sees.

## Evidence limits

Native/controller logs can prove named pivots, deterministic movement, contact bounds and collision behavior. Static gallery images cannot prove animated skating or a six-leg gait. Browser movement checks can establish running actors and pause behavior. None of these establishes real iPhone/Safari frame rate or first-time human difficulty.

## Rework inspection and acceptance

The recaptured roach front, side and three-quarter views were inspected. The wing seam now rests on the shell; its visible air gap is gone. Antenna bars now share actual endpoints at the elbow, removing the small detached-tip appearance. The revised front-facing `props_threequarter.png` exposes the pizza counter/sign, paper display and mailbox face while preserving the full ten-prop inventory. These revisions are preserved in `checkpoints/07_contact_seam_rework.gd.txt`.

The rail contact contract now uses the actual Truck mesh underside, .045 above the actor origin. Both authored grind routes and their approach ramps use .605 elevation. The rerunnable `game/tests/skater_contacts.gd` checked the actual plaza, rail meshes and articulated board model for forty simulated seconds per rider at 30, 60 and 120 updates per second. `tests/rail-contact-proof.log` records 25 checks with zero failures. Both grind riders have maximum truck-to-rail error 0.000000 at all rates; rail top is .650000. All three riders' maximum planted sole/deck error is .016500, within the stated .025 budget, and final route positions agree across update rates within .00001. This closes the rejected contact unit using measured model bounds, rather than a prose offset assumption.

Refreshed desktop and landscape-phone game frames were inspected after the hint correction. They now say to watch rider loops and cross behind the board. Retained screenshots under `tests/` show the actual game, paused overhead layout, editor and landscape-phone viewport. The ordinary arrival space leaves room to observe moving skaters before committing, and the circular layout and separate roach/rider silhouettes remain readable.

The final native run completed 147 checks with zero failures, including 39 streetlife checks and a complete ordinary-input plaza traversal with all skaters and roaches active. The live traversal completed in 11.17 simulated seconds with .20 seconds waiting; this is an automated feasibility result, not a human difficulty target. The streetlife browser sequence passed 12 checks with no JavaScript or Godot errors. The retained original browser regression log reports 16 passing checks. Web, Windows and debug exports completed in the retained build log. Static models, actor hierarchies, actual motion/action poses, collision/route behavior and contact bounds therefore have separate evidence.

All applicable production-tier gates pass for this game's original low-poly style. Editable procedural sources, independent construction checkpoints, fifteen canonical renders, meaningful geometric/contact rework, native/browser proofs and game views are retained. No critical omitted assembly, detached component, integration blocker or unreadable required route was found in this scope. Real iPhone/Safari behavior, native Windows execution, sustained device performance and first-time human difficulty remain separate platform/playtest work.
