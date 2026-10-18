# PS1-style Frog Frenzy direction

The user's supplied Frog Frenzy and PS1 Frogger images establish the presentation direction: a visible three-dimensional frog near the foreground, a fixed-angle camera looking into the level, richly patterned grassy paths and water, chunky scenery and an expressive arcade mood. The overhead construction view is retained for maps and editing. A bonus 2D game mode is a future possibility.

## Implemented visual foundation

- Perspective gameplay on desktop and mobile, with a fixed north-facing view and smooth following. The frog remains freely movable; this change adds no grid-locked movement or jumping mechanic.
- Original 32 × 32 textures for grass, moss, brick, carved stone, water, bark, leaves and frog skin. Nearest sampling retains visible texels.
- A reduced-resolution 3D render, nearest enlargement, 5-bit RGB quantization, ordered dithering, gentle projected vertex snapping and vertex-lit materials. Interface text remains sharp.
- Faceted frog body, broader head, amber eyes, splayed toes, moving hind legs and a ground-contact shadow. The existing pharaoh hat attachment remains functional.
- Low-poly palms and violet fronds, animated canal water, perimeter masonry, distance haze and a night backdrop.
- Moonlit Oasis, an editable grass-and-canal course with a centered start and alternative routes. Pharaoh's Courtyard and Violet Mire remain playable with the new materials.

The textures and meshes are original procedural art. The supplied images guide composition and mood; their game assets are not embedded in this project.

Current production build: [perspective gameplay](images/ps1-oasis.png) and [paused overhead map](images/overhead-map.png).

## Overhead view

**M / Map** freezes the world and opens the overhead map at full interface resolution. **M / 3D view** returns to perspective play. The level editor uses the overhead view for accurate painting, waypoint drawing and object selection. Both views use the same level data and physics world.

## Future work

Further character/art polish, richer theme-specific landmarks, active-hazard difficulty playthroughs and real iPhone Safari checks remain. A bonus 2D mode can reuse the level format and overhead camera, but needs its own controls, readability and content pass before it is a finished mode.
