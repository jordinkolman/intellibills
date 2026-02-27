SET ROLE app_owner;

-- Apply audit_event foreign keys
ALTER TABLE audit.audit_event
  ADD CONSTRAINT fk_audit_event_user
  FOREIGN KEY (user_id) REFERENCES core.user_data(id) ON DELETE RESTRICT;

ALTER TABLE audit.audit_event
  ADD CONSTRAINT fk_audit_event_session
  FOREIGN KEY (session_id) REFERENCES auth.user_session(id) ON DELETE RESTRICT;

-- Apply audit_row_change foreign keys
ALTER TABLE audit.audit_row_change
  ADD CONSTRAINT fk_audit_row_change_user
  FOREIGN KEY (user_id) REFERENCES core.user_data(id) ON DELETE RESTRICT;
