# Hopán title art — exact selected #6 and #4

The authoritative source is the original generated six-preview PNG retained in
`docs/previews/hat-variations/Hopan-hat-six-previews.png`, SHA-256
`2ae5269526c16b606ae0c79e5c31f18b89793133d60c04ca8320e5777ed99d80`.
The user selected #6 Wrapped Gold, with occasional #4 Layered Cloth. V37 redrew
those shapes and did not faithfully match the selected image; that approach is
superseded. No newly generated or redrawn frog/hat is used by this compositor.

Run `python3 tools/draw_splash.py` (Python/Pillow). It delegates to
`compose_selected_splashes.py`: crop #6 at `(1032,512,1524,968)` and #4 at
`(12,512,504,968)`; cut each original frog and hat together with an editable alpha
mask; place them at native pixel resolution on the retained sanctuary/water/rock
background. RGB values are never repainted, recolored or resampled. The complete
selected head/hat combination is retained rather than fitting it to a different
procedural head. Source scene pixels within the silhouette remain unchanged.

- `selected/{6,4}-source.png`: exact untouched source-panel crops, labels excluded.
- `selected/{6,4}-seam-mask.png`: binary cutout masks, with a one-pixel edge guard.
- `selected/{6,4}-foreground.png`: original source RGB plus the cutout alpha.
- `selected/{layout}/`: full-resolution editable composite layers.
- `hopan-{wide,compact,portrait}.ora`: #6 editable composite documents.
- `hopan-layered-{wide,compact,portrait}.ora`: #4 documents.
- `layers/{wide,compact,portrait}/`: retained low-resolution background masters;
  v37 frog/crown layers there are historical and not read by the compositor.
- `selected/source-pixel-proof.json`: every opaque hat sample equals the original
  source pixel in each of the six game PNGs (57,337 pixels for #6, 60,312 for #4).

Menu controls remain live Godot UI. The 15% #4 launch selection and stable session
choice are unchanged. Compare with `?splash=6` / `?splash=4` on the existing site.
The exported image and runtime keep nearest-neighbor presentation; no new motion,
gameplay hat/model, timing or save behavior is introduced.

See [exact-source correction](../../docs/EXACT_SPLASH_CORRECTION.md) for visual
comparison and checks. V37 artwork and its earlier proof remain in Git history;
its claim about preserving the old frog applies only to that superseded redraw.
