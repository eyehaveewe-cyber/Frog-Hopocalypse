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

## Implemented

- Continuous WASD/arrow movement, animated hopping, physical collisions and an interchangeable pharaoh hat.
- Wandering critters, waypoint patrols, and projectile traps with configurable direction and interval.
- Critter, water and projectile deaths; immediate retry; victory with completion time, death count and next-level transition.
- Moonlit Oasis, Pharaoh's Courtyard and Violet Mire, reconstructed and saved through the editor's own operations. The oasis adds grassy canal paths and palms inspired by the supplied Frog Frenzy reference.
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

Requested address: `Hopan.chatgpt.sites`. It has **not** been reserved or published. On 2026-10-18, the official Sites account listing returned no Hopán Site. Native Sites tools are available, but this execution environment lacks their required official `site-workflow.mjs` source/publishing helper; the cloud skill also could not return that helper. No replacement uploader, Site registration or deployment was attempted. A real hostname must come from a successful Sites deployment result.

The complete `build/web` directory is the deployable browser artifact and requires a host supporting HTML, JavaScript, WebAssembly and Godot data files with correct MIME types. Publishing the cloud development environment does not deploy the game website. The optional RiverSim test belongs only under `/riversim/`, preserving this frog game at `/`. Its Library package could not be materialized by the supported helper in this environment, including after refreshing the transfer. Its reported oversized WASM and any gzip/Content-Encoding hosting behavior remain unverified here. See `UPDATES.txt` for current handoff status.
