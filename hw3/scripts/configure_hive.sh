#!/usr/bin/env bash
set -euo pipefail

# The password is read locally by root and never transmitted from the edge VM.
sudo python3 - <<'PY'
from pathlib import Path
import grp, os, pwd
password = Path('/etc/hive/metastore-password').read_text().strip()
template = Path('/home/team/hw3/config/hive-site.xml.template').read_text()
assert template.count('__HIVE_DB_PASSWORD__') == 1
output = Path('/opt/hive/conf/hive-site.xml')
output.write_text(template.replace('__HIVE_DB_PASSWORD__', password))
os.chown(output, pwd.getpwnam('hadoop').pw_uid, grp.getgrnam('hadoop').gr_gid)
os.chmod(output, 0o600)
PY

sudo -u hadoop /opt/hadoop/bin/hdfs dfs -mkdir -p /tmp /user/hive/warehouse
sudo -u hadoop /opt/hadoop/bin/hdfs dfs -chmod 1777 /tmp
sudo -u hadoop /opt/hadoop/bin/hdfs dfs -chmod 775 /user/hive/warehouse

HIVE_ENV=(JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 HADOOP_HOME=/opt/hadoop HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop HIVE_HOME=/opt/hive)
if sudo -u hadoop env "${HIVE_ENV[@]}" /opt/hive/bin/schematool -dbType postgres -info >/dev/null 2>&1; then
    echo 'Hive Metastore schema already initialized.'
else
    echo 'Initializing Hive Metastore schema in PostgreSQL.'
    sudo -u hadoop env "${HIVE_ENV[@]}" /opt/hive/bin/schematool -dbType postgres -initSchema
fi
