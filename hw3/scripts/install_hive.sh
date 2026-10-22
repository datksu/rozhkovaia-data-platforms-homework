#!/usr/bin/env bash
set -euo pipefail

VERSION=4.1.0
DIR="/opt/apache-hive-${VERSION}-bin"
ARCHIVE="/tmp/apache-hive-${VERSION}-bin.tar.gz"
BASE="https://archive.apache.org/dist/hive/hive-${VERSION}"

if [[ ! -x "$DIR/bin/hive" ]]; then
    curl -fL --retry 3 "$BASE/apache-hive-${VERSION}-bin.tar.gz" -o "$ARCHIVE"
    curl -fL --retry 3 "$BASE/apache-hive-${VERSION}-bin.tar.gz.sha256" -o "$ARCHIVE.sha256"
    python3 - "$ARCHIVE" <<'PY'
from pathlib import Path
import hashlib, re, sys
p = Path(sys.argv[1])
expected = re.search(r'\b[0-9a-fA-F]{64}\b', Path(str(p) + '.sha256').read_text())
if expected is None:
    raise SystemExit('Missing SHA256 digest from Apache checksum file')
h = hashlib.sha256()
with p.open('rb') as f:
    for block in iter(lambda: f.read(1024 * 1024), b''):
        h.update(block)
if h.hexdigest().lower() != expected.group().lower():
    raise SystemExit('Hive archive SHA256 mismatch')
print('Apache Hive archive SHA256: OK')
PY
    sudo tar -xzf "$ARCHIVE" -C /opt
    sudo chown -R hadoop:hadoop "$DIR"
fi

sudo ln -sfn "$DIR" /opt/hive
sudo ln -sfn /usr/share/java/postgresql.jar /opt/hive/lib/postgresql.jar
sudo install -d -o hadoop -g hadoop -m 750 /opt/hive/logs
sudo -u hadoop env JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    HADOOP_HOME=/opt/hadoop HIVE_HOME=/opt/hive /opt/hive/bin/hive --version
