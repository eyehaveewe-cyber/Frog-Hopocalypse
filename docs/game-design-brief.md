# Hopocalypse: Pharaoh Frog Hopán
## Version 0.1 — Initial Game & Level Editor Design Brief

**Engine:** Godot 4.7.2 stable  
**Platforms:** Windows desktop and iPhone (browser-first)  
**Genre:** 3D arcade maze / obstacle avoidance  
**Inspiration:** 3D Frog Frenzy, Warcraft III's Run Kitty Run, classic Frogger  
**Primary development priority:** Playable, reusable level editor

### 1. Game concept

Hopocalypse is a colorful, slightly absurd 3D frog maze game featuring dangerous critters, environmental hazards, and increasingly elaborate mazes.

Players guide a small, customizable frog through winding passages, avoid enemies with deliberately simple AI, and reach the exit without getting killed.

The game emphasizes quick reactions, learning enemy movement patterns, short retries, and exploration. Its tone combines cute animal characters with dramatic, comically abrupt deaths.

Environments draw inspiration from ancient Egypt, Honduras, Mexico, and strange fantasy locations, including glowing purple swamp-woods.

The initial release should be a **small but complete playable demonstration**, built using the same level editor intended for future development.

### 2. The level editor — highest priority

Build a functional editor inside the game, initially optimized for mouse and keyboard.

The editor should enable someone with no programming experience to construct new playable levels without relying on AI.

**Required features:**
- Create, name, save, load, and duplicate levels.
- Paint floors, walls, water, paths, and solid obstacles onto a grid.
- Place and remove 3D scenery and collision-enabled objects.
- Place frog starting positions and victory destinations.
- Place critters and choose their behavior types.
- Place projectile emitters and configure direction and firing interval.
- Draw basic enemy patrol routes with waypoints.
- Rotate objects and adjust simple object properties.
- Undo/redo basic editing actions.
- Instantly switch between Edit and Playtest modes.
- Return from playtesting without losing edits.

The editor uses a grid to arrange level geometry, but **the frog and critters move freely in 3D**. They must not be restricted to individual tile movements.

Map data should be saved independently of game code in a portable, versioned format such as JSON. Custom levels should use the same loading and gameplay systems as the bundled levels.

The editor is the foundation for all future world-building and content additions.

### 3. Core player mechanics

- Third-person elevated camera with a mostly fixed viewing angle.
- Smooth directional movement using WASD, arrow keys, or virtual joystick.
- Responsive controls suitable for narrow passages and quick dodging.
- Small animated frog with idle, movement, and death animations.
- Real collision with walls, trees, pillars, and other solid objects.
- Contact with deadly critters instantly kills the frog.
- Water and projectile hazards have their own death conditions.
- Deaths allow immediate retry, without lengthy loading or animations.

The 0.1 build does not require combat, inventory, character statistics, or upgrades.

A dedicated jumping mechanic may be introduced later; animated hopping is enough for initial movement if it helps complete the core systems sooner.

### 4. Critters and simple AI

Critters are the principal moving obstacles, inspired by the chaotic enemy behavior of Run Kitty Run.

Implement two initial AI modes:

**Wander:** The critter chooses directions periodically, moves independently, and reacts to walls or obstacles.

**Patrol:** The critter follows an assigned path between editor-defined waypoints.

Behavior should be simple, readable, and occasionally unpredictable without feeling unfair.

Initial critter assets can include scarabs, snakes, lizards, chickens, or swamp creatures, with shared AI and collision components.

Every critter must have a visible 3D body and an appropriately sized lethal collision shape.

The game should support numerous critters in the same maze, with an initial test target of approximately 20 moving enemies on screen, subject to iPhone performance.

Future versions can add chasing, bouncing, territorial behavior, and enemy interactions.

### 5. Collision, hazards, and death screens

All gameplay assets must have appropriate collision behavior from the beginning.

| Object | Required behavior |
|---|---|
| Wall / pillar / tree | Physically blocks player and critters |
| Critter | Instantly kills player upon contact |
| Water / pit | Triggers fall or splash death |
| Projectile | Travels through the level and kills player on impact |
| Projectile emitter | Fires at configurable intervals |
| Decoration | Nonblocking unless designated solid |
| Exit marker | Triggers victory when reached |

**Death states:**

- **Critter death:** Contact animation and an immediate "CROAKED!" screen.
- **Water death:** Frog falls or sinks, splash effect, and "SPLASHED!" screen.
- **Projectile death:** Impact effect, knockback or brief hit animation, and "HIT!" screen.

Each death screen includes a prominent **Retry** button and a return-to-menu option. Retrying resets the frog, critters, and projectiles.

Deaths should be comedic and quick, not graphically violent.

Projectiles must interact with solid world geometry instead of traveling through walls.

### 6. Victory and level completion

Every level must have an editor-placeable exit object.

When the frog reaches the exit:

