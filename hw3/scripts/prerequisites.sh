#!/usr/bin/env bash
set -euo pipefail

[[ "$(hostname -s)" == "team-17-nn" ]] || {
    echo "Expected team-17-nn (Hive/PostgreSQL node)" >&2; exit 1;
}
id hadoop >/dev/null 2>&1 || { echo 'The hadoop user is absent. Run HW1 first.' >&2; exit 1; }
[[ -x /opt/hadoop/bin/hdfs ]] || { echo 'Hadoop is absent. Run HW1 first.' >&2; exit 1; }
[[ -x /usr/lib/jvm/java-17-openjdk-amd64/bin/java ]] || { echo 'Java 17 is missing.' >&2; exit 1; }
sudo -u hadoop /opt/hadoop/bin/hdfs dfs -ls / >/dev/null
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    postgresql postgresql-contrib libpostgresql-jdbc-java curl openssl psmisc python3
sudo systemctl enable --now postgresql
