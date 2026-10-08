#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/scripts/configure_yarn.sh"
"$SCRIPT_DIR/scripts/start_yarn.sh"
"$SCRIPT_DIR/scripts/start_historyserver.sh"

sleep 3

"$SCRIPT_DIR/scripts/check_yarn.sh"
