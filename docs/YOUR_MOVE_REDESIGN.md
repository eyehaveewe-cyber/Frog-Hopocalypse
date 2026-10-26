# Moves When You Move: decision-screen redesign

26 October 2026. Levelwright pass in response to the user's complaint that solutions are obvious and the set too easy. This is a first playable difficulty revision, not proof of a successful difficulty target.

Compared structures: denser/faster hazards were rejected because they add punishment without teaching a new decision. A single narrow solution corridor was rejected because it makes the answer more obvious. Selected: offset choice screens within existing observation courts. The original moving hazards, freeze rule, resource policies, checkpoint and reward remain. Signs teach cause/effect without naming the next turn or collection route.

## Teaching sequence

1. One Step Ahead: compare crossing entry and arrival phase. Three split courts interrupt direct approaches without obscuring the traffic itself.
2. Needle Clock: plan movement while tracking darts and rail together. Offset safe-floor screens change approach access; emitter rows/columns remain clear.
3. Shard Switchyard: collecting a reserve also advances patrols. Split collection courts and approaches require choosing which side to enter and exit; both fragment-funded leaps remain possible.
4. Stillwater Circuit: keep a plan across log landing and seed expenditure. Successive bank/garden screens break the broad open courts into approach choices.
5. Rush Hourglass: combine phase planning, paired traffic and charge conservation. Seven rows of offset screens reduce unrestricted movement in the safe medians and crossing-grid approaches.

The pass changes 15/24/24/42/73 floor cells respectively, preserving legal fresh-run and checkpoint route clearance. Screens retain opposite mouths where space permits. Existing witness paths are reserved deliberately; this pass does not claim those paths are unique or that geometric alternatives are equally safe. No additional enemies or speed increases. Shortcut/solution diversity and perceived difficulty require new-player observation; a known solution still completing is the solvability gate, not a difficulty metric.

## Rebuild and inspect

```
python3 tools/design_your_move_set.py
python3 tools/redesign_your_move.py
godot --headless --path game --script tests/your_move_set.gd
godot --path game --script tests/move_redesign_preview.gd
```

`docs/your-move-redesign.json` records every changed cell and teaching goal. Map IDs, campaign progress, the new frog cosmetics and all other level sets are retained. Screenshots in `docs/previews/move-redesign/` are actual native Godot map views. Rendering used Linux llvmpipe/Godot 4.6.3; no browser/mobile or human difficulty validation is claimed. No website publication in this checkpoint.

Verification result: all 61 native acceptance checks passed, including five fresh routes, all checkpoint retries, idle hazard freeze, one-beat-per-hop, earned hat persistence and a failed reckless finale crossing. This is evidence of solvability and rule preservation; human difficulty remains open.
