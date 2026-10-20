# Hopan hop effects

These twelve WAVs are **original procedural synthesis**, authored by the assistant
for Jonathan's Hopan request on 2026-10-20. They contain no sampled recordings,
mocap, third-party audio or purchased assets. Reproduce them with
`python3 tools/synthesize_hops.py` (deterministic seed and variant parameters).

License: **CC0-1.0**. To the extent possible under law, the author dedicates these
original synthesized WAVs and their synthesis recipe to the public domain.
[CC0 legal text](https://creativecommons.org/publicdomain/zero/1.0/legalcode).
No attribution is required; this file records provenance, not an endorsement.
The game's pre-existing user recordings retain their existing provenance.

- `soft_takeoff_[0-2].wav`: short filtered-noise / low sine lift, 115 ms.
- `soft_landing_[0-2].wav`: damped low contact, 95 ms.
- `retro_takeoff_[0-2].wav`: rounded rising spring, 140 ms.
- `retro_landing_[0-2].wav`: descending rounded contact, 110 ms.

24 kHz mono, signed 16-bit PCM; no loops. Sources peak at -6.38 dBFS with short
attack/release fades. Playback adds -8 dB and the selected volume gain; landing
is another 2 dB lower. Effects duck by a factor of 0.55 while recorded speech is
busy. Three deterministic variants reduce exact repetition. This is digital
headroom, not a measured real-world sound pressure level or a comfort guarantee.
See `measurements.json` for per-file peak/RMS and SHA256.

## Free source investigated, not bundled

Kenney, **Impact Sounds 1.0** (130 files, released 2019):
https://kenney.nl/assets/impact-sounds . Its primary provider page explicitly
lists Creative Commons CC0, checked 2026-10-20. The source ZIP download failed
in this executor at the CONNECT proxy with HTTP 403 Forbidden. No Kenney audio
was downloaded, auditioned or included; no claim is made about any particular
clip's suitability. The requested original-synthesis fallback is used instead.
Digital Audio was also inspected; its space/laser emphasis is a weaker fit for
the desired organic contact than the labelled original soft palette.
