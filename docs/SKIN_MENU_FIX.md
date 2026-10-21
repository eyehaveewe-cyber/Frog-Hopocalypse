# Skin and hop-feel menu cycling

The Skin button previously called `show_menu()` from its own pressed callback.
That removed and queued the active menu controls for deletion, rebuilt the
menu, and deferred focus back to its first action on every color change. This
unnecessary UI replacement could interrupt the current mouse/touch/keyboard
interaction and reset scroll/focus. The user reported a menu crash; a full
engine crash was not reproduced locally, so that exact failure is not claimed
as independently reproduced.

The animation and Soft/Retro sound selectors had the same self-rebuilding
callback. The user reported intermittent blank, stretched panels in Edge and
supplied screenshots showing the background still rendered while menu contents
were absent. Both advanced selectors now retain their existing controls and
update only their labels; sound changes still clear the previous audition. The
volume slider and panel contents remain alive.

Skin cycling now changes the frog's material and saved preference as before, then
updates only the existing Skin button's label. It keeps the active control,
menu scroll and focus intact. Leaving the menu clears its button reference;
returning creates a fresh valid control. No map, unlock requirement, hat,
audio, gameplay rule or save format changed.

Fifteen focused native checks pass, including 32 skin activations with a stable control,
focus and scroll position; save/reload; retained campaign progress and hat;
leaving/returning; locked profiles; 80 advanced animation/palette changes with
bounded panel height and stable contents/focus/slider; retained volume; audition
cancellation; and Pause access. All 15 existing skin/palette/unlock regression
checks and 51 hop/audio checks pass.

Extended browser validation covers the supplied 2465 × 1311 window size,
repeated mouse and Enter activation, editor → Menu → Hop feel access, and
portrait touch compatibility. It checks panel contents and bounded height on
every advanced-setting change, as well as retained skin/hat/progress on reload.
Eight browser checks passed without console/page errors: 46 skin selections and
96 advanced-setting changes across main-menu, editor-backed menu and touch
contexts, plus return navigation and reload. The result record is linked below. Microsoft
Edge itself is not installed here; Chromium tests are not a claim of direct Edge
or physical iPhone/Safari acceptance. The original full engine crash was not
independently reproduced; the known destructive menu callbacks were removed.

[Browser evidence](previews/skin-cycle/results.json) ·
[Desktop preview](previews/skin-cycle/desktop-purple.png) ·
[Touch preview](previews/skin-cycle/touch-purple.png) ·
[Native checks](previews/skin-cycle/native.log) ·
[Palette regression](previews/skin-cycle/palette-regression.log) ·
[Audio regression](previews/skin-cycle/audio-regression.log).

```sh
XDG_DATA_HOME=/tmp/hopan-skin-check bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/skin_cycle.gd
XDG_DATA_HOME=/tmp/hopan-skin-regression bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/skin_variants.gd
bash tools/build.sh --with-browser-test
python3 -m http.server 8068 --directory build --bind 127.0.0.1
# In another terminal with local Playwright/Chromium:
node tools/skin_cycle_smoke.cjs
```

Web/Windows release and debug Web exports build with pinned Godot 4.7.2.
Windows was exported, not executed. Publication uses the existing Hopán Site
and preserves all current RiverSim and unrelated files. Exact publication IDs,
rollback and preservation evidence are recorded after deployment.

## Published version

Site version **33** was published successfully on October 21, 2026, from source
`c61fdd10218651edc7e497fa9d39388a01189bcd`. The prior approval hold was resolved
by explicit user authorization; the single retry succeeded. Before publication,
the official workflow confirmed no intervening source changes and all 17 protected
files matched live v32. RiverSim 0.4.2, the compressed engine and hosting manifest
are preserved. Rollback target remains v32, which includes the current RiverSim.
Native Sites confirmed successful production deployment; external runtime inspection
remains limited by the executor's CONNECT proxy. Staged release startup and the
cycling checks above passed. [Publication record](MENU_CYCLING_PUBLICATION.json).
