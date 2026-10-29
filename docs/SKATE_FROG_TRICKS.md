# Skateboard frog and airborne tricks

Skate Escape uses a standing frog pose with animated limbs and a separate board. During an airborne jump, a fresh left press selects a kickflip and a fresh right press selects a shove-it. Steering remains available; the player can perform one trick per jump. The next landing restores the riding pose. The same controls work with the touch joystick.

The trick shapes adapt the procedural skateboard motions in the user's Zendelves project: [Zendelves source, commit e351fcb](https://github.com/eyehaveewe-cyber/Zendelves/tree/e351fcb7f34c0281c48db8bc5bab0b1e85bb4904), `lib/xen/marsh.ts`, `lib/xen/marsh-models.ts` and `lib/xen/renderer.ts`. Zendelves implements a board flip, a horizontal board rotation and rider lift in code; it does not provide motion-capture clips. Hopán's existing frog geometry, wardrobe and physics remain its own. The source repository is private.

A trick begun early in a jump completes a full board rotation. A late input becomes a shorter flourish so the board can settle before touchdown instead of snapping. The frog's collision body and acceleration remain the authority for gameplay; the pose changes are visual. Morning-suit idle animation yields to the skateboard stance.

The native rig suite checks ordinary jumps, ramp launches, rail dismounts, late-input landing continuity and equipment/wardrobe preservation. Browser evidence shows the actual Skate Escape level with normal keyboard input. Physical mobile hardware and human assessment of the new animation remain open.

Verification: 52 focused native checks, 16 existing ice/skate checks and six browser checks passed. Tests include late left/right input on ordinary ollies, ramp launches and rail dismounts; tested touchdown rotation differences were at most 0.001 radians. [Browser screenshots and recording](skate-frog-evidence/) come from the real third City Journey stage using a saved-profile fixture to unlock it. The browser used software rendering.

```bash
bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/skate_frog_tricks.gd
bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/ice_skate_features.gd
```
