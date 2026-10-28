# Latest main publication · Hopán Site 85

Published main `6b1e4b049cf63d2578e82951dcd6b94c71785950` at https://hopan.fiiendward.chatgpt.site. It contains NYC traffic, streetlife assets and the six-level Streetlife campaign. This publication builds that requested main snapshot; it does not merge the older feature branches.

The native suite passes 217 checks, including 52 campaign checks. The debug WebGL runner passes 20 campaign checks, and the actual production release passes four startup/input checks at desktop and landscape touch-emulated sizes. Production captures show the real six-level start action and gameplay. No JavaScript or engine errors were reported. Physical phone hardware remains unverified.

The Web export uses Godot 4.7.2 with matching templates. `tools/prepare_sites_web.py` applies the existing Hopán streaming gzip loader so the engine fits the hosting file limit and starts without a gzip response header. Gameplay source is unchanged.

`tools/package_sites_hopan.py` verifies the browser reports and preserves every file outside the new root game export. All 15 unrelated static files, including RiverSim 0.4.51, retain their hashes; the hosting manifest is byte-identical. The Site remains public. Saved Site source `fd22a3bbaf37bb70de9660652de1b54836ef5175` matches the uploaded archive; native publication succeeded as version 85.

See [the publication receipt](HOPAN_MAIN_PUBLICATION.json), [preservation hashes](publication-main-6b1e4b0/preservation.json), [campaign checks](publication-main-6b1e4b0/campaign-browser.json), [production checks](publication-main-6b1e4b0/release-browser.json), [desktop capture](publication-main-6b1e4b0/release-desktop-play.png) and [landscape capture](publication-main-6b1e4b0/release-landscape-play.png). No new Site, audience change or branch merge.
