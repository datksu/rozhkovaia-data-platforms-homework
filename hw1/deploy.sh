#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY="${HOME}/.ssh/team_internal"

"$ROOT_DIR/scripts/install.sh"
"$ROOT_DIR/scripts/stop_cluster.sh"
"$ROOT_DIR/scripts/configure.sh"

ssh -i "$KEY" team@team-17-nn '
    if [ ! -f /data/hdfs/namenode/current/VERSION ]; then
        sudo -u hadoop /opt/hadoop/bin/hdfs \
            namenode -format -nonInteractive
    fi
'

"$ROOT_DIR/scripts/start_cluster.sh"
"$ROOT_DIR/scripts/check_cluster.sh"
