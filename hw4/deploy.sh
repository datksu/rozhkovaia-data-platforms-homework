#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="${HW4_HOST:-team-17-nn}"
KEY="${HW4_SSH_KEY:-$HOME/.ssh/team_internal}"
REMOTE="/home/team/hw4"
[[ -f "$KEY" ]] || { echo "Missing SSH key: $KEY" >&2; exit 1; }
ssh -i "$KEY" -o BatchMode=yes "team@$HOST" "mkdir -p '$REMOTE'"
scp -i "$KEY" -q -r "$ROOT/scripts" "$ROOT/sql" "team@$HOST:$REMOTE/"
for step in prerequisites install_spark run_spark register_hive check_results; do
  echo "=== HW4: $step ==="
  ssh -i "$KEY" -o BatchMode=yes "team@$HOST" "bash '$REMOTE/scripts/$step.sh'"
done
echo 'HW4 deployment and verification completed.'
