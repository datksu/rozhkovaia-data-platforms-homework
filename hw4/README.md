# HW4 — Apache Spark on YARN: HDFS transformation and Hive table

Run Apache Spark **3.5.3 under YARN**, read data from HW3 in HDFS, transform and aggregate six event records, write date-partitioned Parquet, register an external Hive table, and verify it from Beeline.

## Prerequisites

- **HW1:** Hadoop 3.4.0 / Java 17, HDFS operational, three DataNodes.
- **HW2:** YARN running with ResourceManager and at least two registered NodeManagers.
- **HW3:** PostgreSQL Metastore and HiveServer2 active, six HW3 event records at `hdfs://team-17-nn:9000/user/hive/warehouse/hw3_events`.
- SSH from `team-17-en` to `team-17-nn` via `~/.ssh/team_internal`, `sudo` access as in earlier homework.
- Network access to the Apache archive only if Spark has not yet been installed.

Spark is executed via **YARN**, not by starting Spark Standalone Master/Workers.

## Automated deployment

On `team-17-en`, from the repository root:

```bash
./hw4/deploy.sh
```

This copies the submission to `/home/team/hw4` on `team-17-nn`, then executes:

1. `scripts/prerequisites.sh`: verify HDFS, YARN, Hive and source HDFS directory.
2. `scripts/install_spark.sh`: reuse Spark 3.5.3 when present; otherwise download the verified SHA-512 `without-hadoop` binary, install in `/opt/spark`.
3. `scripts/run_spark.sh`: launch **`spark-shell --master yarn --deploy-mode client`** with one executor, execute `transform.scala`, and require a successful completion marker.
4. `scripts/register_hive.sh`: register an external Hive table with SQL via the existing HiveServer2 endpoint.
5. `scripts/check_results.sh`: verify HDFS Parquet partition files and the exact results returned by a standard Hive Beeline client.

The Spark job uses the real Hadoop 3.4.0 libraries through `SPARK_DIST_CLASSPATH=$(/opt/hadoop/bin/hadoop classpath)` and `HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop`. No Hadoop, YARN or Hive daemon is restarted or reconfigured. The job overwrites **only** `/user/hive/warehouse/hw4_events_agg`; input HW3 data remain unchanged.

## Data processing pipeline

```text
Spark driver: team-17-nn; YARN application through HW2 ResourceManager
  -> Spark reads HW3 CSVs in HDFS (dt=... directory partitions)
  -> cast id/user_id to INT, value to DOUBLE; validate non-null values
  -> id declared nullable=false after validation
  -> filter, groupBy(dt), count/sum/avg, round to 2 decimal places
  -> Spark writes date-partitioned Parquet using partitionBy("dt")
  -> Beeline CREATE EXTERNAL TABLE + MSCK REPAIR TABLE
  -> Beeline SELECT verifies the Hive-accessible result
```

Spark 3.5.3 does **not** connect directly to the Hive 4.1.0 Metastore. The separately registered external table provides the required Hive interoperability without version-dependent Metastore integration.

Input table: `default.hw3_events` (six rows, three dates). Output table: `default.hw4_events_agg` over the partitioned files at `/user/hive/warehouse/hw4_events_agg`.

| dt | event_count | total_value | avg_value |
|---|---:|---:|---:|
| 2026-10-20 | 2 | 3.5 | 1.75 |
| 2026-10-21 | 2 | 18.5 | 9.25 |
| 2026-10-22 | 2 | 21.5 | 10.75 |

## Manual verification

On `team-17-nn`, check the existing Spark job log:

```bash
grep -E 'HW4 YARN application:|HW4_SPARK_OK' /tmp/hw4-spark.log
```

Run the stages separately without reinstalling anything:

```bash
bash /home/team/hw4/scripts/run_spark.sh
bash /home/team/hw4/scripts/register_hive.sh
bash /home/team/hw4/scripts/check_results.sh
```

For an interactive YARN session, set the environment variables from `run_spark.sh` and execute:

```bash
/opt/spark/bin/spark-shell --master yarn --deploy-mode client \
  --driver-memory 1g --executor-memory 1g --executor-cores 1 \
  --num-executors 1 --conf spark.yarn.am.memory=512m
```

At the Scala prompt run `sc.master` (expected `yarn`) and `sc.applicationId` (a YARN application ID); exit with `:quit`.

## Compatibility and references

Spark 3.5.3 uses Java 17 and the `without-hadoop` distribution against our Hadoop 3.4.0 libraries; Hive 4.1.0 reads the Parquet output. The interactive workflow was already validated manually, while the packaged automated workflow should also be tested end-to-end before submission.

- [Spark 3.5.3: Running on YARN](https://downloads.apache.org/spark/docs/3.5.3/running-on-yarn.html)
- [Spark: Hadoop-free build](https://spark.apache.org/docs/3.5.3/hadoop-provided.html)
- [Spark SQL Parquet](https://spark.apache.org/docs/3.5.3/sql-data-sources-parquet.html)
