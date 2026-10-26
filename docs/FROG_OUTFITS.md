# Fitted hats, morning suit and earned frog colors

26 October 2026. Builds on fix/phase15-map-validation at 3d5bfea. Motionwright guided the procedural pose/attachment work. Original geometry and deterministic stone/spot textures; no downloaded animation or recorded song.

The existing Your Move reward now has a lower pyramid crown, fitted circular headband/brim, stone-block texture and a front opening revealing the nested hourglass. The existing reward requirements still apply. Morning suit adds a rounded tailcoat back, cutaway sides, split tails, waistcoat/buttons, shirt collar, cravat and banded top hat. Hat cycles to the complete outfit after six distinct campaign level clears.

The main menu Skin control now cycles earned colors. Two clears earn orange, four yellow, six yellow/green spotted, eight purple with a pure white belly, and ten glossy pink gummy. These thresholds are implementation choices for the user's request for more level unlocks, and can be tuned. The existing purple reward still requires all Baby Mode stages. Replaying a cleared stage does not increase the count; editor/custom maps do not count. Existing profile storage/browser backup carries the selected IDs, with locked IDs rejected on restore. The Skin tooltip explains the thresholds.

Morning-suit idle begins after 2.5 seconds standing still. A four-second procedural loop combines alternating toe lifts, body sway, foreleg reach and a hat tip. It is a silent ragtime-inspired gesture, not a recording or reconstruction of the cited song. World movement, long-hop input, jumping, pause, map, intro, results and outfit changes cancel the routine and restore limb/hat transforms. Collision and hazard clocks remain owned by gameplay. No mocap.

The existing five-stage Your Move route/reward suite also passed all 61 checks, including hazard-clock isolation, earned hourglass eligibility, profile reload and hat cycling.

## Evidence and commands

- [Lineup](previews/frog-outfits/lineup.png), [hats close up](previews/frog-outfits/hats-close.png), [coat back](previews/frog-outfits/suit-back.png).
- [Four-second idle preview](previews/frog-outfits/morning-idle.mp4): actual Godot actor poses rendered at 10 sampled frames/sec in the preview fixture.
- `godot --headless --path game --script tests/frog_outfits.gd`: 24 checks, no failures; unlock gates, profile restore, white belly, cosmetic-only motion, interruption, limb cleanup, 30/60/120 Hz timing, actual world pause/input interruption.
- `godot --headless --path game --script tests/skin_variants.gd`: 15 checks, no failures; legacy purple eligibility, material restore, map changes and tree texture regression.
- `godot --headless --path game --script tests/skin_cycle.gd`: 15 checks, no failures; earned-color menu cycling, focus/scroll stability, saves and existing sound/animation settings. Existing test exit reports an ObjectDB leak warning; not claimed resolved here.
- `godot --path game --script tests/frog_outfits_preview.gd` generates screenshots and `/tmp/frog-dance` frames. FFmpeg assembles the clip at 10 fps.

Tested on Godot 4.6.3/Linux llvmpipe, with writable XDG data/cache/config paths. A pre-existing constant-array concatenation in `main.gd` did not parse on that installed version; the same four paths are now an explicit constant array. No content ordering change. Browser/mobile rendering and live publication remain unverified for this branch. Preview cameras inspect the actual runtime models; screenshots are not a human gameplay session.
