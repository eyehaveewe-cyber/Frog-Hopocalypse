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
- Hosting and the requested `Hopan.chatgpt.sites` address. Native Sites tools are now available, but the official source/publishing helper is missing in this executor, and the 39,514,754-byte release WASM exceeds the stated static-file limit. No Site, version, access setting or deployment URL has been created or confirmed.

The implementation is a functional prototype of the requested game and editor. It is not being marked as fully complete version 0.1 while real-device criteria remain unchecked.
