#!/bin/bash
# Rails 8 keeps Solid Cache, Solid Queue and Action Cable in their own
# databases. PostgreSQL's entrypoint creates only POSTGRES_DB, so create the
# other three here. This runs once, on an empty data volume.
set -euo pipefail

for suffix in cache queue cable; do
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-SQL
    SELECT 'CREATE DATABASE ${POSTGRES_DB}_${suffix}'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${POSTGRES_DB}_${suffix}')\gexec
SQL
done
