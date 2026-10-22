# HW3 — Apache Hive: concurrent clients and partitioned data

Deploys Apache Hive 4.1.0 with a **remote Thrift Metastore backed by PostgreSQL 16** and **HiveServer2**, then automatically loads a three-partition table in HDFS. No embedded Derby is used.

## Prerequisites

- VM topology from HW1: edge `team-17-en` (SSH key `~/.ssh/team_internal`), NameNode `team-17-nn`, DataNodes `team-17-00` and `team-17-01`.
- HW1 already deployed: Hadoop 3.4.0, Java 17, running HDFS, Linux service user `hadoop`.
- Ubuntu 24.04, sudo access for `team` on `team-17-nn`; Internet access to Apache archive and Ubuntu apt repositories.
- Run commands on `team-17-en` from the repository root.

Hive 4.1.0 was released/tested against Hadoop 3.4.1; this homework cluster uses Hadoop 3.4.0. The working combination was verified manually with `SHOW DATABASES`, two Beeline sessions and partitioned CSV loads. Hadoop 3.4.0 is **not replaced** by this deployment.

## Automated deployment

```bash
./hw1/deploy.sh       # only on a fresh cluster; skips this step if HW1 already works
./hw3/deploy.sh
```

`hw3/deploy.sh` copies the HW3 assets from the edge VM to `/home/team/hw3` on `team-17-nn`, and runs, in order:

1. `prerequisites.sh` — verifies Hadoop/HDFS and installs PostgreSQL and JDBC dependencies.
2. `install_hive.sh` — downloads Hive 4.1.0, verifies SHA-256, installs in `/opt/apache-hive-4.1.0-bin` with symlink `/opt/hive`.
3. `setup_postgres.sh` — creates/updates the `hive` PostgreSQL role and `hive_metastore` DB; keeps PostgreSQL on loopback.
4. `configure_hive.sh` — renders `hive-site.xml`, creates HDFS warehouse, initializes the Metastore schema only if necessary.
5. `start_services.sh` — reconciles manually started Hive listeners, installs and starts two systemd services.
6. `load_data.sh` — loads three CSV files into partitions via SQL `LOAD DATA LOCAL ... OVERWRITE`.
7. `check_hive.sh` — checks two concurrent Beeline clients, three partitions, six records and HDFS files.

Rerunning the deployment preserves PostgreSQL metadata and overwrites data only in the three sample table partitions; it does not format HDFS.

## Architecture

```text
Beeline clients -> team-17-nn:10000 (HiveServer2)
                -> team-17-nn:9083 (remote Thrift Metastore)
                -> localhost:5432 (PostgreSQL, hive_metastore database)
Hive managed table files -> hdfs://team-17-nn:9000/user/hive/warehouse
```

PostgreSQL credentials are **not in Git**. Deployment generates a random password in `/etc/hive/metastore-password` (root-only) and writes the protected Hive configuration at `/opt/hive/conf/hive-site.xml` (mode `0600`, owner `hadoop`).

The configuration sets `metastore.event.db.notification.api.auth=false` to permit HiveServer2 to initialize its notification event poll in this non-Kerberized teaching cluster. `hive.server2.enable.doAs=false` means Hive statements run as the shared service user, not with per-client impersonation. This demonstrates multiple concurrent client **connections**, not production-grade authentication, authorization or isolation. Ports 9083 and 10000 are for the internal teaching network.

## Verification and sample data

Table: `default.hw3_events` with columns `id INT`, `user_id INT`, `event_type STRING`, `value DOUBLE`, partition column `dt STRING`. Source data lives in `data/`; SQL commands in `sql/load.sql`.

Expected output of `SHOW PARTITIONS hw3_events;`:

```text
dt=2026-10-20
dt=2026-10-21
dt=2026-10-22
```

`SELECT * FROM hw3_events;` returns 6 records; HDFS contains three `dt=.../events_....csv` paths. The CSV files contain partition **data columns only**; dates are supplied by `PARTITION (dt='...')` in the corresponding load commands.

To rerun the verification without reinstalling anything:

```bash
ssh -i ~/.ssh/team_internal team@team-17-nn 'bash /home/team/hw3/scripts/check_hive.sh'
```

To load the sample data again:

```bash
ssh -i ~/.ssh/team_internal team@team-17-nn 'bash /home/team/hw3/scripts/load_data.sh'
```

To inspect daemon logs:

```bash
ssh -i ~/.ssh/team_internal team@team-17-nn \
    'sudo journalctl -u hive-metastore -u hive-hiveserver2 -n 100 --no-pager'
```

To stop Hive (does not stop HDFS or PostgreSQL):

```bash
ssh -i ~/.ssh/team_internal team@team-17-nn \
    'bash /home/team/hw3/scripts/stop_services.sh'
```

## Version rationale

The homework recommends Hive 4.0.0-alpha-2. We use stable Hive 4.1.0 because it supports Java 17, which is already used by our Hadoop 3.4.0 cluster, while the older 4.0.x branch requires a different Java version. Hive 4.1.0's officially paired Hadoop version is 3.4.1; the slight patch mismatch with our 3.4.0 is explicitly tested in the verification workflow.

References: [Apache Hive downloads](https://hive.apache.org/general/downloads/), [Metastore administration](https://hive.apache.org/docs/latest/admin/adminmanual-metastore-administration/), [Hive DML](https://hive.apache.org/docs/latest/language/languagemanual-dml/).
