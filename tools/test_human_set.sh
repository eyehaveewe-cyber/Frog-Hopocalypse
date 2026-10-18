#!/usr/bin/env bash
set -euo pipefail
HOPAN_PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
HOPAN_SET_TEST_DATA="$(mktemp -d /tmp/hopan-human-set.XXXXXX)"
trap 'rm -rf -- "$HOPAN_SET_TEST_DATA"' EXIT
XDG_DATA_HOME="$HOPAN_SET_TEST_DATA" timeout 90 bash "$HOPAN_PROJECT_ROOT/tools/godot.sh" --headless --fixed-fps 60 --script res://tests/human_set.gd -- --compat
