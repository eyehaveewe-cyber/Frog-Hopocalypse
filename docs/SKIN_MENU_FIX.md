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
The exact completed checks are recorded in the browser result below. The extended
advanced-panel browser run is still in progress; its result will be refreshed
before publication. Microsoft
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
