#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
KEY="${HOME}/.ssh/team_internal"
HOSTS=(team-17-nn team-17-00 team-17-01)

for host in "${HOSTS[@]}"; do
    scp -q -i "$KEY" \
        "$ROOT_DIR/config/core-site.xml" \
        "$ROOT_DIR/config/hdfs-site.xml" \
        "team@$host:/tmp/"

    ssh -i "$KEY" "team@$host" '
        sudo install -o hadoop -g hadoop -m 644 \
            /tmp/core-site.xml \
            /opt/hadoop/etc/hadoop/core-site.xml

        sudo install -o hadoop -g hadoop -m 644 \
            /tmp/hdfs-site.xml \
            /opt/hadoop/etc/hadoop/hdfs-site.xml

        sudo install -d -o hadoop -g hadoop -m 700 \
            /data/hdfs/datanode

        rm -f /tmp/core-site.xml /tmp/hdfs-site.xml
    '
done

ssh -i "$KEY" team@team-17-nn '
    sudo install -d -o hadoop -g hadoop -m 700 \
        /data/hdfs/namenode \
        /data/hdfs/namesecondary

    sudo sed -i \
        "/^[[:space:]]*127\.0\.1\.1[[:space:]].*team-17-nn/d" \
        /etc/hosts

    if ! grep -qE \
        "^10\.17\.0\.11[[:space:]].*team-17-nn" \
        /etc/hosts; then
        echo "10.17.0.11 team-17-nn" |
            sudo tee -a /etc/hosts >/dev/null
    fi
'
