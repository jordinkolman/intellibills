BEGIN;
SELECT plan(5);

-- Verify app_runtime cannot write to global tables
SET ROLE app_runtime;
SELECT throws_ok(
    'INSERT INTO auth.hash_algo (name) VALUES (''INVALID'')',
    '42501', -- insufficient_privilege
    NULL,
    'app_runtime should not be able to insert into auth.hash_algo'
);

-- Verify auditor is read-only in audit schema
SET ROLE auditor;
SELECT throws_ok(
    'INSERT INTO audit.audit_event (operation, table_name, query, session_id, client_addr) VALUES (''TEST'', ''TEST'', ''TEST'', gen_random_uuid(), ''127.0.0.1'')',
    '42501',
    NULL,
    'auditor should not be able to insert into audit.audit_event'
);

-- Verify app_worker can bypass RLS (check if role has bypassrls attribute)
RESET ROLE;
SELECT has_role('app_worker', 'app_worker role should exist');
SELECT ok(rolbypassrls, 'app_worker should have BYPASSRLS attribute') 
FROM pg_roles WHERE rolname = 'app_worker';

SELECT schema_privs_are('auth', 'app_runtime', ARRAY['USAGE'], 'app_runtime should have usage on auth schema');

SELECT * FROM finish();
ROLLBACK;
