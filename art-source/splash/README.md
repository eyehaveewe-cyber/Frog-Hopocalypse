# Hopán splash artwork — Wrapped Gold and Layered Cloth

The user selected **#6 Wrapped Gold** as the main title illustration and **#4
Layered Cloth** as an occasional alternate, from the generated six-hat concept
sheet in `docs/previews/hat-variations/`. Their shapes are now adapted in the
existing editable code-art source, [draw_splash.py](../../tools/draw_splash.py).
The concept sheet is not cropped and baked into the game. Outside the hat region,
the original frog and scenery pixels are preserved exactly in all six exports.

Regenerate with Python/Pillow: `python3 tools/draw_splash.py`. PNGs use 384×216 or
216×384 working pixels, exported at 4× with nearest-neighbor scaling. No new
animation or gameplay hat/model change is included. Screenwright and Motionwright
were available and read for this pass; the latter's scope was attachment/contact
and layer separation for this static illustrated character.

- `hopan-{wide,compact,portrait}.ora` / matching game PNGs: #6 Wrapped Gold.
- `hopan-layered-{wide,compact,portrait}.ora` / matching game PNGs: #4 Layered Cloth.
- `layers/{layout}/`: eight editable RGBA passes per composition, with cloth,
  frog and fitted crown on separate layers.

Side cloth is composited behind the eye lobes. Closed stripe polygons stay inside
its silhouette; the crown's continuous underside supplies a restrained contact
shadow. #6 has the domed crown; #4 has a lower crown and folded side edges. The
small upright ornament joins the crown rather than floating above its brim.
Both leave the eyes unobstructed. No hat motion or gameplay rig was changed.

The illustration is static; menu titles and controls remain live Godot UI.
#4 is selected on 15% of launches, #6 on the remaining 85%, using a separate
cosmetic RNG. Selection lasts for the app session, including menu returns and
resizes, and is not written to the save profile. Preview with `?splash=6` or
`?splash=4` on the website, or `--splash=6` / `--splash=4` in native user arguments.
These overrides select art only and do not alter gameplay or unlocks.

[Checks and screenshots](../../docs/HAT_SPLASH_VARIANTS.md). Historical first-pass
screenshots remain under `docs/previews/splash/`; current evidence is under
`docs/previews/hat-implementation/`. Physical iPhone/Safari/Edge and art-editor
import are unverified. The files remain editable without the generation service.
