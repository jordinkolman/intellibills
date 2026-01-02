CREATE SCHEMA core;

GRANT USAGE ON SCHEMA core TO app_owner;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA core TO app_owner;

ALTER DEFAULT PRIVILEGES IN SCHEMA core
GRANT ALL PRIVILEGES ON TABLES TO app_owner;

CREATE TABLE IF NOT EXISTS core."user" (
  id UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  first_name VARCHAR(50),
  archived BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_users_created_at ON core."user" (created_at);
CREATE UNIQUE INDEX ux_user_email ON core."user"(lower(email)) WHERE archived = false;

CREATE OR REPLACE TRIGGER audit_user_changes
AFTER INSERT OR UPDATE OR DELETE ON core."user"
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();

CREATE TABLE IF NOT EXISTS core.archived_user (
  user_id UUID PRIMARY KEY NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL,
  FOREIGN KEY (user_id) REFERENCES core."user"(id) ON DELETE RESTRICT
);

CREATE INDEX idx_archived_users_expires_at ON core.archived_user (expires_at);

CREATE OR REPLACE TRIGGER audit_archived_user_changes
AFTER INSERT OR UPDATE OR DELETE ON core.archived_user
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();


-- Schema Functions --
CREATE FUNCTION core.archive_user(p_user_id uuid) 
RETURNS void 
SECURITY DEFINER
SET search_path = core, public
AS $$
BEGIN
UPDATE core."user"
SET archived=true
WHERE id = p_user_id;
INSERT INTO core.archived_user (user_id, expires_at)
VALUES (p_user_id, now() + interval '30 days');
END; $$
LANGUAGE PLPGSQL;

-- Still need restore_user and purge_user functions
