**Frog menu and level collections:** The illustrated frog is back. Explore levels groups the NYC and earlier level sets in one menu, with their existing progression gates. Earlier outfits and saved levels remain accessible. [Versions, save safeguards and verification](docs/HOPAN_UNIFIED_LEVELS.md).

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

## NYC Streetlife six-level set

Choose **Start NYC Streetlife · 6 levels** on the main menu. The new set is a
separate six-stop campaign: Stoop Patrol, Newsstand Weave, Ferry Railwalk,
Banked Boulevard, Sanitation Courts and Block Party. Each level uses a different
route decision, progressing from slow roach gates to supported grind lines,
banks and combined street crossings. Next level stays within the set; finishing
Block Party offers a complete-set replay. All earlier maps remain selectable.

See [level design and progression](docs/STREETLIFE_SET.md) and
[validation](docs/STREETLIFE_SET_VALIDATION.md).

## Implemented

- Continuous WASD/arrow movement, animated hopping, physical collisions and an interchangeable pharaoh hat.
- Wandering critters, waypoint patrols, and projectile traps with configurable direction and interval.
- Critter, water and projectile deaths; immediate retry; victory with completion time, death count and next-level transition.
- Brooklyn Skate Circle adds an 18-tile-diameter plaza, three articulated skateboard enemies riding ramps and rails, and six-legged roaches. Ten new street/skate assets also dress the NYC districts. See [the skate plaza](docs/NYC_SKATE_PLAZA.md).
- Five additional regular New York City maps progress from Central Park to Midtown Rush Hour. The fifth NYC map has eight opposing lanes of animated taxis, sedans, buses and delivery trucks, separated by safe medians. See [NYC maps and traffic](docs/NYC_LEVELS.md).
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
node tools/nyc_browser_smoke.cjs
node tools/streetlife_browser_smoke.cjs
node tools/streetlife_set_browser.cjs
```

The browser runner uses Playwright 1.62.1 and `/usr/bin/chromium` in this cloud environment. Set `HOPAN_CHROMIUM` or `HOPAN_TEST_URL` for another browser binary/server. Screenshots and exported test maps go into ignored `build/test-results/`. Native tests use an isolated temporary save library.

## Remaining validation and publishing

This is a first functional prototype. **Real iPhone/Safari testing**, Windows execution, broader accessibility work and gameplay/difficulty tuning remain. Emulated touch tests cannot establish iPhone performance or Safari compatibility. Honduras and Mexico theme kits remain on the roadmap. There is no combat, multiplayer, account system or online sharing.

Requested address: `Hopan.chatgpt.sites`. It has **not** been reserved or published; this session has no ChatGPT Sites publishing tool. The complete `build/web` directory is the deployable browser artifact and requires a host supporting HTML, JavaScript, WebAssembly and Godot data files. Publishing the cloud development environment does not deploy the game website.
