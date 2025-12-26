DROP TABLE IF EXISTS access_logs;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS rls_admins;

CREATE TABLE rls_admins (
  user_name TEXT PRIMARY KEY
)

CREATE TABLE access_logs ( 
	id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, 
	user_name VARCHAR(20) NOT NULL,
	logged_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	table_name VARCHAR(20) NOT NULL,
	operation TEXT CHECK (operation IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')),
  access_source VARCHAR(50) NOT NULL
);

CREATE INDEX idx_access_logs_logged_at ON access_logs (logged_at);
CREATE INDEX idx_access_logs_user_name ON access_logs (user_name);
CREATE INDEX idx_access_logs_table_name ON access_logs (table_name);

CREATE OR REPLACE FUNCTION log_access() RETURNS trigger AS $$
BEGIN
INSERT INTO access_logs (
  user_name, 
  table_name, 
  operation, 
  access_source
  )
  VALUES (
  SESSION_USER, 
  TG_TABLE_NAME, 
  TG_OP, 
  COALESCE(
    NULLIF(current_setting('application_name', true), ''),
    'psql'
  ),
  );
RETURN NULL;
END; $$
LANGUAGE PLPGSQL;

CREATE EXTENSION pgcrypto;

CREATE TABLE users (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_name VARCHAR(20) NOT NULL,
  encrypt_hash_password bytea NOT NULL
);

CREATE OR REPLACE TRIGGER trg_log_user_access
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW
EXECUTE FUNCTION log_access();

CREATE POLICY deny_all_policy
ON users
USING (false);

CREATE POLICY tenant_isolation_policy ON users
USING (id = current_setting('app.current_tenant_id', true)::BIGINT
OR EXISTS (SELECT 1 FROM rls_admins WHERE user_name = current_user));
