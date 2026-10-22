#!/usr/bin/env bash
set -euo pipefail
sudo systemctl stop hive-hiveserver2.service hive-metastore.service
sudo systemctl status hive-hiveserver2.service hive-metastore.service --no-pager || true
