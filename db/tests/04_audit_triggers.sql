BEGIN;
SELECT plan(23);

-- Ensure we are app_owner to see audit tables
SET ROLE app_owner;

-- Setup context
SELECT set_config('app.context.current_tenant_id', gen_random_uuid()::text, true);
SELECT set_config('app.context.request_id', gen_random_uuid()::text, true);

-- Perform an action that should be audited (INSERT)
INSERT INTO core.user_data (email) 
VALUES ('audit_test@example.com');

-- Verify INSERT audit log
SELECT is(
    (SELECT COUNT(*)::integer FROM audit.audit_row_change WHERE table_name = 'user_data' AND operation = 'INSERT'),
    1,
    'Audit log should capture the INSERT operation on core.user_data'
);

SELECT ok(
    (SELECT (after_data->>'email') = 'audit_test@example.com' FROM audit.audit_row_change WHERE table_name = 'user_data' AND operation = 'INSERT' LIMIT 1),
    'Audit log should contain the correct after_data payload for INSERT'
);

-- Verify Context Capture
SELECT ok(
    (SELECT 
        (request_id::text = current_setting('app.context.request_id', true)) AND 
        (user_id::text = current_setting('app.context.current_tenant_id', true)) AND 
        (db_role = 'app_owner') 
     FROM audit.audit_row_change WHERE table_name = 'user_data' AND operation = 'INSERT' LIMIT 1),
    'Audit log should exactly match session context for request_id, tenant_id, and db_role'
);

-- Perform an action that should be audited (UPDATE)
UPDATE core.user_data SET first_name = 'Audit' WHERE email = 'audit_test@example.com';

-- Verify UPDATE audit log
SELECT is(
    (SELECT COUNT(*)::integer FROM audit.audit_row_change WHERE table_name = 'user_data' AND operation = 'UPDATE'),
    1,
    'Audit log should capture the UPDATE operation on core.user_data'
);

SELECT ok(
    (SELECT ((before_data->>'first_name') IS NULL) AND ((after_data->>'first_name') = 'Audit') 
     FROM audit.audit_row_change WHERE table_name = 'user_data' AND operation = 'UPDATE' LIMIT 1),
    'Audit log should capture before_data and after_data correctly for UPDATE'
);

-- Perform an action that should be audited (DELETE)
DELETE FROM core.user_data WHERE email = 'audit_test@example.com';

-- Verify DELETE audit log
SELECT is(
    (SELECT COUNT(*)::integer FROM audit.audit_row_change WHERE table_name = 'user_data' AND operation = 'DELETE'),
    1,
    'Audit log should capture the DELETE operation on core.user_data'
);

SELECT ok(
    (SELECT ((before_data->>'email') = 'audit_test@example.com') AND (after_data IS NULL) 
     FROM audit.audit_row_change WHERE table_name = 'user_data' AND operation = 'DELETE' LIMIT 1),
    'Audit log should capture before_data and NULL after_data for DELETE'
);

-- Verify Trigger Existence programmatically via has_trigger
SELECT has_trigger('core', 'user_data', 'audit_user_changes', 'core.user_data should have audit trigger');
SELECT has_trigger('core', 'archived_user', 'audit_archived_user_changes', 'core.archived_user should have audit trigger');
SELECT has_trigger('auth', 'user_session', 'audit_user_sessions', 'auth.user_session should have audit trigger');
SELECT has_trigger('auth', 'email_verification', 'audit_email_verification_changes', 'auth.email_verification should have audit trigger');
SELECT has_trigger('auth', 'password_credential', 'audit_password_credential_changes', 'auth.password_credential should have audit trigger');
SELECT has_trigger('auth', 'password_reset', 'audit_password_reset_events', 'auth.password_reset should have audit trigger');
SELECT has_trigger('plaid', 'plaid_item', 'audit_plaid_items', 'plaid.plaid_item should have audit trigger');
SELECT has_trigger('plaid', 'plaid_sync_job', 'audit_plaid_sync_jobs', 'plaid.plaid_sync_job should have audit trigger');
SELECT has_trigger('plaid', 'plaid_webhook_event', 'audit_plaid_webhook_events', 'plaid.plaid_webhook_event should have audit trigger');
SELECT has_trigger('plaid', 'plaid_account', 'audit_plaid_accounts', 'plaid.plaid_account should have audit trigger');
SELECT has_trigger('finance', 'account', 'audit_account_changes', 'finance.account should have audit trigger');
SELECT has_trigger('finance', 'transaction', 'audit_transactions', 'finance.transaction should have audit trigger');
SELECT has_trigger('finance', 'income_stream', 'audit_income_streams', 'finance.income_stream should have audit trigger');
SELECT has_trigger('finance', 'transaction_income_override', 'audit_transaction_income_overrrides', 'finance.transaction_income_override should have audit trigger');
SELECT has_trigger('timekeeping', 'shift', 'audit_shifts', 'timekeeping.shift should have audit trigger');
SELECT has_trigger('timekeeping', 'shift_transaction', 'audit_shift_transactions', 'timekeeping.shift_transaction should have audit trigger');

SELECT * FROM finish();
ROLLBACK;
