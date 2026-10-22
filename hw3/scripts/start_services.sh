#!/usr/bin/env bash
set -euo pipefail

# Stop prior systemd services, if present.
sudo systemctl stop hive-hiveserver2.service hive-metastore.service 2>/dev/null || true

# Reconcile services previously launched manually using nohup.
for port in 10000 9083; do
    for pid in $(sudo fuser -n tcp "$port" 2>/dev/null || true); do
        owner="$(ps -p "$pid" -o user= | xargs)"
        if [[ "$owner" != hadoop ]]; then
            echo "Port $port is used by $owner (PID $pid); refusing to stop it." >&2
            exit 1
        fi
        sudo kill "$pid"
    done
done
for i in {1..15}; do
    if ! (sudo fuser -n tcp 10000 2>/dev/null || sudo fuser -n tcp 9083 2>/dev/null); then
        break
    fi
    sleep 1
done
if sudo fuser -n tcp 10000 >/dev/null 2>&1 || sudo fuser -n tcp 9083 >/dev/null 2>&1; then
    echo 'A previous Hive listener did not exit.' >&2; exit 1
fi

sudo tee /etc/systemd/system/hive-metastore.service >/dev/null <<'UNIT'
[Unit]
Description=Apache Hive Metastore
Wants=network-online.target
After=network-online.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=hadoop
Group=hadoop
WorkingDirectory=/home/hadoop
Environment=JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
Environment=HADOOP_HOME=/opt/hadoop
Environment=HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
Environment=HIVE_HOME=/opt/hive
ExecStart=/opt/hive/bin/hive --service metastore -p 9083
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
UNIT

sudo tee /etc/systemd/system/hive-hiveserver2.service >/dev/null <<'UNIT'
[Unit]
Description=Apache HiveServer2
Wants=network-online.target
After=network-online.target hive-metastore.service
Requires=hive-metastore.service

[Service]
Type=simple
User=hadoop
Group=hadoop
WorkingDirectory=/home/hadoop
Environment=JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
Environment=HADOOP_HOME=/opt/hadoop
Environment=HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
Environment=HIVE_HOME=/opt/hive
ExecStart=/opt/hive/bin/hive --service hiveserver2
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload
sudo systemctl enable --now hive-metastore.service

port_listening() { sudo ss -lnt | grep -Eq "[.:]${1}[[:space:]]"; }
for i in {1..60}; do
    if port_listening 9083; then break; fi
    sleep 2
done
port_listening 9083 || { sudo journalctl -u hive-metastore -n 60 --no-pager; exit 1; }

sudo systemctl enable --now hive-hiveserver2.service
for i in {1..60}; do
    if port_listening 10000; then break; fi
    sleep 2
done
port_listening 10000 || { sudo journalctl -u hive-hiveserver2 -n 60 --no-pager; exit 1; }
echo 'Hive Metastore :9083 and HiveServer2 :10000 are listening.'
