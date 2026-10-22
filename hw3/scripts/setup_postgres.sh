#!/usr/bin/env bash
set -euo pipefail

sudo install -d -o root -g root -m 700 /etc/hive
PASSWORD_FILE=/etc/hive/metastore-password
if ! sudo test -s "$PASSWORD_FILE"; then
    sudo sh -c "umask 077; openssl rand -hex 24 > '$PASSWORD_FILE'"
fi
DB_PASS="$(sudo cat "$PASSWORD_FILE")"
[[ "$DB_PASS" =~ ^[0-9a-f]{48}$ ]] || { echo 'Unexpected password format' >&2; exit 1; }

if [[ "$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='hive'")" == 1 ]]; then
    sudo -u postgres psql -v ON_ERROR_STOP=1 -c "ALTER ROLE hive PASSWORD '$DB_PASS';" >/dev/null
else
    sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE ROLE hive LOGIN PASSWORD '$DB_PASS';" >/dev/null
fi
if [[ "$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='hive_metastore'")" != 1 ]]; then
    sudo -u postgres createdb -O hive hive_metastore
fi
sudo -u postgres psql -v ON_ERROR_STOP=1 -c \
    'GRANT ALL PRIVILEGES ON DATABASE hive_metastore TO hive;' >/dev/null
unset DB_PASS

# PostgreSQL should remain localhost-only.
sudo ss -lnt | grep -q '127.0.0.1:5432' || {
    echo 'PostgreSQL is not listening on localhost:5432' >&2; exit 1;
}
echo 'PostgreSQL metastore database ready (password kept in /etc/hive).'
