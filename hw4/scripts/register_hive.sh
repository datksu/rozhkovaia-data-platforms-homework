#!/usr/bin/env bash
set -euo pipefail
sudo install -o hadoop -g hadoop -m 644 /home/team/hw4/sql/register_hive.sql /tmp/hw4-register-hive.sql
sudo -u hadoop env \
  JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
  HADOOP_HOME=/opt/hadoop \
  HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop \
  HIVE_HOME=/opt/hive \
  /opt/hive/bin/beeline \
  -u 'jdbc:hive2://team-17-nn:10000/default' \
  -n hadoop \
  -f /tmp/hw4-register-hive.sql
