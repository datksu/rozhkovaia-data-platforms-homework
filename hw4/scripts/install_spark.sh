#!/usr/bin/env bash
set -euo pipefail
VERSION=3.5.3
DIST="spark-${VERSION}-bin-without-hadoop"
TARGET="/opt/$DIST"
ARCHIVE="/tmp/$DIST.tgz"
BASE="https://archive.apache.org/dist/spark/spark-${VERSION}"
if [[ ! -x "$TARGET/bin/spark-submit" ]]; then
  curl -fL --retry 3 "$BASE/$DIST.tgz" -o "$ARCHIVE"
  curl -fL --retry 3 "$BASE/$DIST.tgz.sha512" -o "$ARCHIVE.sha512"
  python3 - "$ARCHIVE" <<'PY'
import hashlib, re, sys
from pathlib import Path
p = Path(sys.argv[1])
match = re.search(r'\b[0-9a-fA-F]{128}\b', Path(str(p)+'.sha512').read_text())
if not match: raise SystemExit('Missing Spark SHA-512 digest')
h = hashlib.sha512()
with p.open('rb') as f:
    for block in iter(lambda: f.read(1024*1024), b''): h.update(block)
if h.hexdigest().lower() != match.group().lower(): raise SystemExit('Spark SHA-512 mismatch')
print('Spark SHA-512: OK')
PY
  sudo tar -xzf "$ARCHIVE" -C /opt
  sudo chown -R hadoop:hadoop "$TARGET"
fi
if [[ -e /opt/spark && ! -L /opt/spark ]]; then
  echo '/opt/spark is not a symlink; refusing to replace.' >&2; exit 1
fi
if [[ -L /opt/spark && "$(readlink -f /opt/spark)" != "$TARGET" ]]; then
  echo '/opt/spark points elsewhere; refusing to replace.' >&2; exit 1
fi
sudo ln -sfn "$TARGET" /opt/spark
sudo -u hadoop bash -c '
  export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
  export HADOOP_HOME=/opt/hadoop
  export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
  export SPARK_HOME=/opt/spark
  export SPARK_DIST_CLASSPATH="$(/opt/hadoop/bin/hadoop classpath)"
  /opt/spark/bin/spark-submit --version
' 2>&1 | grep -E 'version 3\.5\.3|Using Scala version' || { echo 'Spark version check failed.' >&2; exit 1; }
