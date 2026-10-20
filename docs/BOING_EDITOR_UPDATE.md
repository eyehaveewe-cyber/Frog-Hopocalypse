# Long-hop boing, hop variety and editor protection

Jonathan requested a distinct long-hop boing, more pleasant ordinary-hop variety,
a Channel Hideo pass, a Save/No/Continue editor prompt, and road-placeable Hop
fragments. All are implemented in this source branch; publication IDs follow in
BOING_EDITOR_PUBLICATION.json after the deployment.

## Sound direction and implementation

Channel Hideo's actual direct-game-project skill was accessible and applied.
The direction is a readable cause-and-effect loop: a restrained, varied basic hop
and one recognizable spring sound for the more committed long hop. The user's
requests authorize implementation; numerical ranges and cue synthesis are
AI-origin implementation choices, not human-endorsed acoustic standards.

Long hop now uses three original 240 ms boings in both sound palettes. Menu/Pause
> Hop feel comparison includes Hear long-hop boing. Ordinary takeoff and landing
source files are preserved. Each cue group uses a separate shuffled set of its
three variants, avoiding immediate repeats even across refills. Basic takeoff
pitch varies +/-40 cents (about 2.3%), landing +/-25, boing +/-15. Gain variation
only attenuates, by up to 0.9 dB. Existing volume, mute, input unlock and speech
ducking remain in force; no queued tail resumes on unmute. Audio uses its own RNG.
The hop's movement timing, protections, controls and hazard difficulty are unchanged.

Industry-tool reference: Audiokinetic's Random/Sequence Container documentation
describes shuffle selection that avoids immediate boundary repetition:
https://www.audiokinetic.com/fr/public-library/2025.1.7_9143/?id=random_sequence_container_property_editor&source=Help .
Its Wwise-101 randomization lesson is at
https://www.audiokinetic.com/en/learning/videos/tue3azilcvc/ .
Primary search-index excerpts were available; full pages returned 403 in this
executor, and the video was not watched. These sources support the technique,
not the particular pitch/gain numbers or a universal studio norm. Subjective
pleasantness/comfort requires human listening. All new samples are original CC0;
[provenance and synthesis](../game/audio/hop/ATTRIBUTION.md).

Channel Hideo's separate DOCX-update step remains incomplete: its skill requires
rendering and inspecting every page, but this executor has no exposed Documents
renderer or LibreOffice. The existing Library working document was not replaced;
this repository note records the implementation and uncertainty without claiming
to be a validated DOCX deliverable. No extra consultant review was run.

## Editor leave guard

Menu, new-map replacement, loading another local map, importing JSON and loading
movement/scenery demos protect an active editor map. The three choices are
Yes - Save and leave, No - Leave without saving, and Continue editing (Escape
also continues). A local save is required to succeed before the pending action
runs. Validation/I/O failures retain the editor, old library and old saved file.
The in-memory library, slot ID and saved snapshot commit only after file write
and rename succeed. The prompt explains that local save is on this device and
JSON export is a portable backup.

Dirty detection compares the actual map with its last manual-save snapshot, so
Undo back to that state clears the prompt. New/imported maps and recovered
autosaves remain unsaved until a manual save. Editing a name is included.
Playtesting retains work without prompting; leaving an unsaved playtest is
protected. Continue from the main menu reactivates protection. Automatic editor
recovery checkpoints do not masquerade as manual saves.

A browser beforeunload flag is also set while the active map is dirty. The native
tab-close dialog was not confirmed in headless Chromium; browser-controlled
external navigation/closing is best-effort and cannot offer our custom three
buttons. The in-game navigation dialog is verified. Native OS window closure is
outside this browser-focused guard; save/export before closing desktop builds.

## Road fragments

Hop fragments can be painted on a road, and painting a road beneath an existing
fragment retains it. Validation and portable JSON accept this combination.
Water, solid terrain/objects, invalid coordinates and duplicate pickups remain
restricted. Hop seeds retain their safe-bank requirement. A safe road landing
collects a fragment normally; traffic remains lethal and a fatal crossing does
not award its pickup. No bundled stage layout changed.

## Focused evidence

51 native hop checks pass, including dedicated long-hop selection, preserved
ordinary takeoff, shuffle boundaries, bounded pitch/level variation and existing
hop timing/mute/unlock checks. 26 editor/road checks pass, including save/cancel/
discard, invalid-save and actual filesystem-write failure, intact prior files,
resume protection, Undo, JSON, road collection and lethal traffic. Browser
results are retained in previews/hop-feel/results.json and
previews/editor-leave/results.json. The physical iPhone/Safari and human comfort
limits remain; engine Web/Windows exports are built before publication.
