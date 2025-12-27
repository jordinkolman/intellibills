CREATE SCHEMA audit AUTHORIZATION indibills_owner;

REVOKE ALL ON SCHEMA audit FROM PUBLIC;

GRANT USAGE ON SCHEMA audit TO indibills_user;
GRANT USAGE ON SCHEMA audit TO auditor;

GRANT INSERT, SELECT ON ALL TABLES IN SCHEMA audit TO indibills_user;
GRANT SELECT ON TABLES IN SCHEMA audit TO auditor;

ALTER DEFAULT PRIVILEGES IN SCHEMA audit
GRANT INSERT, SELECT ON TABLES TO indibills_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA audit
GRANT SELECT ON TABLES TO auditor;


CREATE TABLE audit.audit_events(
  id BIGSERIAL PRIMARY KEY,
  event_time TIMESTAMPTZ NOT NULL DEFAULT now(),
  db_user text NOT NULL,
  operation text NOT NULL,
  table_name text NOT NULL,
  query text,
  session_id text,
  client_addr inet,
  source text NOT NULL DEFAULT 'pgaudit'
);

ALTER TABLE audit.audit_event SET (autovacuum_enables = false);

CREATE TABLE audit.audit_row_changes(
  id BIGSERIAL PRIMARY KEY,
  event_time TIMESTAMPTZ NOT NULL DEFAULT now(),
  table_name text NOT NULL,
  operation text NOT NULL,
  db_user text NOT NULL,
  row_pk jsonb,
  before_data jsonb,
  after_data jsonb
);

CREATE OR REPLACE FUNCTION audit.log_row_change()
RETURNS TRIGGER AS $$
SECURITY DEFINER
BEGIN
IF TG_OP = 'INSERT' THEN
INSERT INTO audit.audit_row_changes
(table_name, operation, db_user, row_pk, after_data) 
VALUES 
(TG_TABLE_NAME, TG_OP, current_user, to_jsonb(NEW.id), to_jsonb(NEW));
RETURN NEW;
ELSIF TG_OP = 'UPDATE' THEN
INSERT INTO audit.audit_row_changes
(table_name, operation, db_user, row_pk, before_data, after_data)
VALUES
(TG_TABLE_NAME, TG_OP, current_user, to_jsonb(NEW.id), to_jsonb(OLD), to_jsonb(NEW));
RETURN NEW;
ELSIF TG_OP = 'DELETE' THEN
INSERT INTO audit.audit_row_changes
(table_name, operation, db_user, row_pk, before_data)
VALUES
(TG_TABLE_NAME, TG_OP, current_user, to_jsonb(OLD.id), to_jsonb(OLD));
RETURN OLD;
END IF;
END; $$
LANGUAGE: PLPGSQL;


