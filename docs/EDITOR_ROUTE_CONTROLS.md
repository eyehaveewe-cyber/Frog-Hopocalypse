# Patrol route editing and editor zoom

Patrol route mode draws constant-size numbered flags and high-contrast connecting lines over the 3D view. Terrain and tall objects cannot hide these screen-space annotations. Start is labelled separately; looping routes retain the existing last-waypoint-to-first-waypoint connection. Only the selected critter, patrol car or spike ball is annotated while drawing its route.

**Accept route** ends route editing, keeps the waypoints in the current level and hides the route annotations. Changing tools, deselecting the actor, entering playtest or opening an overlay also hides them. Adding points retains the existing terrain/segment validation and undo behavior; Accept is not a disk-save operation. Save the level normally for persistence.

The editor offers **Zoom in +**, **Zoom out −** and **Fit level**, plus mouse-wheel zoom over the 3D view. Zoom is centred on the level, bounded to 0.35–3 times its fitted scale and retained across editor rebuilds. It does not change the play camera. Flags retain 16 px text, 24 px flag height and 3 px route lines as the view scales. Points outside the visible viewport are clipped, rather than incorrectly shown at a different map location.

Eight native checks verify projected waypoint presence, Accept visibility/data retention, zoom and zoom restoration, deselection cleanup and retained zoom across rebuilds. The previous ten playtest-return checks still pass. The browser test places a critter, draws a patrol through normal UI inputs, operates zoom controls and accepts the route, without captured errors. Screenshots in `docs/editor-route-controls/` were visually inspected. Physical touch devices and dense clusters of many overlapping flags remain untested.

### Camera dragging and occupied route cells

Middle-drag or Shift + right-drag pans the editor camera at its current zoom.
Right-click retains erase. Fit level resets both pan and zoom. Rebuilds retain pan;
focus loss releases the drag. The shortcut is visible beside the zoom buttons.
Route annotations explicitly draw at UI z-index 100 and ignore mouse input, so
terrain and scenery cannot occlude them or consume waypoint clicks. Occupied dry
cells remain available to routes subject to each actor's existing path rules.
This does not make walls or water traversable.

Verification: 13 native route/camera checks, the existing 10 playtest-return
checks, and an actual Chromium middle-drag/route/accept flow. See `panned.png`.
Software rendering is not physical mouse or touch hardware verification.
