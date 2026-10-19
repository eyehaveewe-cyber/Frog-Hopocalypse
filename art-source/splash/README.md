# Hopán splash artwork — static first pass

Original manual pixel illustration, drawn with explicit shapes in
[draw_splash.py](../../tools/draw_splash.py). No image generation, stock images,
fonts baked into the raster, or animation. Palette and geometry are editable
in the script. Regenerate with Python 3 and Pillow (`python3 tools/draw_splash.py`).
Pillow 12.3.0 was used for this export; it is an art tool, not a game dependency.

Three compositions keep the existing frog recognizable: green squat body,
pale belly, raised gold eyes and the procedural character's gold/teal striped
pharaoh hat. A fictional Egyptian-inspired sanctuary, moonlit water and reeds
support the existing adventure theme. This is not a claim of historical accuracy
or a depiction of a specific site in Honduras or Mexico. No hybrid script or
borrowed sacred imagery is included.

- `hopan-wide.ora`: desktop illustration, six named editable RGBA layers.
- `hopan-compact.ora`: touch landscape, hero shifted left of the menu.
- `hopan-portrait.ora`: phone portrait, hero above the menu.
- `layers/`: the same layers as transparent PNGs, at working resolution.
- `../../game/art/splash/`: flattened 4× nearest-neighbor game exports.

The `.ora` files follow OpenRaster's layer-stack format for tools such as Krita
and GIMP. Their merged composites were verified against the game exports;
opening them in a desktop art application was not available in this environment.
Drawings reproduce byte-identical PNGs from the source script. Each canvas is
384×216 or 216×384 working pixels. Six passes separate sky, distant sanctuary,
water, stones/reeds, frog/hat, and the quiet menu field.

The full title is a UI treatment: **Pharaoh Frog** smaller, **Hopán** dominant.
It does not rename the project. Title text, level-set actions, expansion buttons,
settings, editor and continue controls remain Godot UI, separate from the image.
Menu panels have opaque-enough backing for steady contrast and scroll when
content exceeds the viewport. Existing keyboard focus/hover and touch targets
remain active. The first menu action receives keyboard focus; Tab and Shift+Tab
cycle within the menu. No decorative animation was added.

See [desktop preview](../../docs/previews/splash/desktop.png),
[portrait](../../docs/previews/splash/portrait.png),
[landscape](../../docs/previews/splash/landscape.png), and
[validation](../../docs/previews/splash/browser-results.json).
Phone views are desktop Chromium touch/Android-UA emulation; physical devices,
Safari, assistive technologies and art-editor import remain unverified.

Screenwright and Motionwright packages were requested as guidance but unavailable
in this execution context (`skill package is not available`). The implementation
therefore uses direct inspection and local drawing/UI verification.

This branch is for review. No merge, Sites packaging, save, or deployment occurred.
