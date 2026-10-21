# Exact selected #6/#4 splash correction

The user correctly identified that v37 had approximated the chosen design rather
than using it. This correction uses the actual original six-preview PNG. There
is no new image generation or drawing of either selected hat or frog.

Authoritative source: `docs/previews/hat-variations/Hopan-hat-six-previews.png`,
SHA-256 `2ae5269526c16b606ae0c79e5c31f18b89793133d60c04ca8320e5777ed99d80`.
This matches the original locally generated preview and the already-uploaded
GitHub preview. #6 is cropped at `(1032,512,1524,968)`; #4 at
`(12,512,504,968)`, excluding panel labels. The original source pixels are
retained, together with each matching head and frog. This avoids repeating the
failure of fitting an approximated hat onto a different illustrated head.

`tools/draw_splash.py` now delegates to `compose_selected_splashes.py`. It copies
the source RGB pixels at native resolution, adds a binary cutout mask with a
one-pixel edge guard, aligns the feet on the retained stone, and composites over
the retained sanctuary/water background. No RGB colors are redrawn, recolored,
blurred or resampled. The original decorative glints are masked away from the
selected character so they cannot change its colors. Godot still presents the
finished texture with nearest-neighbor scaling.

The actual source crops, alpha masks, full-resolution composite layers and six
OpenRaster documents are retained under `art-source/splash/selected/` and its
parent directory. Older v37 vector frog/crown layers are historical; the active
compositor reads only their untouched background masters and quiet-field layer.

## Comparison and verification

[Original #6 / v37 / corrected runtime](previews/exact-splash/6-source-v37-corrected.png)
and [the same comparison for #4](previews/exact-splash/4-source-v37-corrected.png)
show the actual selected domed crown, ornament and broad stripes in the corrected
runtime. Both source crops and all six in-game browser layouts were visually
inspected. The v37 comparison is its saved release-render screenshot, from the
version confirmed deployed by Sites; it is not a new external live capture.

- Every opaque hat sample in each exported game PNG equals its original source
  RGB bytes: 57,337 samples for each #6 layout and 60,312 for each #4 layout.
  [Per-export coordinates and hashes](../art-source/splash/selected/source-pixel-proof.json).
- Desktop browser hat pixels match the source-derived asset's expected texel or
  immediate neighbor exactly. This accounts only for GPU/Pillow rounding at
  scaled nearest-neighbor boundaries, not recoloring or a different design.
  [Runtime color comparison](previews/exact-splash/runtime-source-color-proof.json).
- All 17 native title-selection/layout/profile/gameplay-entry checks pass.
- Six Chromium mouse/touch scenarios pass: #6 and #4 each on desktop, phone-size
  landscape and portrait; playable Baby Mode and the same artwork on menu return.
  No console/page errors. [Results](previews/exact-splash/browser-results.json).
- Godot 4.7.2 Web release, debug Web and Windows exports built. Windows not run;
  Chromium phone-size emulation is not physical iPhone/Safari/Edge validation.

The title selection logic is unchanged: #6 is default, #4 has a 15% cosmetic
chance once per launch, and `?splash=6` / `?splash=4` preview the two directly.
There are no gameplay-code, timing, level, audio, unlock or profile-format edits.

The publication baseline is Site v37, source
`21933cc0ac607ce7ee7a539481cbb99911448b9b`, including RiverSim 0.4.4. All 17 protected
files, the hosting manifest and compressed engine are preserved exactly in the
published artifact. The archive PCK equals the locally tested release. Both
packaged release hat regions match the source-verified debug render pixel-for-pixel,
and both release overrides start without errors with the debug probe absent.
[Release source proof](previews/exact-splash/release-source-proof.json).

Published **v38** successfully on October 21, 2026; native Sites returned a
successful production deployment. A direct hosted inspection was attempted once
and failed at the executor proxy with CONNECT HTTP 403. Therefore the visual
acceptance above covers the source and corrected local running/packaged game;
no external hosted visual inspection is claimed. No denial was bypassed.
[Publication and v37 rollback evidence](EXACT_SPLASH_PUBLICATION.json).
