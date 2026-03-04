BEGIN;
SELECT plan(2);

-- Ensure we are app_owner to see audit tables
SET ROLE app_owner;

-- Setup context
SELECT set_config('app.context.current_tenant_id', gen_random_uuid()::text, true);
SELECT set_config('app.context.request_id', gen_random_uuid()::text, true);

-- Perform an action that should be audited
INSERT INTO core.user_data (email) 
VALUES ('audit_test@example.com');

-- Verify audit log
SELECT is(
    (SELECT COUNT(*)::integer FROM audit.audit_row_change WHERE table_name = 'user_data' AND operation = 'INSERT'),
    1,
    'Audit log should capture the INSERT operation on core.user_data'
);

SELECT ok(
    (SELECT (after_data->>'email') = 'audit_test@example.com' FROM audit.audit_row_change WHERE table_name = 'user_data' LIMIT 1),
    'Audit log should contain the correct after_data payload'
);

SELECT * FROM finish();
ROLLBACK;
