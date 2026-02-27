SET ROLE app_owner;

ALTER TABLE IF EXISTS audit.audit_row_change DROP CONSTRAINT IF EXISTS fk_audit_row_change_user;

ALTER TABLE IF EXISTS audit.audit_event DROP CONSTRAINT IF EXISTS fk_audit_event_session;

ALTER TABLE IF EXISTS audit.audit_event DROP CONSTRAINT IF EXISTS fk_audit_event_user;
