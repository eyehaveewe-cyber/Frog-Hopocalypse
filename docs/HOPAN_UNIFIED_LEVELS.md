# Frog menu and shared level collections

The illustrated frog returns to the main screen. **Explore levels** groups the NYC, Streetlife, Ancient Ruins, Baby Mode, Not as Hard as It Looks, Bonus, Tile Hop and Moves When You Move collections. A player picks a collection and then a level. The previous progression gates still apply. **Frog outfits & other saved levels** opens the earlier outfit and editor controls.

The two source lines had diverged from their original common commit. The most recent NYC main does not contain the older Tile Hop, Bonus, Baby Mode, outfits or earned progress. This release keeps the two existing game runtimes beneath one menu so both sets remain playable; it does not claim they were merged into a single engine or that outfits work on every NYC level.

## Saved levels and progress

The older game keeps its original library, profile and localStorage keys. The NYC editor has a separate library. On first use, the full older library is copied without changing the original. Unknown records are retained, malformed data is not overwritten, and each editor uses a durable browser mirror before asynchronous filesystem sync. Subsequent edits in one editor do not automatically update the other editor's copy. Export JSON for a portable backup.

The browser storage test uses actual editor saves and an earned profile across the two runtimes on the same origin. It checks first-copy behavior, an immediate reload and that an NYC edit leaves the older library intact. The test does not reconstruct any records overwritten before this change, and it does not establish cross-device synchronization.

## Verification

The current NYC source's normal native suite passes 217 checks. The NYC library helper has 25 focused checks for migration, conflicts, malformed storage, unknown records and persistence. The older source has dedicated save and collection suites; its broad historical suite reports three failures also present on unchanged `bdedcb9`. A separate scene diagnosis confirms those are stale assertions for the editor's unsaved-work prompt and its current preview-camera offset.

The integrated browser checks cover the restored frog screen at desktop, landscape and portrait sizes, all eight collection entries, opening an older stage, returning to collections, NYC gameplay and editor saving. Browser checks use Chromium WebGL and touch emulation; physical phone and controller testing remain open. [Main screen](publication-menu-sync/menu-desktop.png) · [Baby Mode collection](publication-menu-sync/baby-collection.png).

Both Godot Web exports use the existing streaming-gzip loader and run under the same Site origin. The older runtime is hosted under `/classic/` as an implementation detail; the player chooses its levels directly from the collection menu. The existing RiverSim route and other hosted content are preserved by the packaging check. Source commits and publication receipt are recorded after the release is verified.
