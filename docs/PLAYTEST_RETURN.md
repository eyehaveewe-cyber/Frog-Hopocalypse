# Return to the level editor

During a level-editor playtest, the upper-left play area has a clearly labelled **Back to editor** button. The pause and win/loss panels offer the same action. It reopens the current edited level without discarding unsaved edits or opening the leave-editor prompt. It remains available during the overhead map and exit preview. Normal campaign play does not show this control.

Ten native checks verify visibility, the map, paused/completed return paths, preservation of unsaved level edits, and isolation from normal campaign play. The Chromium test clicks the actual playtest return button and captures the editor reopened. See `docs/playtest-return/` and `game/tests/playtest_return.gd`.
