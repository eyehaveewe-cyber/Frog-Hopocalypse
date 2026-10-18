# Android scene-shader startup investigation — 2026-10-18

Integration base: `0a6bf1f8325d61626e96523a4e82668ef66d6588`
(`feature/bonus-shelby`, public version 12). The investigation initially located
v11 at `38353d5`, then moved onto v12 after the deployment owner supplied it.
This branch is an unpublished mitigation and diagnostic patch. Deployment stays
with the main task. No Site, `/droid`, `/riversim`, save format, audio, level or
menu content was modified.

## Evidence and limits

The user's transcription says **scene GLES3 program linking failed**, followed
by `_display_error_with_code`, `shader_gles3.cpp:262`, and generic method/function
failures. There is no screenshot, confirmed subvariant, GPU, Chrome version, generated
shader or actual driver linker explanation. The latest user correction is
**Moto G5**, replacing the earlier tentative G6. This identifies a failure stage,
not a root cause. Chrome updating alone is not an established fix.

Godot's pinned 4.7.2 source calls `glLinkProgram`, checks `GL_LINK_STATUS`, reads
`glGetProgramInfoLog`, and passes that message to the generic error printer.
The reported source line is not a bad line in a custom shader. Both standard
materials and custom spatial materials use the engine's **scene** shader.
Android already selected `--compat` by default, but v12's fallback still selected
`SHADING_MODE_PER_VERTEX` for textured and solid materials. Merely bypassing the
three custom shaders therefore did not avoid lit scene variants.

Shader audit:

- `retro_surface.gdshader`: one explicit 2D sampler, one float custom varying
  (`view_depth`), plus engine UV/lighting varyings. Water shares this shader.
- `retro_screen.gdshader`: canvas shader, one texture sample and indexed dither
  constants; not a scene shader. Compatibility bypasses it.
- `night_sky.gdshader`: sky shader, no custom samplers/varyings; compatibility
  bypasses it. The patch avoids constructing its material in that path.
- Godot emits default **highp** float/int and sampler precision in GLES. No
  specific precision mismatch or sampler/varying overflow was established.
  Reducing precision blindly could introduce mismatches or numerical artifacts.
- Lit scene code contains additional lighting varyings, reflection samplers and
  uniform blocks. The patch selects standard **unshaded** materials for both
  textured and solid objects (including derived shadow/cursor materials), omits
  their emission feature, and omits the directional scene light. Textures,
  transparency and geometry remain. Lighting/retro effects remain on `compat=0`.
  The fallback is visibly brighter/flatter; a local Shelby screenshot was inspected.
- Godot still precompiles internal scene/default/depth variants. This patch does
  **not** eliminate every scene shader, and cannot guarantee recovery from an
  engine/default-shader or driver failure.

## Moto G5 update and conservative limits

The exact G5/Plus/S subtype and OS are unknown; no G6 hardware assumption is
used. Snapdragon 430 was checked as a candidate, not identified from this phone:
[Qualcomm's original product brief](https://www.qualcomm.com/media/documents/files/snapdragon-430-processor-product-brief.pdf)
confirms Adreno 505 and OpenGL ES 3.1 for that SoC. That establishes hardware API
capability only, not this phone's browser/driver support or a successful link.

As a conservative budget, [Khronos ES 3.0 tables 6.30–6.32](https://github.com/KhronosGroup/OpenGL-Registry/blob/main/specs/es/3.0/es_spec_3.0.pdf)
require 15 varying vectors/60 components and 16 fragment texture units. Offline
preprocessing of the 26 captured compatibility material variants found at most
**4 simple vector interface declarations** and **8 declared fragment samplers**,
including unused engine samplers. These interface declarations have no arrays or
matrices; even charging four components each stays under 60. The representative
textured variant has vec3 position, vec3 normal and vec2 UV varyings. This is
static accounting, not evidence that the user's driver compiles correctly;
actual reported limits and precision are collected in diagnostic mode. No limit
overflow was established, so no hardware-specific number or precision change is
hardcoded into the project.

## Focused verification

Checksum-verified Godot **4.7.2 ed1daf0bf**; debug Web exports of unmodified v12
and patched v12. Desktop **Chromium 154.0.8037.57**, ANGLE SwiftShader, Android
UA/touch/mobile viewport 844 × 390. This is **not Android Chrome, an Android
emulator, or physical-phone testing**. No adb, emulator or KVM device is present.
The earlier cloud browser's lack of WebGL2 was not treated as device evidence.

`tools/android_shader_smoke.cjs` verifies Android automatic fallback, explicit
`compat=1` with graphics instrumentation disabled, full `compat=0`, and original
v12 baseline. Each starts through first frame, moves the frog, opens/returns from
the map, and launches original Shelby from Bonus with no unexpected browser or
Godot errors. It inspects actual linked GLSL and records counts. Engine internal
variants are separated from material variants using emitted material defines.
Results are retained in `ANDROID_SCENE_SHADER_RESULTS.json`.

A separate **intentional desktop diagnostic fixture** links individually valid
vertex/fragment stages with incompatible `mismatch` varying types. The actual
SwiftShader linker log is:

```
Types of varying 'mismatch' differ between VERTEX and FRAGMENT shaders.
FRAGMENT varying mismatch does not match any VERTEX varying
```

This is **not the user's shader error**. It verifies recovery, exact linker log
and both source captures, report download, and retention after 40 generic
method/function errors. Normal startup does not query every link status;
synchronizing diagnostic instrumentation requires `graphics-debug=1`.

Existing focused native checks passed: cheese/seam **18/18**, car/tree **16/16**,
and v12 compact-menu/Shelby/progress-save **19/19**. No broad suite was rerun.
Godot import/export and `git diff --check` passed. Native tests used isolated
`XDG_DATA_HOME` directories. Original Shelby SHA-256 remains
`3341a1fcd91c81f89d2bb0abdfbc787e54d338f2aa2e1c0a7f01c39bcdc03aa8`.

Reproduce locally after exporting patched v12 to `build/test-web/index.html`
and baseline v12 to `build/baseline/index.html`; copy `game/hopan-wasm.js` beside
each export, serve `build/` on localhost:8060, then run:

```
HOPAN_BASELINE_URL=http://127.0.0.1:8060/baseline/ node tools/android_shader_smoke.cjs
```

## Phone follow-up after coordinated integration

Test the normal root URL first, then `?compat=1&graphics-debug=1` if it fails.
The startup recovery panel's **Save graphics report** downloads user agent,
selected arguments, actual engine-context GPU/renderer when exposed, GLES/GLSL
versions, texture/sampler/varying/uniform limits, fragment high-float precision,
and up to two failed link logs with attached shader source and compile status.
It does not upload anything or require a separate export/path.

Still needed: exact Moto G5 subvariant, Android version, Chrome version, whether it is regular
Chrome or an in-app browser, and the downloaded `hopan-graphics.json` (or complete
Startup details). Only that device result can confirm this mitigation and guide
an engine-specific fix if an internal shader still fails.

Primary references:

- [Pinned Godot GLES3 compiler/linker source](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/shader_gles3.cpp)
- [Pinned GLES3 scene variants and varyings](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/shaders/scene.glsl)
- [BaseMaterial3D shading modes](https://docs.godotengine.org/en/stable/classes/class_basematerial3d.html)
- [Godot web export requirements](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
