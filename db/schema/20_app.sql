CREATE SCHEMA app;

GRANT USAGE ON SCHEMA app TO indibills_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA app TO indibills_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA app
GRANT ALL PRIVILEGES ON TABLES TO indibills_user;

CREATE TABLE app.rls_admins (
  id BIGSERIAL PRIMARY KEY,
  db_user text NOT NULL
);

INSERT INTO app.rls_admins (db_user) VALUES ('indibills_user');

CREATE TABLE app.users (
  id BIGSERIAL PRIMARY KEY,
  user_name text NOT NULL,
  password bytea NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
)

CREATE OR REPLACE TRIGGER audit_user_changes
AFTER INSERT OR UPDATE OR DELETE ON app.users
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();
