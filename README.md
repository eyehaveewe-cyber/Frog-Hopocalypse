**Current public build: [Hopán version 26](https://hopan.fiiendward.chatgpt.site).**
The harder five-stage Tile Hop tour is published. Existing rules, unlocks, campaign,
RiverSim testing route and audio are preserved. Earlier review notes below record
their state when written. [Publication and rollback](docs/TILE_HARDNESS_PUBLICATION.json).

## Speculative recovery updates — repository only

Branch `speculative/hopan-recovery-two-pass` starts from the published v26 source
chain (`b36f338`). These proposals are committed for testing; the live website
still runs v26. **Pass one:** death screens name the retry destination and show
the long-hop state that will actually be restored. Checkpoint retries confirm
the return in the status line. [Progress and checks](docs/SPECULATIVE_RECOVERY.md).

## Harder Tile Hop tour

All five stages now have tighter crossings and guarded landings: 60 active hazard placements versus 24. All 21 dart shooters face cheese through verified clear firing lines. Existing rules, one checkpoint per stage and unlocks stay intact. [Design and focused checks](docs/TILE_HARDNESS.md). The approximate 2½× target still needs human calibration.

# Hopocalypse: Pharaoh Frog Hopán

A playable Godot **4.7.2** 3D arcade maze game with an integrated desktop level editor, following the [original design brief](docs/game-design-brief.md). The presentation now follows the user's PS1-style direction and Frog Frenzy references: a receding perspective camera, original pixel textures, low-poly models, vertex snapping, limited-color dithering and a low-resolution 3D scene. See [art direction](docs/ART_DIRECTION.md).

## Play or develop

```sh
cd /workspace/Frog-Hopocalypse
python3 tools/bootstrap.py
bash tools/godot.sh --editor
```

On Windows or another desktop, open `game/project.godot` in Godot 4.7.2 and press F5. All game assets are original low-poly meshes generated in GDScript; no external runtime services are required.

To create the browser and Windows distributions:

```sh
bash tools/build.sh
python3 -m http.server 8000 --directory build/web --bind 127.0.0.1
```

The browser entry point is `build/web/index.html`. Serve the **whole directory** over HTTP locally or HTTPS for remote/mobile hosting. Opening HTML directly as a file cannot load WebAssembly. The single-threaded Compatibility export does not require cross-origin isolation headers. Windows output is `build/windows/Hopan.exe` with an embedded game pack.

`tools/bootstrap.py` downloads the pinned Linux editor and export templates from the official Godot release and verifies pinned SHA-512 hashes. Tools and caches live outside the checkout under `/workspace`. Set `HOPAN_TOOL_DIR` and `XDG_DATA_HOME` to relocate them. Desktop developers can install the official editor/templates normally instead.

## Splash-screen review branch

The static, manually drawn splash uses the existing frog and pharaoh hat, with
**Pharaoh Frog** above a larger **Hopán**. Real menu buttons sit over the artwork.
Separate desktop, touch-landscape and portrait compositions preserve the hero;
all existing play, settings, editor and continuation actions remain available.
[Art source and editable layers](art-source/splash/README.md) ·
[Desktop preview](docs/previews/splash/desktop.png) ·
[Phone portrait](docs/previews/splash/portrait.png) ·
[Phone landscape](docs/previews/splash/landscape.png).

Run focused UI checks with `bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/splash_ui.gd`.
Browser evidence uses `tools/splash_smoke.cjs` against the debug export on port
8060; it requires local Playwright and Chromium. There are 14 passing splash
checks, 52 tile-mode checks, and seven browser checks. Web and Windows build.
One pre-existing broader presentation assertion still expects the old camera
return offset (-2.5 rather than -2.0); no camera or level code changed in this pass.
No merge or website deployment is authorized for this splash branch.

## Per-level rules (review branch)

In the editor, choose **Free long hops** or **Charged long hops** and the number
of short hops needed to recharge. Combine these with **Move with me** per level.
Only unseen rules interrupt stage entry; a translucent **Rules** button / F1
reopens them. Original sharp, dripping headings sit above plain instructions.
Try **Editor → Movement demos → Charge Trial · 10 hops → Playtest**.
Existing campaigns and unlocks retain their rules. See [rule behavior and tests](docs/LEVEL_RULES.md)
and the [new-rule preview](docs/previews/rules/new-charge-rule.png).
This branch is committed for review; the website has not been updated.

## Landmark scenery (review branch)

The editor palette now includes **Sphinx, Osiris statue, Pyramid, Moss tree and
Heron**. **Background view** exposes the surrounding water for placement. Select
an object's gold ground pin to change model, rotation or scale. Landmarks are
non-blocking decorations and may also sit on the course.

Try **Editor → Scenery demos → Temple Shore / Heron Marsh → Playtest**.
Two cached model LODs and range culling reduce distant geometry; enlarged 16×16
texture patches provide the coarse look. Scenery levels gain a little camera
headroom; ordinary levels retain their framing. See [asset and rendering notes](docs/LANDMARK_SCENERY.md)
and [Temple preview](docs/previews/landmarks/temple-near.png).

## Implemented

- Tile-mode **Long hop** shows READY / ARMED / HOPPING / WAIT / PAUSED inside its existing touch target. READY follows the same recovery gate as queued directional input; selecting the button still arms a future hop.


- **Cheese wall**: yellow, hole-patterned terrain that blocks the frog and critters but lets darts pass through. Painting, erasing, undo and JSON save/load support it.
- **Seam worm**: a blue-and-gold patrol variant. Its points snap to the lower-right corners of clicked tiles, and routes follow clear horizontal/vertical tile edges. Add square corners to close a loop. Invalid diagonals, water and solid obstructions are rejected. Old worms and their routes stay unchanged.
- **Patrol car**: road-only traffic. Choose east–west or north–south; without waypoints it turns back at walls, blockers and road ends. Draw car waypoints for repeating road routes, with a point at every turn. Clear the route to restore axis patrol. Preview, pause and retry follow the existing game controls.
- Trees no longer mark the structural exit-path check as blocked. Their physical trunks remain; walls, cheese walls, pillars and traps still block route validation.

- **Loop route** in the worm/critter inspector explicitly repeats waypoint routes; legacy saved patrols keep looping. **North–south loop** makes an obstacle-bounded vertical route. Frogbutt’s existing worm now repeats between `[7,1]` and `[7,11]`; its 66 wandering bugs, terrain, scenery, trap and spawn/exit remain unchanged.
- **Exit Preview** in the menu optionally sweeps to the exit and back before each stage starts; the frog, hazards and timer wait. Space skips it on desktop; Map skips it on touch. Retries resume immediately.
- Death animations remain visible for 1.6 seconds and victory for 2.2 seconds before the result screen; retry can skip the hold.
- The workshop size selector offers Standard **17 × 13** or Large **21 × 16**, about **52% more area**, for new mazes. Current documents retain their dimensions; both sizes save/export/import normally.
- **Not as Hard as It Looks** unlocks after all four Baby Mode clears, including existing saved clears. The set stays completely hidden until unlocked, so a fresh save shows Baby Mode alone. It contains your authored layouts in attachment order: **Hardbutt → Gloopbutt → Treebutt → Frogbutt**. Only Frogbutt’s worm route has subsequently changed at your request; the original is retained in `game/tests/fixtures/Frogbutt_original.json`. Its stage progress saves separately; Baby Mode, hats, custom levels and preferences are retained. Browser progress also has an immediate backup for quick reloads.
- **Baby Mode**, the first difficulty set: Moonlit Oasis, Pharaoh's Courtyard, Violet Mire, then Little Frog Crossing. The original three layouts are unchanged. The finale crosses two slow traffic lanes, three long-log lanes, a safe checkpoint bank, then three slightly faster traffic lanes.
- Completing all four distinct Baby Mode stages unlocks and equips a baby frog-head hat, with raised eyes and a stitched smile. **Hat** cycles bare head, the pharaoh headdress and the earned frog hat; selection and stage completion save locally on the device.
- Continuous WASD/arrow movement, animated hopping, physical collisions and an interchangeable pharaoh hat.
- Wandering critters, waypoint patrols, and projectile traps with configurable direction and interval.
- Critter, water and projectile deaths; immediate retry; victory with completion time, death count and next-level transition.
- Moonlit Oasis, Pharaoh's Courtyard and Violet Mire, reconstructed and saved through the editor's own operations. The oasis adds grassy canal paths and palms inspired by the supplied Frog Frenzy reference. Little Frog Crossing adds moving vehicles and rideable logs without changing the original movement or camera.
- Terrain painting, scenery, spawn/exit placement, object properties, rotation, patrol drawing, undo/redo, save/load/duplicate, JSON import/export, and playtesting without losing edits.
- A fixed-angle perspective camera following the frog on desktop and mobile, with a low-resolution, nearest-scaled 3D render and sharp interface text.
- **M / Map** pauses gameplay and opens the preserved overhead view. **3D view** resumes the perspective view. The editor retains its sharp overhead construction view. A bonus 2D mode remains a future possibility.
- Landscape touch joystick, phone-sized controls, and pause on focus loss/tab hiding.
- Batched static meshes and bounded, validated versioned map files.

See the [editor guide](docs/LEVEL_EDITOR.md) and [architecture and map format](docs/ARCHITECTURE.md).

## Validate

```sh
bash tools/test.sh
bash tools/build.sh --with-browser-test
python3 -m http.server 8060 --directory build/test-web --bind 127.0.0.1
# In another terminal, with Playwright and Chromium available:
node tools/browser_smoke.cjs
```

The browser runner uses Playwright 1.62.1 and `/usr/bin/chromium` in this cloud environment. Set `HOPAN_CHROMIUM` or `HOPAN_TEST_URL` for another browser binary/server. Screenshots and exported test maps go into ignored `build/test-results/`. Native tests use an isolated temporary save library.

## Remaining validation and publishing

This is a first functional prototype. **Real iPhone/Safari testing**, Windows execution, broader accessibility work and gameplay/difficulty tuning remain. Emulated touch tests cannot establish iPhone performance or Safari compatibility. Honduras and Mexico theme kits remain on the roadmap. There is no combat, multiplayer, account system or online sharing.

Requested address: `Hopan.chatgpt.sites`. The actual public Site is **https://hopan.fiiendward.chatgpt.site**, now **version 9**, including Baby Mode and the unlockable baby frog hat. It was published on 2026-10-18 through the official Sites workflow. The existing `/riversim/` test files were preserved byte for byte. No custom hostname reservation is claimed.

The root streams deterministic gzip WASM through `hopan-wasm.js`; RiverSim retains its original hosting adapter. Exact decompression and local compressed-release startup passed. Hosted runtime inspection from this executor is limited by DNS/proxy restrictions; the Sites service confirms deployment success and the current public audience. **The supplied `Recording (56).m4a` could not be downloaded, so sound integration and volume adjustment are still pending.** See `UPDATES.txt` for identities, evidence and rollback.


Android startup uses the same root URL and saves. Android defaults to compatibility
graphics: original textured geometry with standard unshaded materials, a plain
sky and no custom postprocess. Mobile canvas resolution is capped at CSS pixels.
[Force compatibility mode](https://hopan.fiiendward.chatgpt.site/?compat=1) or use
`?compat=0` for full retro shaders. No separate /droid export is needed.
Loading stays visible until Godot signals its first rendered frame. Download,
engine, missing-WebGL and lost-context failures reveal retry controls and details.
WebAssembly and WebGL 2 remain required ([Godot web export guidance](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)).
The original physical Android black screen has not been reproduced on hardware;
Android UA/touch/high-DPI emulation and focused failure tests passed.

Focused campaign validation: `bash tools/test_human_set.sh` runs unlock,
save and route checks with an isolated temporary save folder.

## Recorded voices

Exactly the 17 user-selected clips are bundled in `game/audio/`, with their
source manifest and supplied mapping instructions. The first Baby Mode take is
trimmed at the first waveform burst (source seconds 1.708271–2.710); its breath
boundary has not been independently listened to. No unlisted recordings are used.

One voice plays at a time after a keyboard, mouse or touch gesture. **Recorded
voices** in the menu mutes playback and saves the preference. “Begin” waits for
stage display, earlier announcements and Exit Preview. Death/retry clears stale
announcements. Stage 4’s return warning triggers from the final street (rows 7–9)
back to its near safe bank (row 10), and rearms only after another road visit.
Primary drowning and worm-death lines alternate; watersploded is an 18% drowning
alternative and busted is a 6% general death alternative. Baby victory queues the
hat reward line; selecting an earned baby hat can play it again while idle.

All clip hashes and full decodes passed with zero clipped samples (highest
sample peak −2.884 dBFS before the player’s −2 dB headroom). Sixteen native cue
checks and twelve patrol checks passed. Browser checks verified serialized
announcements, preview timing, nonzero Web Audio output, mute/progress persistence,
patrol editor controls and compressed Android-emulated startup. This verifies
programmatic playback, not human listening or physical-phone behavior.

Recorded voices and worm patrols are live in public **version 10** at
https://hopan.fiiendward.chatgpt.site/ . See `UPDATES.txt` for exact source,
deployment and rollback identifiers.

Editor additions are live in public **version 11** at
https://hopan.fiiendward.chatgpt.site/ . Exact publication and rollback IDs are
in `UPDATES.txt`; focused checks are in `docs/EDITOR_HAZARDS_VALIDATION.json`.

Stage sets use compact main buttons with expandable stage pickers. A set button
replays its most recent clear, or starts stage one when fully cleared. Bonus is
immediately available and includes the original 21 x 16 Shelby layout unchanged.
Existing Baby Mode and human-made-set unlock rules are preserved.

Compact sets and Shelby are published in public **version 12** at
https://hopan.fiiendward.chatgpt.site/ . Exact source and rollback identifiers
are in `UPDATES.txt`; physical Android shader testing remains separate.

Android scene-shader compatibility mitigation is published in public **version 13**.
Phone diagnostic URL: https://hopan.fiiendward.chatgpt.site/?compat=1&graphics-debug=1 .
Moto G5 recovery remains unverified; save the graphics report if startup fails.

The editor has a compact **Loop** checkbox beside **Draw route**. Rotating a
seam worm pivots it and its drawn patrol around the original placement tile.
A 180° turn changes the right-side seam to the left-side seam; blocked or
out-of-bounds routes keep their previous placement. Undo and JSON saves retain it.

**Sound** on the main screen and **Sound: On/Off** during play share a saved
preference. Enter the editor from the main screen. The **Checkpoint** tool places
up to 16 safe-ground flags: reach one during play to change the retry spawn;
Erase removes it, undo/redo and JSON preserve the layout. Existing Baby Mode
checkpoint behavior is unchanged.

iPhone-sized Chromium touch/audio checks passed; Safari and physical iPhone
audio remain unverified because the WebKit browser download was blocked here.
Reproduce the available test with `node tools/iphone_sound_smoke.cjs` after the
debug web export is served on localhost:8060. Playwright device emulation changes
[viewport, user agent and touch](https://playwright.dev/docs/emulation); it does
not establish [Safari/iOS platform compatibility](https://playwright.dev/docs/browsers#webkit).

The main menu labels its collections **Level sets**. Baby Mode is a named set;
difficulty is a separate attribute beneath the set button.

**Tile Hop** unlocks after the four Not as Hard as It Looks stages. Arrows/WASD/joystick hop
one tile; Shift or **Long hop** covers two. Walls block both. **Move with me**
freezes hazards between valid hops and also works with regular Hopán movement.

Editor controls: **Tile-hop mode**, **Move with me**, **Movement demos**, a
33 × 49 tour size, and a 10–30 tile draw range. Demos: **Big Hop Boulevard**,
**Your Move Crossing**, and the regular-mode **Your Move Garden** in Bonus.
The overhead map keeps the full layout visible. See [Tile Hop rules, demos and
validation](docs/TILE_HOP.md). Phone performance and Safari remain unverified.

Tile Hop and movement-linked time are live in public **version 18** at
https://hopan.fiiendward.chatgpt.site/ . Exact source, deployment and rollback
identifiers are recorded in `UPDATES.txt`.

Baby Mode also unlocks the **Purple frog** skin. Use **Skin: Green/Purple** on
its main menu to switch independently of hats; your selection survives reloads.
Trees have five fixed variations with broader foliage patches. Tree shapes
and patterns stay fixed in play; original ground textures are retained.

**Editor recovery:** maps started with **New Egypt** or **New Swamp** keep an
**Autosave** recovery copy every 40 undoable edits (one paint stroke counts as
one edit). Select it from **Load a local level…** to recover your map. Manual
saves remain separate. Recovery also preserves unfinished layouts; Playtest
still checks them. Browser recovery uses device-local storage; Export makes a
portable backup.

Turret interval, rotation, speed and length spinners stay attached during edits.
Tile turrets fire at intervals of at least one whole beat. Brick walls and stone caps use lower-contrast mortar and filtered mipmaps
to reduce shimmer at oblique angles.

**Tile-level redesign:** Big Hop Boulevard now uses four timed encounter courts
with refuge banks; Your Move Crossing adds sideways crossings, a dart/rail court
and two approaches to a water-gated vault. Both retain four checkpoint flags.
**Spike ball** in the editor holds, marks its next destination, and slams along a
cardinal patrol or a free shift with one to four enabled directions. Its inspector
sets hold length, free-shift range and patrol loop. Walls, cheese, scenery and
water stop it; a long hop can clear its path. See
[design and playtest evidence](docs/TILE_LEVEL_REDESIGN.md).

Tile encounter redesign and spike balls are live in public **version 22** at
https://hopan.fiiendward.chatgpt.site/ . Publication and rollback IDs are in
`UPDATES.txt`; evidence is in `docs/TILE_REDESIGN_VALIDATION.json`.

**Distant monuments (review branch):** the editor now has a separate **Distant backdrop**
tool with five baked cutouts, independent art scale/distance, fixed world anchoring
and small Map thumbnails. **Scenery demos → Horizon · 1x / Horizon · 80x** compare
the same course at ordinary and monumental art scale. See [authoring, render costs
and limitations](docs/DISTANT_BACKDROPS.md). This feature is not deployed.

**Tile Hop tour (review branch):** five stages now have one late checkpoint each.
Big Hop Boulevard offers a moat/island route choice; Your Move Crossing retains
its geometry. New stages teach three-fragment reserves, single-use Hop seeds and
a 25-short-hop recharge. **Space, then a direction** or the larger lower-right
**Long hop** button selects the action; phones show the rule and live resource
count. Empty taps explain the rule. Editor pickup/rule controls are included.
See [tour design and evidence](docs/TILE_TOURS.md) and the
[working design document](docs/design/Hopan-Tile-Long-Hop-Review.docx). Published in version 25.
