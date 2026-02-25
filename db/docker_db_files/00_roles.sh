#!/bin/bash
set -e

if [-z "$APP_RUNTIME_PASSWORD"] || [-z "$APP_WORKER_PASSWORD"] || [-z "$APP_ADMIN_PASSWORD"] || [-z "$AUDITOR_PASSWORD"]; then
  echo "Error: One or more role passwords are not set in the current environment."
  exit 1
fi

psql -v ON_ERROR_STOP=1 --username = "$POSTGRES_USER" --dbname "$POSTGRES_DB" << EOSQL
  -- schema, table, and trigger owner; cannot login
  CREATE ROLE app_owner NOLOGIN;

  -- holder for BYPASSRLS privilege
  CREATE ROLE rls_bypasser NOLOGIN BYPASSRLS;

  -- LOGIN ROLES (IDENTITIES)
  CREATE ROLE app_runtime LOGIN PASSWORD '${APP_RUNTIME_PASSWORD}';
  CREATE ROLE app_worker LOGIN PASSWORD '${APP_WORKER_PASSWORD}';
  CREATE ROLE app_admin LOGIN PASSWORD '${APP_ADMIN_PASSWORD}';
  CREATE ROLE auditor LOGIN PASSWORD '${AUDITOR_PASSWORD}';
EOSQL

