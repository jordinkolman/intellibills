CREATE SCHEMA core;

GRANT USAGE ON SCHEMA core TO app_owner;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA core TO app_owner;

ALTER DEFAULT PRIVILEGES IN SCHEMA core
GRANT ALL PRIVILEGES ON TABLES TO app_owner;

GRANT USAGE ON SCHEMA core TO app_runtime;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA core TO app_runtime;

GRANT USAGE ON SCHEMA core TO app_worker;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA core TO app_worker;

ALTER DEFAULT PRIVILEGES IN SCHEMA core
GRANT ALL PRIVILEGES ON TABLES TO app_runtime;

ALTER DEFAULT PRIVILEGES IN SCHEMA core
GRANT ALL PRIVILEGES ON TABLES TO app_worker;

CREATE TABLE IF NOT EXISTS core.user_data (
  id UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  first_name VARCHAR(50),
  archived BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_users_created_at ON core.user_data (created_at);
CREATE UNIQUE INDEX ux_user_email ON core.user_data (lower(email)) WHERE archived = false;

CREATE OR REPLACE TRIGGER audit_user_changes
AFTER INSERT OR UPDATE OR DELETE ON core.user_data
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();

CREATE TABLE IF NOT EXISTS core.archived_user (
  user_id UUID PRIMARY KEY NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL,
  FOREIGN KEY (user_id) REFERENCES core.user_data(id) ON DELETE RESTRICT
);

CREATE INDEX idx_archived_users_expires_at ON core.archived_user (expires_at);

CREATE OR REPLACE TRIGGER audit_archived_user_changes
AFTER INSERT OR UPDATE OR DELETE ON core.archived_user
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();



