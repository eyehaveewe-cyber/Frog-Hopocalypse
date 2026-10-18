#!/usr/bin/env bash
set -euo pipefail
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/workspace/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-/workspace/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/workspace/.cache}"
HOPAN_PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
HOPAN_GODOT="${HOPAN_TOOL_DIR:-/workspace/tools/godot-4.7.2}/Godot_v4.7.2-stable_linux.x86_64"
if [[ ! -x "$HOPAN_GODOT" ]]; then
  python3 "$HOPAN_PROJECT_ROOT/tools/bootstrap.py"
fi
exec "$HOPAN_GODOT" --path "$HOPAN_PROJECT_ROOT/game" "$@"
