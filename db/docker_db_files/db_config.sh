#!/bin/bash
set -e

if [ -z "$APP_RUNTIME_PASSWORD" ] || [ -z "$APP_WORKER_PASSWORD" ] || [ -z "$APP_ADMIN_PASSWORD" ] || [ -z "$AUDITOR_PASSWORD" ]; then
  echo "Error: One or more role passwords are not set in the current environment."
  exit 1
fi

psql -v ON_ERROR_STOP=1 \
  --username "$POSTGRES_USER" \
  --dbname "$POSTGRES_DB" \
  --set=postgres_db="$POSTGRES_DB" \
  --set=app_runtime_password="$APP_RUNTIME_PASSWORD" \
  --set=app_worker_password="$APP_WORKER_PASSWORD" \
  --set=app_admin_password="$APP_ADMIN_PASSWORD" \
  --set=auditor_password="$AUDITOR_PASSWORD" <<'EOSQL'
  -- schema, table, and trigger owner; cannot login
  CREATE ROLE app_owner NOLOGIN;

  -- LOGIN ROLES (IDENTITIES)
  SELECT format('CREATE ROLE app_runtime LOGIN PASSWORD %L', :'app_runtime_password') \gexec
  SELECT format('CREATE ROLE app_worker LOGIN PASSWORD %L BYPASSRLS', :'app_worker_password') \gexec
  SELECT format('CREATE ROLE app_admin LOGIN PASSWORD %L BYPASSRLS IN ROLE app_owner', :'app_admin_password') \gexec
  SELECT format('CREATE ROLE auditor LOGIN PASSWORD %L', :'auditor_password') \gexec

  -- Grant app_admin the ability to switch to other roles for testing/management
  GRANT app_runtime TO app_admin;
  GRANT auditor TO app_admin;
  GRANT app_worker TO app_admin;

  -- Set Permissions
  SELECT format('ALTER DATABASE %I OWNER TO app_owner', :'postgres_db') \gexec

  SELECT format('GRANT CONNECT ON DATABASE %I TO app_runtime', :'postgres_db') \gexec
  SELECT format('GRANT CONNECT ON DATABASE %I TO app_admin', :'postgres_db') \gexec
  SELECT format('GRANT CONNECT ON DATABASE %I TO app_worker', :'postgres_db') \gexec
  SELECT format('GRANT CONNECT ON DATABASE %I TO auditor', :'postgres_db') \gexec

  CREATE EXTENSION IF NOT EXISTS pgaudit;
  CREATE EXTENSION IF NOT EXISTS pgcrypto;
  CREATE EXTENSION IF NOT EXISTS btree_gist;
  CREATE EXTENSION IF NOT EXISTS pgtap;

EOSQL

