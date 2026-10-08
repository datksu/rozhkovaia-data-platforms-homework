#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY="${SSH_KEY:-$HOME/.ssh/team_internal}"

HOSTS=(
    team-17-nn
    team-17-00
    team-17-01
)

JAVA17_OPENS='--add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.math=ALL-UNNAMED --add-opens=java.base/java.net=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent=ALL-UNNAMED --add-opens=java.base/java.util.zip=ALL-UNNAMED --add-opens=java.base/sun.security.util=ALL-UNNAMED --add-opens=java.base/sun.security.x509=ALL-UNNAMED --enable-native-access=ALL-UNNAMED'

for host in "${HOSTS[@]}"; do
    scp -q -i "$KEY" \
        "$ROOT_DIR/config/yarn-site.xml" \
        "$ROOT_DIR/config/mapred-site.xml" \
        "team@$host:/tmp/"

    ssh -i "$KEY" "team@$host" bash -s -- "$JAVA17_OPENS" <<'REMOTE'
set -euo pipefail

JAVA17_OPENS="$1"

sudo install -o hadoop -g hadoop -m 644 \
    /tmp/yarn-site.xml \
    /opt/hadoop/etc/hadoop/yarn-site.xml

sudo install -o hadoop -g hadoop -m 644 \
    /tmp/mapred-site.xml \
    /opt/hadoop/etc/hadoop/mapred-site.xml

if ! sudo grep -q '^# HADOOP_JAVA17_OPENS$' \
    /opt/hadoop/etc/hadoop/hadoop-env.sh
then
    sudo tee -a /opt/hadoop/etc/hadoop/hadoop-env.sh >/dev/null <<EOF2

# HADOOP_JAVA17_OPENS
export HADOOP_JAVA17_OPENS="$JAVA17_OPENS"
export HADOOP_OPTS="\${HADOOP_OPTS:-} \$HADOOP_JAVA17_OPENS"
EOF2
fi

rm -f /tmp/yarn-site.xml /tmp/mapred-site.xml
REMOTE
done

echo "YARN configuration installed on all Hadoop nodes."
