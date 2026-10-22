#!/usr/bin/env bash
set -euo pipefail

sudo systemctl is-active --quiet postgresql.service
sudo systemctl is-active --quiet hive-metastore.service
sudo systemctl is-active --quiet hive-hiveserver2.service

run_beeline() {
    sudo -u hadoop env JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
        HADOOP_HOME=/opt/hadoop HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop \
        HIVE_HOME=/opt/hive \
        /opt/hive/bin/beeline -u 'jdbc:hive2://team-17-nn:10000/default' \
        -n "$1" -e "$2"
}

# Launch independent JDBC clients concurrently.
run_beeline client1 'SHOW DATABASES;' > /tmp/hw3-client1.log 2>&1 & p1=$!
run_beeline client2 'SHOW PARTITIONS hw3_events;' > /tmp/hw3-client2.log 2>&1 & p2=$!
wait "$p1" || { tail -40 /tmp/hw3-client1.log; exit 1; }
wait "$p2" || { tail -40 /tmp/hw3-client2.log; exit 1; }
grep -Eq '(^|[|[:space:]])default([|[:space:]]|$)' /tmp/hw3-client1.log
grep -q 'dt=2026-10-20' /tmp/hw3-client2.log
grep -q 'dt=2026-10-21' /tmp/hw3-client2.log
grep -q 'dt=2026-10-22' /tmp/hw3-client2.log

rows="$(run_beeline hadoop 'SELECT * FROM hw3_events;' 2>/dev/null)"
for id in 1 2 3 4 5 6; do
    grep -Eq "^[|][[:space:]]*$id[[:space:]]*[|]" <<< "$rows" || {
        echo "Missing record id $id" >&2; exit 1;
    }
done

hdfs_output="$(sudo -u hadoop /opt/hadoop/bin/hdfs dfs -ls -R /user/hive/warehouse/hw3_events)"
for dt in 2026-10-20 2026-10-21 2026-10-22; do
    grep -q "dt=$dt/events_$dt.csv" <<< "$hdfs_output" || {
        echo "Missing HDFS partition data $dt" >&2; exit 1;
    }
done

echo 'Two Beeline clients: OK'
echo 'Three Hive partitions and six records: OK'
echo 'HDFS partition files (replication configured by HW1): OK'
echo 'HW3 checks passed.'
