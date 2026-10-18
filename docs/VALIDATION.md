# Not as Hard as It Looks — 2026-10-18

25 focused native checks passed. Original files match all four recovered
SHA-256s exactly. Each validates, has a connected dry route and is physically
traversable with hazards paused. Tests also start each exact stage with its
original critter count in Android compatibility mode. They verify locked UI
and loader, three/repeated clears staying locked, the fourth distinct Baby
clear unlocking set and hat, completion start button, legacy profile without
a new-set section, correct menu order, distinct progress, next/finale behavior,
preferences and selected hat after reload, and byte-identical custom library.
Unlock/counting tests invoke the actual world finish signal; route tests do
not establish that moving hazards can be defeated. The unrelated full prior
review/test suite was not repeated.

The exact layouts retain their difficulty: Treebutt has 94 critters and
Frogbutt 67. Full active-hazard human playthroughs, balance and physical-device
performance remain untested. Web release/debug and Windows export completed.
Android compatibility code, loading shell, root streaming adapter and legacy
RiverSim adapter remain unchanged from version 7. Audio transfer is blocked
separately and was not retried.

Browser profile writes now keep an immediate validated backup for quick reload.
A missing/invalid backup falls back to profile.cfg. If that backup is damaged
before asynchronous filesystem sync completes, fallback can recover an older
checkpoint; it cannot guarantee the newest unsynced change. Normal quick reload
retains the latest selected hat and both campaign arrays via the backup.

Twelve focused browser checks pass: locked fresh profile, completed-profile
fixture, attachment order, all four exact stage launches in Android compatibility,
movement/map pause, ordinary quick-reload preservation of selected hat and
custom library, separate campaign arrays, invalid-backup checkpoint fallback,
and no browser/Godot errors. Browser profile fixtures test persistence/loading;
actual four-clear earning is verified by the native runtime checks above.
Staged compressed production startup also passed, with exact WASM hash and no
debug bridge. All 17 protected RiverSim/header/adapter hashes match version 7.
Evidence: /workspace/human-set-focused-native.log,
/workspace/human-set-browser-results.json, /workspace/human-set-staged-results.json
and /workspace/human-set-preserved.json. Browser runs use desktop Chromium
with Android UA/touch/DPR emulation, not Android hardware. Hosted inspection
remains blocked by executor proxy restrictions. Real Android/iPhone/Safari and
Windows execution remain untested.

--- Earlier validation history ---

# Android startup and recovery — 2026-10-18

Baseline Android UA/touch/DPR-3 emulation started successfully, so it did not
reproduce the user's physical Android failure. It confirmed a 2532 × 1170
backing canvas for an 844 × 390 CSS viewport. The new mobile cap gives
844 × 390; Android automatically selects standard textured compatibility
materials and bypasses custom sky/screen/surface shaders.

Focused native compatibility checks passed: actual movement, standard pixel
materials, ocean material/map pause/return, hat switching, crossing objects
and 21 × 16 editor. Script/export checks passed; the unrelated full native
suite was not repeated for this startup fix.

Fourteen focused Chromium checks passed across mobile startup, touch movement,
map pause, saved hat across graphics-mode reload, editor, rotation resize,
staged raw-gzip release startup and exact WASM hash, no production diagnostic
bridge, context loss, missing WebGL, missing engine file, missing gzip support,
invalid WASM and stalled downloads. Intentional failure cases show visible
recovery UI; successful play had no browser/Godot errors. The stream test
forbids whole-response arrayBuffer and verifies exact 39,514,754-byte engine
hash fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0
for raw-gzip and already-decoded bytes. RiverSim responses are passed through
by the new root-only adapter. All 16 protected file hashes remain identical.

Evidence: /workspace/android-validation-results.json,
/workspace/android-wasm-stream-results.json, /workspace/android-build.log,
/workspace/android-compat-play.png and /workspace/android-missing-webgl.png.
This is desktop Chromium emulation with software WebGL, not an Android GPU,
Android WebView or Safari. Physical-device cause and hardware recovery remain
unverified. Hosted GET failed with proxy 'Tunnel connection failed: 403
Forbidden'; native Sites deployment results establish publication only.

Sites confirms public version 7 deployment succeeded. Public access remains
revision 2; all protected RiverSim/legacy-adapter/header hashes match.

Implementation follows the official [web-export guidance](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html),
[manual canvas sizing and engine callbacks](https://docs.godotengine.org/en/stable/tutorials/platform/web/html5_shell_classref.html),
and [frame_post_draw signal](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html#signals).

--- Earlier validation history ---

# Larger editor and Exit Preview — 2026-10-18

75 native runtime checks pass. New coverage verifies large-map validation and
reachability, far-edge paint/undo/redo, standard-size availability, JSON
roundtrip, saved Exit Preview preference, actual camera target at the exit,
frozen player/time, pause, map skip, disabling/cancel, return to frog, 30/120 Hz
timing, visible poses before result screens, delayed screens and early retry.
Original Baby Mode and active crossing checks continue to pass.

Nine focused Chromium checks passed across the preview and editor/result
scenarios: saved toggle, exit view with frozen player/time, return to play,
large-map far-edge paint/undo/redo, large JSON export, actual splash/victory
animation holds, retry and zero runtime errors. Death/victory were triggered
by keyboard movement in imported 5 × 5 test fixtures, not diagnostic writes.
The staged production release starts without the debug bridge and decodes
raw gzip to the exact original WASM hash with the preserved adapter.
Web release/debug and Windows exports completed. Real iPhone/Safari and
Windows execution remain untested; hosted gameplay inspection remains
blocked by executor DNS/proxy restrictions.
Evidence: /workspace/exit-preview-native.log, exit-preview-browser-results.json,
exit-preview-staged-results.json, large-editor.png, exit-preview-at-exit.png
and victory-before-result.png.

Sites confirms successful private version 6 publication at
https://hopan.fiiendward.chatgpt.site, with owner-only access preserved.

User-uploaded levels and audio could not be materialized (download failed).
The user explicitly deferred the four-level set for a later pass. No duplicate
recording or supplied level is claimed inspected or integrated.

--- Earlier validation history ---

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
