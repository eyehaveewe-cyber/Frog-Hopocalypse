# Tile color in the level editor

Choose **Paint color**, pick a color below the tools, then click or drag over floor, path, wall, or cheese-wall tiles. Right-click a painted tile to restore its original appearance. One drag is one undo step. Painting does not remove objects or change collision. Replacing terrain clears the previous tile color.

Colors are stored as optional per-cell `tile_colors` in the saved level JSON. Older levels without this field retain their original appearance. Colors tint the existing texture, so the resulting shade depends on that texture and lighting.

Verified with native tests for editor strokes, undo, saving and playtest return, JSON validation, normal and compatibility materials, and existing route controls. `docs/tile-paint/browser-painted.png` shows the default paint applied with real browser clicks. Physical touch and all themes have not been independently checked.
