SET ROLE app_owner;

CREATE SCHEMA IF NOT EXISTS auth AUTHORIZATION app_owner;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO app_owner;

ALTER DEFAULT PRIVILEGES IN SCHEMA auth
GRANT ALL PRIVILEGES ON TABLES TO app_owner;

GRANT USAGE ON SCHEMA auth TO app_runtime;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO app_runtime;

REVOKE INSERT, UPDATE, DELETE ON auth.hash_algo FROM app_runtime;

GRANT USAGE ON SCHEMA auth TO app_worker;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO app_worker;

ALTER DEFAULT PRIVILEGES IN SCHEMA auth
GRANT ALL PRIVILEGES ON TABLES TO app_runtime;

ALTER DEFAULT PRIVILEGES IN SCHEMA auth
GRANT ALL PRIVILEGES ON TABLES TO app_worker;

CREATE TABLE IF NOT EXISTS auth.hash_algo (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS auth.user_session (
  id UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  refresh_token_hash BYTEA NOT NULL UNIQUE,
  hash_algo_id UUID NOT NULL,
  user_agent TEXT NOT NULL,
  ip_address INET NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  revoked_at TIMESTAMPTZ,
  FOREIGN KEY (user_id) REFERENCES core.user_data(id) ON DELETE RESTRICT,
  FOREIGN KEY (hash_algo_id) REFERENCES auth.hash_algo(id) ON DELETE RESTRICT,
  CHECK (revoked_at IS NULL OR revoked_at >= created_at)
);

CREATE INDEX idx_user_session_user_id ON auth.user_session (user_id);
CREATE INDEX idx_user_session_ip_address ON auth.user_session (ip_address);
CREATE INDEX idx_user_session_active ON auth.user_session (user_id) WHERE revoked_at IS NULL;

CREATE OR REPLACE TRIGGER audit_user_sessions 
AFTER INSERT OR UPDATE OR DELETE ON auth.user_session
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();

CREATE TABLE IF NOT EXISTS auth.email_verification (
  id UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  token_hash BYTEA NOT NULL UNIQUE,
  hash_algo_id UUID NOT NULL,
  is_active BOOLEAN DEFAULT true,
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL,
  FOREIGN KEY (user_id) REFERENCES core.user_data(id) ON DELETE RESTRICT,
  FOREIGN KEY (hash_algo_id) REFERENCES auth.hash_algo(id) ON DELETE RESTRICT,
  CHECK (is_verified = false OR expires_at > created_at)
);

CREATE OR REPLACE TRIGGER audit_email_verification_changes
AFTER INSERT OR UPDATE OR DELETE ON auth.email_verification
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();

CREATE FUNCTION auth.deactivate_previous_email_verification()
RETURNS TRIGGER
SET search_path = auth, public
AS $$
BEGIN
  UPDATE auth.email_verification
  SET 
    expires_at = now(),
    updated_at = now(),
    is_active = false
  WHERE user_id = NEW.user_id
    AND is_verified = false
    AND expires_at > now();

  RETURN NEW;
END; $$
LANGUAGE PLPGSQL;


CREATE OR REPLACE TRIGGER new_email_verification
BEFORE INSERT ON auth.email_verification
FOR EACH ROW 
EXECUTE FUNCTION auth.deactivate_previous_email_verification();

CREATE INDEX idx_email_verification_user_id ON auth.email_verification (user_id);
CREATE UNIQUE INDEX ux_email_verification_active ON auth.email_verification (user_id)
WHERE is_verified = false AND is_active = true;

CREATE TABLE IF NOT EXISTS auth.password_credential (
  id UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  password_hash BYTEA NOT NULL,
  hash_algo_id UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_rotated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (user_id) REFERENCES core.user_data(id) ON DELETE RESTRICT,
  FOREIGN KEY (hash_algo_id) REFERENCES auth.hash_algo(id)
);

CREATE INDEX idx_password_credential_last_rotated_at ON auth.password_credential (last_rotated_at);
CREATE UNIQUE INDEX ux_password_credential_user ON auth.password_credential (user_id);

CREATE OR REPLACE TRIGGER audit_password_credential_changes
AFTER INSERT OR UPDATE OR DELETE ON auth.password_credential
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();

CREATE TABLE IF NOT EXISTS auth.password_reset (
  id UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
  password_credential_id UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL,
  FOREIGN KEY (password_credential_id) REFERENCES auth.password_credential(id) ON DELETE CASCADE
);

CREATE INDEX idx_password_reset_expires_at ON auth.password_reset (expires_at);

CREATE OR REPLACE TRIGGER audit_password_reset_events 
AFTER INSERT OR UPDATE OR DELETE ON auth.password_reset
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();
