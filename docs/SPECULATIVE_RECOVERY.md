# Speculative recovery updates

Repository-only branch: `speculative/hopan-recovery-two-pass`, based on `b36f338`.
No publication, merge, new campaign, difficulty change or RiverSim edit is part
of these two passes. The current public Site remains version 26.

## Pass one — explicit death recovery

The death screen distinguishes **Retry checkpoint · R** from **Retry from start
· R**. Its summary explains that hazards restart and describes the restored
long-hop resource: saved fragments/reserve, seed requirement, or a ready free/
charged hop. It reads the saved snapshot, not inventory acquired after the flag.
The status line confirms checkpoint restoration. Retry mechanics are unchanged.

Focused native check: 17 recovery checks pass, including normal hop/flag claiming,
actual result presentation, emitted button actions, saved fragment versus later
inventory, seed restoration and charged refill. Existing set-menu assertions now
use the displayed retry action, retaining their progression checks.

Pass-one commit: `15400a5`. [Durable source](https://github.com/eyehaveewe-cyber/Frog-Hopocalypse/commit/15400a5).

## Pass two — pause recovery and deliberate full restart

Pause now exposes the same saved-state summary and retry action. After a flag,
**Restart level…** opens a choice: keep the checkpoint or restart from the
beginning. Cancel/Escape return to Pause with hazards still stopped; R cannot
bypass this choice. Confirming resets the active flag, position and collected
pickups through the existing fresh-start path, preserving campaign progress,
set/stage identity and playtest mode. Before a flag, the existing retry-from-start
action avoids a duplicate full-restart button.

This pass fixes the Pause/Resume header label after a paused retry and avoids
calling initial, never-collected fragments “restored.” Tab/Enter remain available
for normal button navigation in the confirmation. Hazard timing, resource rules
and checkpoint restoration mechanics remain unchanged.

Combined focused native checks: **34 recovery checks and 25 level-set menu checks
pass**. The recovery fixture covers ordinary checkpoint hops, result delay,
actual button signals, saved versus later inventory, seed restoration, charged
refill, cancellation, R/Escape behavior, full restart and campaign preservation.
Local debug Web export builds on pinned Godot 4.7.2. Eight local Chromium browser
checks pass without console/page errors across desktop and phone-sized touch
landscape: normal fragment pickup, checkpoint pause, cancellation, R protection,
actual water death, retry and full restart. [Preview images and results](previews/speculative-recovery/).

The phone preview exposed the existing joystick drawing over Pause. This pass
hides it while the pause/restart panels are open; Resume/retry retain the normal
joystick behavior. The phone pause panel may scroll on short landscapes; all
recovery actions were reached through real UI input in the browser check.

## Limits and rollback

These are implemented UI proposals, not a human usability study. Physical iPhone,
Safari, assistive-technology testing and real-device performance remain
unverified. The tiny browser fixture tests recovery controls; it does not
re-establish every campaign route. No broad regression sweep or reviewer agents
were used. All bundled levels, audio and WASM adapters are byte-identical to the
v26 source; its 60 hazards and 21 correctly aligned darts remain unchanged.
RiverSim and the published Site source checkout are untouched.

Do not publish or merge this branch automatically. To inspect the proposals,
check out this branch, run the Godot project, reach a checkpoint, and open Pause
or retry after death. Run the focused suite with `bash tools/godot.sh --headless
--fixed-fps 60 --script res://tests/recovery_feedback.gd`. For local browser
previews, export debug Web into `build/test-web`, serve all of `build` on 8062,
and run `node tools/recovery_smoke.cjs` with local Playwright and Chromium.
Rollback for testing: check out base `b36f338` (v26 publication chain). To keep
pass one only, check out `15400a5`. Neither action changes the live Site.
