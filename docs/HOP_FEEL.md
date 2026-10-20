# Tile frog hop sound and leg comparison

**Publication update:** now live as [Hopán version 27](https://hopan.fiiendward.chatgpt.site).
[Publication evidence and v26 rollback](HOP_FEEL_PUBLICATION.json). Earlier
repository-only statements below describe the source/testing phase.

Requested by Jonathan on 2026-10-20; implemented with the actual Motionwright
character-animation skill. Base: `156fdd4`; branch: `feature/hopan-hop-feel`.
Repository-only. The live Site remains v26 and RiverSim is untouched.

## Play the comparison

Open `game/project.godot` in pinned Godot 4.7.2, or serve the whole unzipped
standalone Web export over HTTP (for example, `python3 -m http.server 8000`
inside its folder). Select **Hop feel comparison** from the main menu or Pause.
Choose **Smooth** (default) or **Stepped · 12 poses/s**, **Soft** or **Retro ·
original**, and a hop-volume value. The audition button plays one takeoff and
one landing; repeated auditions cancel the previous pending pair. Return to the
same tile map to compare. All four combinations are playable. Choices last for
the session; existing Sound Off/On is the saved global voice/effects preference.

[Comparison images, GIFs, MP4 and sound pairs](previews/hop-feel/) include a
standalone HTML viewer. Open that viewer locally for a quick audiovisual
comparison; its clips are recorded gameplay, not a replacement game controller.
The standalone export is a game build for local testing, not a full Site export
and not an instruction to replace RiverSim. Editor Movement demos remain usable
without clearing the campaign; the campaign's NAHAIL unlock stays intact.

## Motion contract

The existing controller remains the sole movement authority. Its body trajectory,
airborne protection, collision shape, takeoff response and 0.34-second hop stay
unchanged. No anticipation delay, landing lock, camera, hazard speed or map edit
was added. Only local mesh poses consume its normalized phase.

The original thigh and toes keep their exact rest transforms; two lightweight,
visual-only shin meshes connect the extending rear legs. Each side spreads
outward and reaches rearward, achieving full extension around 23–55% of the hop,
then tucking on approach and restoring the exact squat at contact. Long hops use
the full amplitude; short hops use 90%. The front feet, body and hats retain their
existing geometry. Direct child meshes preserve the existing purple-skin flow.
Death resets the leg rig; retry builds a clean rest pose.

Smooth samples the simulation phase continuously. Stepped samples just the leg
pose at 12 poses/s, with forced exact contact reset. Body travel stays smooth in
both; this deliberate visual mismatch is why it is offered as a comparison,
rather than imposed on the entire presentation. Default Smooth matches the
existing continuous body motion. No mocap or external motion data was used.

## Sound contract and provenance

Original deterministic synthesis supplies three variants for each palette and
phase: 12 short mono WAVs. Soft combines rounded filtered noise and a low tonal
lift/contact; Retro uses a rounded rising/falling spring. No third-party samples.
Sources peak at -6.38 dBFS; playback adds -8 dB times the chosen gain (70% by
default), with landing another 2 dB lower. Effects duck by 0.55 while recorded
speech is busy. Nonzero browser output and gain response were measured; device
sound-pressure level and subjective comfort were not.

Accepted tile hops emit takeoff once. A safe completed landing emits contact
once, after water/collision validation; idle, blocked hops and water deaths do
not generate false dry landings. Effects require the same trusted-input unlock
as voices, use separate players, never queue stale cues, and stop on mute,
pause, retry, editor entry, menu return or death. A final victory landing may
finish its short tail. Original voice recordings remain byte-identical.

[Full attribution, license, source investigation and measurements](../game/audio/hop/ATTRIBUTION.md).
Kenney Impact Sounds was investigated on its primary CC0 page, but downloading
the free ZIP was blocked by the executor's CONNECT proxy (403). No Kenney clip
was downloaded or auditioned. The explicitly allowed original-synthesis fallback
provides the playable options; no asset was bought.

## Focused evidence and limits

40 native checks pass: pose spread/extension/tuck/contact, symmetric legs,
stepped holds versus continuous sampling, unchanged two-cell destinations and
hop duration at 30/60/120 Hz, one-shot events, blocked/water/death cases,
voice ducking, gain, zero-volume silence and mute/unmute. Fast native tests allow
the wall-clock audio mixer to release stopped samples before forced exit.
All five harder campaign fixtures and all five checkpoint retries complete with
hazards active, retaining their previous route outcomes. All 57 pre-existing
map/audio/adapter files are byte-identical to the base.

Ten browser checks pass without console/page errors across desktop and
Android-UA touch landscape: no sound before gesture, real hop output, mute,
volume scaling/zero and both sound/pose choices. Read-only diagnostics select
nothing; tests use actual buttons, keys and touch joystick gestures. WAV pairs
use the normal relative mix. Recordings/GIFs are sampled browser playback,
not an assertion of physical-device performance. [Machine evidence](HOP_FEEL_VALIDATION.json).

Physical iPhone, Safari, human preference/comfort and real-device frame pacing
remain unverified. No extra general consultant reviews were requested or run.
Godot Web/Windows exports are built; no merge or Site publication is included.

Primary references: Motionwright skill and its Godot/production/runtime pages;
current Godot AudioStreamPlayer documentation (volume_db, play/stop and stream
replacement), https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html ;
Kenney source page, https://kenney.nl/assets/impact-sounds . Implementation uses
APIs verified against the installed Godot 4.7.2 parser and playback tests.

## Delivered test artifact

[Standalone Web ZIP](../artifacts/hopan-hop-feel-web.zip): 10,749,065 bytes,
source `ca14b276915d7c01a15c720eeb179a3da95a3b4e`. Ten exported files are
byte-checked inside the ZIP; CRC checks pass. Its release export starts locally
without console/page errors and exposes no debug probe. SHA256 and provenance
are recorded in [the artifact manifest](../artifacts/hopan-hop-feel-web.json).
Repackage a completed build with `python3 tools/package_hop_feel.py`; this script
creates a local ZIP and never calls Sites or deploys anything.
