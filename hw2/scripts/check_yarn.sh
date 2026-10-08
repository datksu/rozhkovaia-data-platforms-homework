#!/usr/bin/env bash
set -euo pipefail

KEY="${SSH_KEY:-$HOME/.ssh/team_internal}"

ssh -i "$KEY" team@team-17-nn \
    'sudo -u hadoop jps | grep -q ResourceManager'

ssh -i "$KEY" team@team-17-00 \
    'sudo -u hadoop jps | grep -q NodeManager'

ssh -i "$KEY" team@team-17-01 \
    'sudo -u hadoop jps | grep -q NodeManager'

ssh -i "$KEY" team@team-17-nn \
    'sudo -u hadoop /opt/hadoop/bin/yarn node -list | grep -q "Total Nodes:2"'

ssh -i "$KEY" team@team-17-nn \
    'curl -fsSI http://team-17-nn:8088 >/dev/null'

ssh -i "$KEY" team@team-17-nn \
    'curl -fsSI http://team-17-nn:19888 >/dev/null'

echo "YARN cluster check passed."
