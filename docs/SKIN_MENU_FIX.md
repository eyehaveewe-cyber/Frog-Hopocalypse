# Main-menu skin cycling

The Skin button previously called `show_menu()` from its own pressed callback.
That removed and queued the active menu controls for deletion, rebuilt the
menu, and deferred focus back to its first action on every color change. This
unnecessary UI replacement could interrupt the current mouse/touch/keyboard
interaction and reset scroll/focus. The user reported a menu crash; a full
engine crash was not reproduced locally, so that exact failure is not claimed
as independently reproduced.

Cycling now changes the frog's material and saved preference as before, then
updates only the existing Skin button's label. It keeps the active control,
menu scroll and focus intact. Leaving the menu clears its button reference;
returning creates a fresh valid control. No map, unlock requirement, hat,
audio, gameplay rule or save format changed.

Nine focused native checks pass, including 32 activations with a stable control,
focus and scroll position; save/reload; retained campaign progress and hat;
leaving/returning; and locked profiles. All 15 existing skin/palette/unlock
regression checks pass.

Five browser checks pass without console/page errors: 13 real mouse cycles,
four additional Enter activations, 13 touch taps, and desktop/touch save-reload
checks. Touch uses iPhone-size portrait/UA emulation in Chromium, after dismissing
the existing orientation prompt. It does not establish physical iPhone/Safari
behavior or independently confirm the original engine-crash cause.

[Browser evidence](previews/skin-cycle/results.json) ·
[Desktop preview](previews/skin-cycle/desktop-purple.png) ·
[Touch preview](previews/skin-cycle/touch-purple.png) ·
[Native checks](previews/skin-cycle/native.log) ·
[Palette regression](previews/skin-cycle/palette-regression.log).

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
