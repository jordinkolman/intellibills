SET ROLE app_owner;

CREATE SCHEMA IF NOT EXISTS audit AUTHORIZATION app_owner;

REVOKE ALL ON SCHEMA audit FROM PUBLIC;

GRANT USAGE ON SCHEMA audit TO app_owner;
GRANT USAGE ON SCHEMA audit TO auditor;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA audit TO app_owner;
GRANT SELECT ON ALL TABLES IN SCHEMA audit TO auditor;

ALTER DEFAULT PRIVILEGES IN SCHEMA audit
GRANT ALL PRIVILEGES ON TABLES TO app_owner;

ALTER DEFAULT PRIVILEGES IN SCHEMA audit
GRANT SELECT ON TABLES TO auditor;


CREATE TABLE audit.audit_event(
  id UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
  event_time TIMESTAMPTZ NOT NULL DEFAULT now(),
  request_id UUID,
  txid xid8 DEFAULT pg_current_xact_id_if_assigned(),
  db_role text NOT NULL,
  user_id UUID,
  operation TEXT NOT NULL,
  table_name TEXT NOT NULL,
  query TEXT NOT NULL,
  session_id UUID NOT NULL,
  client_addr inet NOT NULL,
  source TEXT NOT NULL DEFAULT 'pgaudit'
);

CREATE INDEX idx_audit_event_time ON audit.audit_event (event_time);
CREATE INDEX idx_audit_event_request_id ON audit.audit_event (request_id);
CREATE INDEX idx_audit_event_user_id ON audit.audit_event (user_id);

CREATE TABLE audit.audit_row_change(
  id UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
  event_time TIMESTAMPTZ NOT NULL DEFAULT now(),
  request_id UUID,
  txid xid8 DEFAULT pg_current_xact_id_if_assigned(),
  table_name TEXT NOT NULL,
  operation TEXT NOT NULL,
  db_role TEXT NOT NULL,
  user_id UUID,
  row_pk jsonb,
  before_data jsonb,
  after_data jsonb
);

CREATE INDEX idx_audit_row_change_event_time ON audit.audit_row_change (event_time);
CREATE INDEX idx_audit_row_change_request_id ON audit.audit_row_change (request_id);
CREATE INDEX idx_audit_row_change_user_id ON audit.audit_row_change (user_id);

CREATE OR REPLACE FUNCTION audit.log_row_change()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = audit, public
AS $$
DECLARE 
  v_tenant_id uuid; 
  v_request_id uuid;
BEGIN
IF TG_TABLE_SCHEMA = 'audit' THEN
  RETURN NULL;
END IF;
v_tenant_id := NULLIF(current_setting('app.context.current_tenant_id', true), '')::uuid;
v_request_id := NULLIF(current_setting('app.context.request_id', true), '')::uuid;
IF TG_OP = 'INSERT' THEN
INSERT INTO audit.audit_row_change
(table_name, request_id, operation, db_role, user_id, row_pk, after_data) 
VALUES 
(TG_TABLE_NAME, v_request_id, TG_OP, current_user, v_tenant_id, to_jsonb(NEW.id), to_jsonb(NEW));
RETURN NEW;
ELSIF TG_OP = 'UPDATE' AND NEW IS DISTINCT FROM OLD THEN
INSERT INTO audit.audit_row_change
(table_name, request_id, operation, db_role, user_id, row_pk, before_data, after_data)
VALUES
(TG_TABLE_NAME, v_request_id, TG_OP, current_user, v_tenant_id, to_jsonb(NEW.id), to_jsonb(OLD), to_jsonb(NEW));
RETURN NEW;
ELSIF TG_OP = 'DELETE' THEN
INSERT INTO audit.audit_row_change
(table_name, request_id, operation, db_role, user_id, row_pk, before_data)
VALUES
(TG_TABLE_NAME, v_request_id, TG_OP, current_user, v_tenant_id, to_jsonb(OLD.id), to_jsonb(OLD));
RETURN OLD;
END IF;
RETURN NULL;
END; $$
LANGUAGE PLPGSQL;


