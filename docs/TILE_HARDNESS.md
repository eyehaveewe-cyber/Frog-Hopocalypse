# Harder Tile Hop tour

The user's target is roughly 2½ times harder. This pass increases active hazard placements from 24 to 60, with encounters placed at landings, collection routes and formerly safe bypasses. That budget ratio is exact; it is not a measured human difficulty multiplier. Human play will determine whether further tuning is needed.

All five stages keep their rule, stage ID, NAHAIL unlock and one checkpoint. Free hops still teach timing; fragment and seed routes put collection under pressure; the 25-hop stage keeps forward recharge circuits and side pockets to change hazard phase. Linked-time darts fire every three accepted hops to avoid a two-beat parity trap.

The Seed Vault shooter at (3,19) now faces east toward cheese at (8,19). All 21 shooters face actual cheese through clear firing lines. Physics ray checks cover their barrels, wall occlusion and cheese colliders; live projectiles pass through cheese in all four orientations.

Validation: 98 dart/layout checks and 38 resource checks pass. Five fresh ordinary-input, hazard-active runs finish, followed by five successful checkpoint retries. The last stage uses an alternate retry route because hazard reset changes the encounter phase. Native routes run at a fixed 60 Hz and use no invincibility, teleport or restored-world oracle. Test-only lookahead helped author the fixtures; the checked-in acceptance runner independently replays normal input from fresh loads.

Eight desktop/touch Chromium checks pass without browser errors, including Space and real touch fragment collection/long-hop use. Map and perspective screenshots are in [previews](previews/tile-hardness/). Physical iPhone, Safari, human feel and real-device frame rates remain unverified. Web release, Windows release and Web debug exports build with pinned Godot 4.7.2.

Run `bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/harder_darts.gd` and `--script res://tests/harder_replay.gd`. The old route entrypoints now call the current five-stage replay. Rebuild layouts deterministically with `python3 tools/design_tile_tours.py`. [Machine-readable evidence](TILE_HARDNESS_VALIDATION.json).

Publication uses the existing public Hopán Site; RiverSim and hosting adapters remain byte-identical. The confirmed rollback is version 25, recorded in [the previous publication](TILE_TOURS_PUBLICATION.json). Publication IDs for this pass are recorded after deployment in TILE_HARDNESS_PUBLICATION.json.
