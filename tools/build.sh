#!/usr/bin/env bash
set -euo pipefail
HOPAN_PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$HOPAN_PROJECT_ROOT/build/web" "$HOPAN_PROJECT_ROOT/build/windows" "$HOPAN_PROJECT_ROOT/build/test-web"
bash "$HOPAN_PROJECT_ROOT/tools/godot.sh" --headless --editor --import --quit
bash "$HOPAN_PROJECT_ROOT/tools/godot.sh" --headless --export-release Web "$HOPAN_PROJECT_ROOT/build/web/index.html"
bash "$HOPAN_PROJECT_ROOT/tools/godot.sh" --headless --export-release "Windows Desktop" "$HOPAN_PROJECT_ROOT/build/windows/Hopan.exe"
if [[ "${1:-}" == "--with-browser-test" ]]; then
  bash "$HOPAN_PROJECT_ROOT/tools/godot.sh" --headless --export-debug Web "$HOPAN_PROJECT_ROOT/build/test-web/index.html"
fi

# The custom shell loads this streaming hosting adapter beside the engine.
cp "$HOPAN_PROJECT_ROOT/game/hopan-wasm.js" "$HOPAN_PROJECT_ROOT/build/web/hopan-wasm.js"
if [[ "${1:-}" == "--with-browser-test" ]]; then
  cp "$HOPAN_PROJECT_ROOT/game/hopan-wasm.js" "$HOPAN_PROJECT_ROOT/build/test-web/hopan-wasm.js"
fi
