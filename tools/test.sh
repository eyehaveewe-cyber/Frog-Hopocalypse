#!/usr/bin/env bash
set -euo pipefail
HOPAN_PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
HOPAN_TEST_DATA="$(mktemp -d /tmp/hopan-tests.XXXXXX)"
trap 'rm -rf -- "$HOPAN_TEST_DATA"' EXIT
# Tests never add sample saves to a developer's library.
XDG_DATA_HOME="$HOPAN_TEST_DATA" timeout 45 bash "$HOPAN_PROJECT_ROOT/tools/godot.sh" --headless --fixed-fps 60 -- --integration-test
