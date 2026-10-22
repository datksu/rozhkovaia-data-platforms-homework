#!/usr/bin/env bash
set -euo pipefail
HDFS=/opt/hadoop/bin/hdfs
LOCATION=/user/hive/warehouse/hw4_events_agg
sudo -u hadoop "$HDFS" dfs -test -d "$LOCATION"
listing="$(sudo -u hadoop "$HDFS" dfs -ls -R "$LOCATION")"
for dt in 2026-10-20 2026-10-21 2026-10-22; do
  grep -q "${LOCATION}/dt=${dt}/" <<< "$listing" || {
    echo "Missing Parquet data in partition $dt" >&2; exit 1
  }
done
sudo -u hadoop env \
  JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
  HADOOP_HOME=/opt/hadoop \
  HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop \
  HIVE_HOME=/opt/hive \
  /opt/hive/bin/beeline -u 'jdbc:hive2://team-17-nn:10000/default' -n hadoop \
    -e 'SHOW PARTITIONS hw4_events_agg; SELECT * FROM hw4_events_agg;' \
    > /tmp/hw4-hive-check.log 2>&1
python3 - <<'PY'
from pathlib import Path
import re
text = Path('/tmp/hw4-hive-check.log').read_text()
expected = {
  '2026-10-20': (2, 3.5, 1.75),
  '2026-10-21': (2, 18.5, 9.25),
  '2026-10-22': (2, 21.5, 10.75),
}
for day in expected:
  if not re.search(r'^\|\s*dt=' + re.escape(day) + r'\s*\|', text, re.M):
    raise SystemExit('Hive partition missing: ' + day)
rows = {}
for line in text.splitlines():
  if not line.startswith('|'): continue
  parts = [x.strip() for x in line.strip().strip('|').split('|')]
  if len(parts) != 4 or parts[-1] not in expected: continue
  rows[parts[-1]] = (int(parts[0]), float(parts[1]), float(parts[2]))
if rows != expected:
  raise SystemExit(f'Unexpected Hive results: {rows}, expected {expected}')
print('Hive partitions and aggregates: OK')
PY
echo 'Parquet files in 3 HDFS partitions: OK'
echo 'HW4 checks passed.'
