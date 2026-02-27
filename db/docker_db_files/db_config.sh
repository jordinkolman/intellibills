#!/bin/bash
set -e

if [ -z "$APP_RUNTIME_PASSWORD" ] || [ -z "$APP_WORKER_PASSWORD" ] || [ -z "$APP_ADMIN_PASSWORD" ] || [ -z "$AUDITOR_PASSWORD" ]; then
  echo "Error: One or more role passwords are not set in the current environment."
  exit 1
fi

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" << EOSQL
  -- schema, table, and trigger owner; cannot login
  CREATE ROLE app_owner NOLOGIN;

  -- LOGIN ROLES (IDENTITIES)
  CREATE ROLE app_runtime LOGIN PASSWORD '${APP_RUNTIME_PASSWORD}';
  CREATE ROLE app_worker LOGIN PASSWORD '${APP_WORKER_PASSWORD}' BYPASSRLS;
  CREATE ROLE app_admin LOGIN PASSWORD '${APP_ADMIN_PASSWORD}' BYPASSRLS IN ROLE app_owner;
  CREATE ROLE auditor LOGIN PASSWORD '${AUDITOR_PASSWORD}';

  -- Set Permissions
  ALTER DATABASE intellibills OWNER TO app_owner;

  GRANT CONNECT ON DATABASE intellibills TO app_runtime;
  GRANT CONNECT ON DATABASE intellibills TO app_admin;
  GRANT CONNECT ON DATABASE intellibills TO app_worker;
  GRANT CONNECT ON DATABASE intellibills TO auditor;

  CREATE EXTENSION IF NOT EXISTS pgaudit;
  CREATE EXTENSION IF NOT EXISTS pgcrypto;
  CREATE EXTENSION IF NOT EXISTS btree_gist;

EOSQL

