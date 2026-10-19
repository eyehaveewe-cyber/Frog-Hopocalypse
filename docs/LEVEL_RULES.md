# Per-level rule sets

The user's direction is **variety rules on individual levels**, rather than a
separate global charged-hop mode. Current campaign maps retain their rules and
layouts. The editor now chooses Free long hops / Charged long hops, with a
1–25 ordinary-hop recharge setting (default 10). Tile-hop mode and Move with me
remain per-level settings; Move with me also works in regular Hopán.

## Player flow and wording

At stage start, show only rules this device/profile has not acknowledged before.
The game clock, hazards, input and exit-preview sweep wait for dismissal. The
notice has no reading timer or flashing animation. Retry does not repeat it.
`Rules` is a translucent, 72×44 game-UI target below the header; F1 also opens
the active rule set. Back / Escape / Enter / Space close the card. Returning
from rules preserves map or pause state. Editor controls remain on the menu/editor
route; no gameplay editor shortcut was added.

Rule identities include their version and, for charge rules, the recharge count.
The acknowledged identities persist through the existing native profile and
immediate browser backup. A new count is a new rule; changing levels with already
known rules does not repeat the introduction. Reopening Rules lists all active
rules; the first-time notice lists only new ones.

Copy was edited for literal, short instructions rather than a theatrical preamble:

- **TILE HOPS:** Hop one tile with a direction. Use Shift or Long hop to jump two.
  Walls stop both.
- **FREE LONG HOPS:** Long hop whenever the frog is ready. No charge needed.
- **CHARGE YOUR HOPS:** 10 short hops recharge one long hop. Start charged.
  Checkpoint retries refill it.
- **MOVE WITH ME:** Stop to freeze the hazards. They move when you move.

No separate tool named Anti-slap/Anti-slop was available; this was a direct
plain-language edit. No claim of a separate plugin review is made.

## Sharp, dripping text

`game/art/rules/hopan-rule-ink.ttf` is an original editable display alphabet,
drawn from explicit glyph grids and sharp contours in
`tools/draw_rule_lettering.py`. It has pointed baseline drips and no animation.
Short headings use it; the instructional body keeps the regular game font.
This translates the requested jagged/runny quality into original lettering,
without claiming an exact match to the uncertain named reference.

Regenerate with Python 3 and fontTools (`python3 tools/draw_rule_lettering.py`).
fontTools 4.61.1 was used. It is an authoring dependency, not a game dependency.
The glyphs contain no third-party font outlines. The source remains editable;
the rules are real text, not baked into a raster image.

## Charge semantics and editor data

```json
"game_mode": "tile",
"move_with_me": true,
"rules": {"long_hop": "charged", "charge_hops": 10}
```

Missing rules preserve legacy free hopping. `long_hop` is `free` or `charged`;
`charge_hops` is an integer 1–25. Malformed/unknown rule entries are rejected.
Charge settings remain stored but inactive in regular Hopán, so switching modes
does not discard the author's choice. Undo, portable JSON, manual saves and
editor recovery carry the settings with the level.

Charged levels start full. A valid long-hop takeoff spends one reserve. Only
completed ordinary-hop landings advance recharge; long hops, rejected inputs,
idle time, maps/menus and log carrying do not. Back-and-forth hops count. A full
reserve stays full until spent. Empty long-hop attempts do not move or advance
Move with me's beat; the touch control cannot arm while empty. The existing
indicator shows `10 TO GO`, counts down, then returns to READY / ARMED.
Retry rebuilds the level and restores a full reserve, including checkpoint retry.

The existing structural exit-path check does not model charge state or dynamic
hazard timing. Authors must playtest required crossings and leave space to
recharge; isolated one-cell landings can otherwise make an authored charged map
impossible. Existing campaign water-hop chains are deliberately left free.

**Charge Trial** is available via Editor → Movement demos → Charge Trial · 10 hops
→ Playtest. It starts charged, crosses a water row, provides ten ordinary hops
and a checkpoint, then crosses the second water row. It is an editor test map;
the NAHAIL unlock rule and campaign stage list are unchanged.

## Verification and delivery

- 35 focused rule tests: first-seen pause, remembering/reload, changed-rule-only
  introduction, manual reopen, charge/blocked/idle/landing/threshold behavior,
  checkpoint retry, free and regular modes, editor controls, Undo, JSON validation,
  map-state return, and a complete 20-hop Charge Trial with its checkpoint.
- 52 tile-mode and 23 editor/recovery regression checks pass.
- Five existing hazard-active route variants still complete without changed maps:
  both tile levels, delayed traffic entry, the vault shortcut and regular Garden.
- Six browser checks pass with no console/page errors: desktop keyboard and
  Android-UA touch emulation exercise notices, Rules, recharge HUD, completed
  trial, and persistence across reload. Screenshots in `previews/rules/` were
  inspected at desktop and phone-landscape sizes.
- Web release/debug and Windows release exports build. No physical iPhone,
  Safari, assistive-technology or first-time human comprehension test was run.

Branch `feature/per-level-rules` follows the unpublished splash branch. Nothing
was merged or deployed; public v22 and main are unchanged. Revert this feature
commit to remove it. Export custom maps before returning to v22: that older
reader ignores the new rules field, so a charged map would play with free hops.