- Movement stops and a victory effect plays.
- A **LEVEL COMPLETE!** screen appears.
- Display completion time and number of deaths.
- Provide Retry, Next Level (when available), and Menu options.

Levels must be completable from start to finish, with working transitions back to the menu.

### 7. World art and theming

Use cheerful low-poly 3D assets with distinctive colors and readable silhouettes. Prioritize strong visual communication over high polygon counts.

The level-editor asset library should be expandable through theme packs.

**Initial art priorities:**

- **Egypt:** Sandstone corridors, pillars, desert ruins, scarabs, and pharaoh-inspired hats.
- **Honduras:** Jungle terrain, vine-covered stone, river obstacles, and Maya-inspired architectural elements reflecting places such as Copán.
- **Mexico:** Bright courtyards, colorful walls, plazas, cactus gardens, and roaming animals.
- **Purple Swamp-Woods:** Violet foliage, crooked trees, mushrooms, glowing plants, dark water, and misty paths.

For 0.1, fully assemble only two small visual kits: **Egyptian ruins and Purple Swamp-Woods**. Honduras and Mexico should be represented in the asset/theme roadmap, with their full sets developed in subsequent releases.

Assets should be modular so that multiple mazes can reuse the same components.

### 8. Frog hats and cosmetics

Build a simple hat attachment point into the frog character and provide at least one working interchangeable hat.

The initial collectible cosmetic should be a small pharaoh's headdress, with future options including explorer hats, mushroom caps, flower crowns, sombreros, and wizard hats.

Hats have no gameplay effects in 0.1. A hat selection screen and additional rewards may be introduced later.

### 9. Initial demo content

Provide two small handcrafted sample levels, both built and saved through the integrated editor.

**Demo Level A — Pharaoh's Courtyard**

An Egyptian-inspired stone maze introducing walls, wandering scarabs, patrolling snakes, a projectile trap, and an exit.

**Demo Level B — Violet Mire**

A purple swamp-woods maze featuring twisting paths, wandering swamp critters, lethal water, and a finish marker.

The levels should be short enough to replay quickly, while containing meaningful route choices and opportunities to learn enemy behaviors.

### 10. Interface and mobile requirements

The game must be playable on iPhone, preferably through Safari without an App Store installation for the first demonstration.

- Landscape orientation.
- Responsive menu and victory/death screens.
- Virtual directional joystick.
- Touch-friendly Retry and Menu buttons.
- Adjustable display scaling for different screen dimensions.
- Low-poly, lightweight rendering designed around mobile performance.
- Pause behavior when leaving the browser tab.
- Early testing on an actual iPhone.

**Scope distinction:** The level editor only needs a polished desktop interface in 0.1. The resulting levels must be playable on iPhone. Touch-based editing can come later.

### 11. Technical architecture

Use Godot 4.7.2 with GDScript and a mobile/web-compatible rendering configuration.

Separate the major systems into reusable components:

- Level Editor and Map Serialization
- Modular World Asset Library
- Frog Player Controller
- Critter Movement and AI
- Collision and Hazard System
- Projectile System
- Death and Victory State Manager
- Level Loader and Menu UI
- Cosmetic Attachment System

Prefer shared behavior components and data-driven content rather than scripts duplicated for every critter or level.

All assets intended to block movement or cause death must have correctly configured collision shapes and masks. Add basic automated or repeatable tests where practical.

### 12. Explicit exclusions from 0.1

Do not spend initial development time on:

- Multiplayer or cooperative revival
- Procedural level generation
- Combat, equipment, or RPG progression
- Complex enemy intelligence or pathfinding
- Large open worlds
- Online level sharing or accounts
- Full costume customization
- Sophisticated physics simulation
- Elaborate cinematics or story sequences

These are future considerations, not prerequisites.

### 13. Completion criteria for version 0.1

Version 0.1 is considered complete when:

- [ ] A user can create and save a 3D maze using the in-game editor.
- [ ] The editor can reload that maze with objects and settings intact.
- [ ] Wall, water, enemy, projectile, spawn, and exit placement work.
- [ ] Playtesting begins directly from the editor.
- [ ] The frog moves freely and cannot pass through solid objects.
- [ ] Wandering and patrolling critters behave independently.
- [ ] Touching a critter causes immediate death.
- [ ] Falling into water produces a splash/death sequence.
- [ ] Projectile impact causes an appropriate death.
- [ ] Death screens correctly allow retry.
- [ ] Reaching the exit triggers a victory screen.
- [ ] At least two themed demonstration levels are playable.
- [ ] The frog can wear an interchangeable cosmetic hat.
- [ ] The game can be loaded and controlled on a real iPhone.
- [ ] Returning to the editor preserves saved content and allows further editing.

**Development principle:** Build a small, genuinely complete game first. The real product of 0.1 is a usable arcade-maze construction system, accompanied by a playable demonstration of what that system can produce.