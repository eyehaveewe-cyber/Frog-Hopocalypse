# Recorded keyboard-click reduction

All 17 approved OGG voice cues use FFmpeg's autoregressive short-impulse repair:
`adeclick=w=55:o=75:a=2:t=2:b=2`. This interpolates detected brief impulses rather
than muffling the full recording with a low-pass filter. No silence gate, trim,
resample, pitch shift or loudness boost was applied. Synthesized hop/landing/boing
WAVs and gameplay code are unchanged.

The pre-cleanup OGGs and manifest are retained in
[`audio-originals/pre-keyboard-cleanup`](audio-originals/pre-keyboard-cleanup).
`python3 tools/clean_voice_clicks.py` always reads those originals, avoiding
cumulative filtering. Dependencies: FFmpeg/ffprobe and NumPy. Vorbis quality 6
limits additional encoding loss; this does not recover detail from the original
compressed recordings. The game manifest records both original and current hashes.

[Before](previews/voice-cleanup/before.wav) and
[after](previews/voice-cleanup/after.wav) concatenate the same phrases in manifest
order with 250 ms gaps. [Measurements](previews/voice-cleanup/measurements.json)
cover every bundled cue: exact decoded sample count, 24 kHz mono preserved;
no clipped samples; maximum absolute RMS change below 0.06 dB. Peak headroom
remains at least 2.88 dBFS before the existing player's additional 2 dB reduction.
Detected impulse samples occupy 1.96–4.32% of each clip. Those counts do **not**
identify individual keyboard clicks or establish subjective removal quality.

Independent human listening is unavailable in this executor. Keyboard noise
overlapping speech may remain; the comparisons permit listening acceptance and
the originals permit restoration if a consonant sounds softened.

Validation: all 19 voice cue/loading/gesture/queue/duplicate-death/mute/save checks
passed. The sound/checkpoint suite passed all three sound-toggle checks and 20
other checks, with one unrelated menu-entry assertion failure. An isolated
unchanged v33 worktree reproduced that exact failure (23/24), so it was not
introduced by filtering. No unrelated menu or checkpoint changes were made.
Seven Chromium touch/UA landscape browser checks passed with no console/page
errors: gesture unlock, nonzero output, visible sound control, editor hidden during
play, mute silence, persisted mute and restored audio. This is not physical
Safari/iPhone testing or subjective listening. [Browser results](previews/voice-cleanup/browser-results.json).
Web and Windows release exports built with Godot 4.7.2; Windows not executed.

Publication status and protected shared-Site hashes are recorded in
`VOICE_CLEANUP_PUBLICATION.json` after publication. Existing RiverSim and unrelated
hosted files must remain byte-for-byte unchanged. Rollback target: saved Site v33.
