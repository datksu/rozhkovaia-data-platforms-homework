#!/usr/bin/env bash
set -euo pipefail
[[ "$(hostname -s)" == "team-17-nn" ]] || { echo 'Expected team-17-nn' >&2; exit 1; }
id hadoop >/dev/null
[[ -x /opt/hadoop/bin/hdfs ]] || { echo 'Missing Hadoop; run HW1.' >&2; exit 1; }
[[ -x /usr/lib/jvm/java-17-openjdk-amd64/bin/java ]] || { echo 'Java 17 is required.' >&2; exit 1; }
[[ -x /opt/hive/bin/beeline ]] || { echo 'Missing Hive/Beeline; run HW3.' >&2; exit 1; }
sudo -u hadoop /opt/hadoop/bin/hdfs dfs -test -d /user/hive/warehouse/hw3_events || {
  echo 'Missing HW3 source HDFS data.' >&2; exit 1;
}
sudo -u hadoop /opt/hadoop/bin/yarn node -list 2>&1 | grep -Eq 'Total Nodes:[[:space:]]*[2-9][0-9]*' || {
  echo 'Fewer than two registered YARN NodeManagers.' >&2; exit 1;
}
sudo systemctl is-active --quiet hive-hiveserver2.service
sudo systemctl is-active --quiet hive-metastore.service
sudo systemctl is-active --quiet postgresql.service
echo 'HDFS, YARN (at least 2 nodes), Hive, PostgreSQL: OK'
