# Baby frog-head hat correction — 2026-10-18

55 native checks passed. New checks cover locked reward on entry, cycling only
unlocked hats, repeated-stage protection, three-clear locked state, migration
of a premature version-4 unlock, fourth-clear auto-equip, visible frog-head
mesh and persistence. Active crossing traversal at three phases still passes.
Web release, debug web and Windows exports completed without errors.

Five focused Chromium checks pass with zero runtime errors: fresh entry stays
locked, cycling skips locked headwear, the lock survives reload, a completed
four-stage saved-profile fixture renders the earned frog-head hat, and the
reward joins the three-way cycle. The fixture tests rendering/load behavior;
actual fourth-clear earning is verified by the native runtime checks above.
The staged production export starts through the preserved WASM adapter with
no Content-Encoding header, exposes no debug bridge and decodes to the exact
39,514,754-byte engine hash. RiverSim, adapter and headers remain byte-identical.
Evidence: /workspace/frog-hat-native.log, frog-hat-browser-results.json,
frog-hat-staged-results.json and frog-hat-play.png.
Real iPhone/Safari and Windows execution remain untested. Hosted gameplay
inspection remains blocked by executor DNS/proxy restrictions.

Sites confirms successful private version 5 publication at
https://hopan.fiiendward.chatgpt.site. Owner-only access is preserved.

--- Earlier validation history ---

# Baby Mode update — 2026-10-18

51 native checks passed, including active-hazard full finale traversal at three
arrival phases, moving-log support/carrying, car and water deaths, overhead pause,
checkpoint retry, baby bonnet unlock, hat cycling and persistent progress.
The original three dry routes still pass their physical traversal checks.

Ten focused desktop Chromium checks passed. Emulated landscape phone play also
confirmed stage four is reachable from the menu, the bonnet equips, touch moves
the frog and pause/resume works with zero page errors. Production startup passes
without exposing the debug probe. The staged release also starts through the
existing WASM hosting adapter when gzip is served without Content-Encoding;
client-decoded bytes match the exact original engine WASM hash.

Sites confirms private version 4 at https://hopan.fiiendward.chatgpt.site.
Existing RiverSim files are byte-identical. Real iPhone/Safari and Windows
execution remain untested. The supplied audio attachment is inaccessible to
the download helper; no sound integration or loudness claim is made.

--- Earlier validation history ---

# Prototype validation — 2026-10-17

2026-10-18 handoff recheck: baseline `7be94416ead3e43595fd20b533e40e461234a802`
passed all 37 native checks again. Checksum-verified Godot 4.7.2 exported Web,
Windows and debug Web builds successfully. A focused Chromium run passed seven
checks: production startup without a debug bridge, perspective play, keyboard
movement, overhead-map pause, 3D restoration, overhead editor, and no browser/
Godot errors or failed asset responses. This did not repeat the broader browser
editor/storage/mobile suite below. Local HTML/JS/WASM/PCK responses had correct
MIME types. See `../UPDATES.txt` for publishing blockers and current limitations.

Engine: Godot 4.7.2 stable, official Linux x86-64 binary and export templates with pinned SHA-512 verification. Original design brief preserved unchanged in `game-design-brief.md`.

## Passed

`bash tools/test.sh`: **37 checks, zero failures**, with an isolated temporary save library and the actual Godot physics/runtime:

- All three bundled JSON maps validate and have dry connected routes.
- Default perspective gameplay, paused overhead map inspection, restoration of the frog camera and preserved orthographic editing.
- Actual editor painting, undo/redo, patrol waypoint recording and trap properties.
- Authored JSON write/read round trip; independent duplicate slots; disk library reload.
- Playtest constructs authored critters/traps and returning preserves the document.
- Physical wall collision, water/critter/projectile deaths, retry reset and exit victory.
- Swept projectiles stop at solid geometry.
- Invalid version numbers and types are rejected without replacing the document.
- Twenty critters instantiate and simulate; wandering movement is observed.
- The actual frog physically traverses each demo's complete dry route with hazards paused. This verifies clearance and collision, not enemy timing or difficulty.

`node tools/browser_smoke.cjs`: **16 checks, zero failures**, Playwright 1.62.1 with Chromium 154 / WebGL 2 using software rendering:

- Continuous keyboard movement and world-clock pause.
- Low-resolution perspective gameplay, M / Map pause, return to the 3D view and full-resolution overhead editing.
- Mouse terrain painting, keyboard undo/redo, downloaded map JSON.
- Editor document preserved across playtesting.
- Local save retained after browser reload (IndexedDB).
- Actual file-picker import restores exported terrain.
- Landscape 844 × 390 CSS-pixel interface and dispatched touch joystick movement.
- Mobile pause/resume screen.
- No browser JavaScript or Godot runtime errors during the smoke sequence.

Screenshots are generated in `build/test-results/`. The opt-in read-only browser diagnostic bridge is enabled only in debug exports launched with `?browser-test=1`; the production release does not expose it. Production web startup is checked separately.

All three bundled levels were reconstructed through editor operations using `game/tests/author_demos.gd` and saved with the shared serializer. The web and Windows x86-64 release exports completed without Godot script/export errors. The PS1 surface, water, sky and screen shaders compiled and rendered in Chromium without runtime errors.

## Still required before declaring the brief complete

- Real iPhone Safari loading, touch ergonomics, audio/browser lifecycle behavior and sustained performance, including the 20-critter target.
- Running the Windows executable on Windows; this Linux environment verifies export, not Windows execution.
- Human full playthroughs with all hazards active, enemy/trap timing and difficulty tuning. Automated physical route checks pause hazards.
- Broader accessibility review. The canvas interface has readable controls and keyboard gameplay, but full screen-reader support is not implemented.
- Hosted startup and headers: Sites confirms private version 1 at https://hopan.fiiendward.chatgpt.site. Exact gzip decompression and local compressed-release startup passed. Hosted validation is blocked by executor DNS/proxy restrictions; see `../UPDATES.txt`. The requested custom address is not reserved or promised.

The implementation is a functional prototype of the requested game and editor. It is not being marked as fully complete version 0.1 while real-device criteria remain unchecked.
