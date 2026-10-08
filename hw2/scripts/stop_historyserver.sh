#!/usr/bin/env bash
set -euo pipefail

KEY="${SSH_KEY:-$HOME/.ssh/team_internal}"

ssh -i "$KEY" team@team-17-nn \
    'sudo -u hadoop /opt/hadoop/bin/mapred --daemon stop historyserver'

echo "JobHistoryServer stopped."
