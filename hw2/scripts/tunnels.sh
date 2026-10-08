#!/usr/bin/env bash
set -euo pipefail

KEY="${SSH_KEY:-$HOME/.ssh/team_internal}"
HOST="${SSH_HOST:-team@178.236.27.243}"

if [[ ! -f "$KEY" ]]; then
    echo "SSH key not found: $KEY" >&2
    echo "Set SSH_KEY to the path of the team private key." >&2
    exit 1
fi

exec ssh -T -N \
    -o ExitOnForwardFailure=yes \
    -o ServerAliveInterval=60 \
    -o ServerAliveCountMax=3 \
    -i "$KEY" \
    -L 9870:10.17.0.11:9870 \
    -L 8088:10.17.0.11:8088 \
    -L 9868:10.17.0.11:9868 \
    -L 19888:10.17.0.11:19888 \
    -L 8042:10.17.0.12:8042 \
    -L 8043:10.17.0.13:8042 \
    -L 9864:10.17.0.11:9864 \
    -L 9865:10.17.0.12:9864 \
    -L 9866:10.17.0.13:9864 \
    "$HOST"
