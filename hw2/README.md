# Homework 2 — YARN and Web Interfaces

## Cluster

- `team-17-en` — edge node with external address `178.236.27.243`
- `team-17-nn` (`10.17.0.11`) — NameNode, SecondaryNameNode, DataNode, ResourceManager, JobHistoryServer
- `team-17-00` (`10.17.0.12`) — DataNode, NodeManager
- `team-17-01` (`10.17.0.13`) — DataNode, NodeManager

## Deployment

After Hadoop and HDFS from HW1 are running, the complete HW2 deployment can be performed on `team-17-en` with:

```bash
./hw2/deploy.sh
```

The deployment script:

1. installs `yarn-site.xml` and `mapred-site.xml` on all Hadoop nodes;
2. applies the Java 17 compatibility options required by Hadoop 3.4.0;
3. starts the ResourceManager;
4. starts both NodeManagers;
5. starts the MapReduce JobHistory Server;
6. checks the cluster.

## Manual deployment

Individual steps can also be executed separately:

```bash
./scripts/configure_yarn.sh
./scripts/start_yarn.sh
./scripts/start_historyserver.sh
./scripts/check_yarn.sh
```

## Verification

The expected YARN state is:

- `team-17-nn` — ResourceManager is running;
- `team-17-00` — NodeManager is running;
- `team-17-01` — NodeManager is running;
- `yarn node -list` reports two nodes in `RUNNING` state.

The cluster can be checked with:

```bash
./scripts/check_yarn.sh
```

A successful check prints:

```text
YARN cluster check passed.
```

## Web interfaces

The Hadoop cluster is located in an internal network.

The external address `178.236.27.243` is NATed to `team-17-en`, while the Hadoop web interfaces are located on the internal cluster network. Direct access to the Hadoop web ports from the Internet is not available.

External access is provided through SSH local port forwarding via `team-17-en`.

Run the tunnel script on the local computer, not on a cluster node:

```bash
./scripts/tunnels.sh
```

Keep the SSH session open while using the web interfaces.

| Local address | Component | Internal endpoint |
|---|---|---|
| `http://localhost:9870` | NameNode | `10.17.0.11:9870` |
| `http://localhost:8088/cluster` | ResourceManager | `10.17.0.11:8088` |
| `http://localhost:9868` | SecondaryNameNode | `10.17.0.11:9868` |
| `http://localhost:19888/jobhistory` | JobHistoryServer | `10.17.0.11:19888` |
| `http://localhost:8042` | NodeManager `team-17-00` | `10.17.0.12:8042` |
| `http://localhost:8043` | NodeManager `team-17-01` | `10.17.0.13:8042` |
| `http://localhost:9864` | DataNode `team-17-nn` | `10.17.0.11:9864` |
| `http://localhost:9865` | DataNode `team-17-00` | `10.17.0.12:9864` |
| `http://localhost:9866` | DataNode `team-17-01` | `10.17.0.13:9864` |

## Stopping the services

Stop the JobHistory Server:

```bash
./scripts/stop_historyserver.sh
```

Stop YARN:

```bash
./scripts/stop_yarn.sh
```

The SSH tunnel is stopped with `Ctrl+C` in the terminal where `tunnels.sh` is running.
