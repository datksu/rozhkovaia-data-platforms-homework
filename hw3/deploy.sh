#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="${HW3_HOST:-team-17-nn}"
KEY="${HW3_SSH_KEY:-${HOME}/.ssh/team_internal}"
REMOTE="/home/team/hw3"

[[ -f "$KEY" ]] || { echo "SSH key not found: $KEY" >&2; exit 1; }
ssh -i "$KEY" -o BatchMode=yes "team@$HOST" "mkdir -p '$REMOTE'"
scp -i "$KEY" -q -r "$ROOT/scripts" "$ROOT/config" "$ROOT/sql" "$ROOT/data" "team@$HOST:$REMOTE/"

for step in prerequisites install_hive setup_postgres configure_hive start_services load_data check_hive; do
    echo "=== $step ==="
    ssh -i "$KEY" -o BatchMode=yes "team@$HOST" \
        "bash '$REMOTE/scripts/$step.sh'"
done

echo "HW3 deployment and verification completed."
