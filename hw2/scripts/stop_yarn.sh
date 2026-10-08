#!/usr/bin/env bash
set -euo pipefail

KEY="${SSH_KEY:-$HOME/.ssh/team_internal}"

ssh -i "$KEY" team@team-17-nn \
    'sudo -u hadoop /opt/hadoop/bin/yarn --daemon stop resourcemanager'

ssh -i "$KEY" team@team-17-00 \
    'sudo -u hadoop /opt/hadoop/bin/yarn --daemon stop nodemanager'

ssh -i "$KEY" team@team-17-01 \
    'sudo -u hadoop /opt/hadoop/bin/yarn --daemon stop nodemanager'

echo "YARN daemons stopped."
