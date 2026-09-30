#!/usr/bin/env bash
set -euo pipefail

KEY="${HOME}/.ssh/team_internal"

stop_daemon() {
    local host="$1"
    local process="$2"
    local daemon="$3"

    ssh -i "$KEY" "team@$host" "
        if sudo -u hadoop jps |
            awk '{print \$2}' |
            grep -qx '$process'; then
            sudo -u hadoop /opt/hadoop/bin/hdfs \
                --daemon stop '$daemon'
        fi
    "
}

stop_daemon team-17-00 DataNode datanode
stop_daemon team-17-01 DataNode datanode
stop_daemon team-17-nn DataNode datanode
stop_daemon team-17-nn SecondaryNameNode secondarynamenode
stop_daemon team-17-nn NameNode namenode
