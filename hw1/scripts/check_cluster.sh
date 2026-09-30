#!/usr/bin/env bash
set -euo pipefail

KEY="${HOME}/.ssh/team_internal"

for host in team-17-nn team-17-00 team-17-01; do
    ssh -i "$KEY" "team@$host" 'sudo -u hadoop jps'
done

REPORT=""

for _ in {1..30}; do
    REPORT="$(
        ssh -i "$KEY" team@team-17-nn \
            'sudo -u hadoop /opt/hadoop/bin/hdfs dfsadmin -report' \
            2>/dev/null || true
    )"

    if grep -q 'Live datanodes (3):' <<<"$REPORT"; then
        break
    fi

    sleep 2
done

printf '%s\n' "$REPORT"

if ! grep -q 'Live datanodes (3):' <<<"$REPORT"; then
    echo "Expected 3 live DataNodes" >&2
    exit 1
fi

FSCK="$(
    ssh -i "$KEY" team@team-17-nn \
        'sudo -u hadoop bash -s' <<'REMOTE'
set -euo pipefail

HDFS="/opt/hadoop/bin/hdfs"
LOCAL_FILE="/tmp/hdfs-healthcheck.txt"
HDFS_DIR="/healthcheck"

cleanup() {
    rm -f "$LOCAL_FILE"
    "$HDFS" dfs -rm -r -skipTrash "$HDFS_DIR" \
        >/dev/null 2>&1 || true
}

trap cleanup EXIT

printf 'hdfs-healthcheck\n' > "$LOCAL_FILE"

"$HDFS" dfs -mkdir -p "$HDFS_DIR"
"$HDFS" dfs -put -f "$LOCAL_FILE" "$HDFS_DIR/check.txt"
"$HDFS" dfs -setrep -w 3 "$HDFS_DIR/check.txt" >/dev/null

"$HDFS" fsck "$HDFS_DIR/check.txt" \
    -files -blocks -locations
REMOTE
)"

printf '%s\n' "$FSCK"

grep -q 'Status: HEALTHY' <<<"$FSCK"
grep -q 'Live_repl=3' <<<"$FSCK"
grep -qE 'Under-replicated blocks:[[:space:]]*0' <<<"$FSCK"

echo "Cluster check passed"
