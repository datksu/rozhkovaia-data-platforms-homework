# Homework 1 — HDFS Cluster Deployment

Automated deployment of an HDFS cluster based on Apache Hadoop 3.4.0.

## Architecture

The cluster consists of:

| Host | Services |
| --- | --- |
| `team-17-nn` | NameNode, SecondaryNameNode, DataNode |
| `team-17-00` | DataNode |
| `team-17-01` | DataNode |

The `team-17-en` host is used as an edge node from which deployment and cluster management scripts are executed.

The HDFS replication factor is set to 3.

## Requirements

The scripts are expected to be executed from `team-17-en`.

The edge node must have:

- SSH access to `team-17-nn`, `team-17-00`, and `team-17-01`
- the internal SSH key at `~/.ssh/team_internal`
- passwordless `sudo` for the `team` user on the cluster nodes

The deployment script automatically installs:

- OpenJDK 17
- Apache Hadoop 3.4.0
- the `hadoop` system user required to run HDFS services

## Repository structure

```text
hw1/
├── README.md
├── deploy.sh
├── config/
│   ├── core-site.xml
│   └── hdfs-site.xml
└── scripts/
    ├── install.sh
    ├── configure.sh
    ├── start_cluster.sh
    ├── stop_cluster.sh
    └── check_cluster.sh
```

## Deployment

Make the scripts executable:

```bash
chmod +x deploy.sh scripts/*.sh
```

Deploy the cluster:

```bash
./deploy.sh
```

The script:

1. installs Java and Hadoop on the cluster nodes;
2. creates the `hadoop` user if it does not exist;
3. distributes the HDFS configuration;
4. prepares the NameNode and DataNode storage directories;
5. formats the NameNode if it has not been formatted before;
6. starts the HDFS services;
7. verifies cluster health and replication.

The NameNode is formatted only if `/data/hdfs/namenode/current/VERSION` does not exist.

## Cluster verification

Run:

```bash
./scripts/check_cluster.sh
```

A correctly functioning cluster must report:

```text
Live datanodes (3):
```

The automated check also creates a temporary HDFS file with replication factor 3 and verifies that the block has three live replicas.

Expected FSCK results include:

```text
Status: HEALTHY
Live_repl=3
Under-replicated blocks: 0
Missing blocks: 0
Corrupt blocks: 0
```

The temporary health-check file is removed automatically after verification.

## Start the cluster

```bash
./scripts/start_cluster.sh
```

## Stop the cluster

```bash
./scripts/stop_cluster.sh
```

## NameNode Web UI

From the local machine, create an SSH tunnel through the edge node:

```bash
ssh -L 9870:team-17-nn:9870 team@<EDGE_PUBLIC_IP>
```

Then open:

```text
http://localhost:9870
```

The NameNode interface should show three live DataNodes and no dead DataNodes.
