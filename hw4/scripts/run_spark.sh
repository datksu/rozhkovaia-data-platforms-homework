#!/usr/bin/env bash
set -euo pipefail
LOG=/tmp/hw4-spark.log
sudo install -o "$(id -un)" -g "$(id -gn)" -m 644 /dev/null "$LOG"
sudo install -o hadoop -g hadoop -m 644 /home/team/hw4/scripts/transform.scala /tmp/hw4-transform.scala
sudo -u hadoop bash -c '
  set -euo pipefail
  export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
  export HADOOP_HOME=/opt/hadoop
  export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
  export YARN_CONF_DIR=/opt/hadoop/etc/hadoop
  export SPARK_HOME=/opt/spark
  export SPARK_DIST_CLASSPATH="$(/opt/hadoop/bin/hadoop classpath)"
  /opt/spark/bin/spark-shell \
    --master yarn \
    --deploy-mode client \
    --driver-memory 1g \
    --executor-memory 1g \
    --executor-cores 1 \
    --num-executors 1 \
    --conf spark.yarn.am.memory=512m \
    -i /tmp/hw4-transform.scala
' 2>&1 | tee "$LOG"
grep -q '^HW4_SPARK_OK$' "$LOG" || { echo 'Spark pipeline failed; see /tmp/hw4-spark.log' >&2; exit 1; }
echo 'YARN Spark transformation and partitioned Parquet write: OK'
