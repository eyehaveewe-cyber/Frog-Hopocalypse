# Tile Hop: five-level tour

Implements the user's Levelwright / Channel Hideo request of October 19, 2026.
The set still unlocks after Not as Hard as It Looks. Stage IDs 0/1 stay in place;
stages 2–4 extend the set. Old completion records do not complete new stages.
Existing campaign/audio files outside this tile set are preserved. The source branch remains
unmerged; the tested export is published publicly as version 25 at
https://hopan.fiiendward.chatgpt.site.

## Spatial direction and authorship

The human requirements are: make the first stage inventive, review the second,
add three stages dedicated to fragments, power-ups and a 25-move recharge, retain
one late checkpoint per stage, and explain the phone control. Three fragments
per reserve, the Hop seed name, new stage names/layouts and collection recovery
semantics are AI-authored implementation choices within that request. Human
playtest approval and enjoyment are not established by automated completion.

The Jak and Daxter reference is treated as an invitation to exploration and
readable destinations. Evan Wells describes the original game's connected,
visible-accessible world in [Naughty Dog's firsthand retrospective](https://www.naughtydog.com/blog/jak_and_daxter_the_precursor_legacy_20_year_anniversary).
Our application is a bounded tour of visible gates, collection loops and return
sightlines, with original Hopán art and rules. No copied layout, character,
branding or claim of a Naughty Dog design rule is involved.

The two considered structures were a linear sequence of refill gates, and a
collection/return loop with differently oriented crossings. The latter fits the
pickup stages: gathering changes the meaning of a water gate already in view.
The 25-hop stage instead uses winding circuits: forward traversal replenishes
power, so repeated stationary recharge is optional rather than required.

| Stage | Organizing idea and player decision | Rule / checkpoint |
| --- | --- | --- |
| Big Hop Boulevard | Circle the moat on its outer bank or use a central island/rail shortcut. A wet crossing, road, island and dart lane require different alignments. | Free; one flag at (8,13). Inner route 27 hops; outer route 38, including a later start. |
| Your Move Crossing | Retained S-route with sideways roads, visible spike destinations and alternate vault entries. Review found its movement-linked clock and safe approaches useful as stage two. | Free + Move with me; retain former second-to-last flag (10,21). Terrain/objects unchanged. |
| Shardwater Sanctuary | Gather on three islands; a central pond splits the road-crossing collection loop. Revisit the gate once three fragments are assembled. | Fragments + Move with me; one flag at (9,8), before the last water gate. |
| The Seed Vault | Five differently oriented gates form a switchback. Land on each seed and preserve the reserve; outer banks let you walk around a rail instead of wasting it. | Power-up; one flag at (4,14), with the final seed ahead. Real-time hazards continue while observing. |
| Twenty-Five Terraces | Two winding circuits refill the reserve on the way to the next gate. Safe lookout pockets change the linked traffic phase. Save power for the water crossing. | 25 short-hop recharge + Move with me; one flag at (10,22). |

## Resource and recovery contract

Missing rules retain free long hops. Editor **Level rules** adds **Fragment long
hops · 3 pieces** and **Power-up long hops · Hop seed**; the existing recharge
spinner applies only to Charged rules. The palette places **Hop fragment** and
**Hop seed** on safe, clear whole cells. Both support selection/erase, Undo,
local Save, recovery snapshots and JSON. Triangle fragments are copper; diamond
seeds are cyan, with different silhouettes so color alone does not identify them.
They have no collision, light, shadow, animation, expiry or timer.

- **Fragments:** start empty. Three ordinary landings on triangle pickups earn
  one reserve. Collecting the third resets the partial count to zero.
- **Power-up:** start empty. One diamond seed grants one reserve.
- Both carry at most one long hop. A pickup stays on the ground while full.
  Collect only the type matching the level rule; no pickup on a skipped middle
  tile. A successful long-hop takeoff spends it; a blocked attempt spends nothing.
  Idle/ordinary hopping cannot refill a collectible rule.
- Collection happens after a safe landing and before checkpoint capture. The
  checkpoint stores reserve, partial fragments and collected IDs. Retry restores
  exactly that state and matching visible pickups; pickups collected after the
  checkpoint become available again. Before a flag, restart resets the route.
  Finite pickups can be wasted on an unnecessary valid jump; retry is the
  explicit recovery. No undisclosed auto-refill or stockpiling is added.
- Charged rules retain their earlier contract: start charged, exactly 25 completed
  short landings refill this stage, and checkpoint retry refills it. Idle, blocked
  input, long hops, log carrying and menus do not advance recharge. Backtracking
  counts. Both forward circuits are long enough to refill without backtracking.

Schema stays version 1, adding `rules.long_hop: "fragments" | "powerup"` and
object types `hop_fragment` / `hop_seed`. Older readers reject those new values;
keep portable map exports before rollback. Earlier free/charged maps retain their
semantics. Collection state lives within an attempt/checkpoint, not a persistent
cross-level inventory.

## Controls and phone feedback

The **Long hop** button is a 166×64 target at the lower right, opposite the
joystick. It is outside the crowded header. **Tap, then move** stays visible
above it along with the current level's refill rule. Its status shows READY,
ARMED, partial fragments, FIND HOP SEED or the remaining SHORT HOPS. Pauses and
recovery are distinguished from resource availability. While empty, tapping
opens the rule card with the live resource status and pauses safely; it never
arms or silently ignores the request. Ready taps arm exactly the next accepted
hop. Space then a direction does the same; Shift + direction remains available.
An accepted short or long hop clears arming. Rules are readable without a timer.
`tile-v2` introduces the updated controls once to returning profiles.

## Evidence and remaining questions

See `TILE_TOURS_VALIDATION.json`, native route fixtures and
`previews/tile-tours/results.json`. Real controller runs keep hazards active,
without teleporting or invincibility. The tested Sanctuary route gathers all
nine fragments and uses three long hops; Seed Vault gathers five seeds and uses
five. The 25-hop stage uses three gated long hops with complete refill circuits.
Second-stage sheltered and shortcut routes still complete with its single flag.

These are successful route and interaction checks, not proof of difficulty,
novice comprehension, enjoyment, every possible timing or device FPS. A human
pilot should focus on identifying pickup silhouettes from the gameplay camera,
understanding that empty tapping explains the rule, and recovering after wasting
power. Phone validation uses Chromium with touch/Android-UA emulation; physical
iPhone and Safari remain unverified. Native Sites publication succeeded as version 25. This executor cannot open
the live URL because its network proxy rejects CONNECT (403); the exact staged
compressed release starts successfully. See `TILE_TOURS_PUBLICATION.json`.

Regenerate layouts with `python3 tools/design_tile_tours.py`; the older movement
map generator invokes it after its historical baseline. Revert this feature
commit for source rollback. Preserve custom maps first; source base is
21f8ded10141a3514637c8e32236fbb8bff510a2. The earlier Channel Hideo recommendation
favoring a separate 10-hop experiment is retained as history in the working
DOCX; the user's later per-level variety request supersedes that restriction.
