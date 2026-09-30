#!/usr/bin/env bash
set -euo pipefail

HADOOP_VERSION="3.4.0"
JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
KEY="${HOME}/.ssh/team_internal"
HOSTS=(team-17-nn team-17-00 team-17-01)

for host in "${HOSTS[@]}"; do
    ssh -i "$KEY" "team@$host" bash -s -- "$HADOOP_VERSION" "$JAVA_HOME" <<'REMOTE'
set -euo pipefail

HADOOP_VERSION="$1"
JAVA_HOME="$2"
HADOOP_HOME="/opt/hadoop"
ARCHIVE="/tmp/hadoop-${HADOOP_VERSION}.tar.gz"
URL="https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"

if ! id hadoop >/dev/null 2>&1; then
    sudo adduser --disabled-password --gecos "" hadoop
fi

sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-17-jdk wget

if [ ! -d "/opt/hadoop-${HADOOP_VERSION}" ]; then
    wget "$URL" -O "$ARCHIVE"
    sudo tar -xzf "$ARCHIVE" -C /opt
    rm -f "$ARCHIVE"
fi

sudo ln -sfn "/opt/hadoop-${HADOOP_VERSION}" "$HADOOP_HOME"
sudo chown -R hadoop:hadoop "/opt/hadoop-${HADOOP_VERSION}"

sudo sed -i '/^export JAVA_HOME=/d' \
    "$HADOOP_HOME/etc/hadoop/hadoop-env.sh"

printf 'export JAVA_HOME=%s\n' "$JAVA_HOME" |
    sudo tee -a "$HADOOP_HOME/etc/hadoop/hadoop-env.sh" >/dev/null
REMOTE
done
