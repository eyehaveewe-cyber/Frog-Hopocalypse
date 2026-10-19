# Editable backdrop bake

Original geometry remains in `game/scripts/landmark_models.gd`. This bake uses
its triangles, vertex colors and normals; no external model, photo or image
service is involved. `models.json` is the retained source snapshot.

Regenerate from repository root:

```sh
bash tools/godot.sh --headless --script res://tools/export_backdrop_models.gd
python3 tools/bake_backdrops.py
```

The Python rasterizer needs NumPy and Pillow. It applies a fixed three-quarter
view, software z-buffer, palette quantization and transparent-bound cropping.
Five outputs in `game/art/backdrops` are byte-identical on a repeated bake in
the tested environment. `bake-metrics.json` records dimensions, logical RGBA8
bytes and nontransparent texel counts. Change the model kit or camera/palette in
the script to author another view; these are fixed world cards, not billboards.
