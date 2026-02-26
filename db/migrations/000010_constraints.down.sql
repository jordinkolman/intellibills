ALTER TABLE audit.audit_row_change DROP CONSTRAINT IF EXISTS fk_audit_row_change_user;

ALTER TABLE audit.audit_event DROP CONSTRAINT IF EXISTS fk_audit_event_session;

ALTER TABLE audit.audit_event DROP CONSTRAINT IF EXISTS fk_audit_event_user;
