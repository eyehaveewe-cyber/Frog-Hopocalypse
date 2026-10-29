# City Journey anti-aliasing

City Journey's wide view previously rendered gameplay at roughly 240 pixels tall, then enlarged it with nearest filtering and retro color quantization. Small frog, skater, vehicle and railing edges became visibly jagged.

The three City Journey stages now render near display resolution, capped to keep large viewports bounded, with 2× 3D MSAA and linear viewport filtering. Their overhead map also uses the smoother settings. Earlier campaigns retain their original retro presentation. No gameplay or save data changes.

At a 1280 × 800 browser window, the scene buffer changes from 426 × 232 to 1280 × 698, about nine times as many pixels; 2× MSAA adds further GPU work. A landscape mobile emulation remained 844 × 286 before and after. Browser comparisons show smoother geometry, retain pixel textures and captured no console errors. Physical-device performance is unmeasured.

Run `bash tools/godot.sh --headless --fixed-fps 60 --script res://tests/city_journey_antialias.gd` for 13 native configuration checks. Browser screenshots and measurements are in [city-aa-evidence](city-aa-evidence/); `tools/city_aa_browser.cjs` and `tools/check_city_aa_evidence.py` reproduce the comparison with exports served at the configured test URLs.
