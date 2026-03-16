BEGIN;
SELECT plan(16);

-- Set up valid account type to test subtype insert
SET ROLE app_admin;
INSERT INTO finance.account_type (name) VALUES ('depository');
SELECT set_config('app.test.account_type_id', (SELECT id::text FROM finance.account_type WHERE name='depository'), true);

-- Verify app_runtime cannot write to global tables
SET ROLE app_runtime;
SELECT throws_ok(
    'INSERT INTO auth.hash_algo (name) VALUES (''INVALID'')',
    '42501', -- insufficient_privilege
    NULL,
    'app_runtime should not be able to insert into auth.hash_algo'
);

SELECT throws_ok(
  'INSERT INTO finance.account_type (name) VALUES (''INVALID'')',
  '42501',
  NULL,
  'app_runtime should not be able to insert into finance.account_type'
);

SELECT throws_ok(
  'INSERT INTO finance.account_subtype (name, type_id) VALUES (''INVALID'', current_setting(''app.test.account_type_id'', true)::uuid)',
  '42501',
  NULL,
  'app_runtime should not be able to insert into finance.account_subtype'
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

-- Verify schema USAGE privileges for app_runtime
SELECT schema_privs_are('auth', 'app_runtime', ARRAY['USAGE'], 'app_runtime should have usage on auth schema');
SELECT schema_privs_are('core', 'app_runtime', ARRAY['USAGE'], 'app_runtime should have usage on core schema');
SELECT schema_privs_are('plaid', 'app_runtime', ARRAY['USAGE'], 'app_runtime should have usage on plaid schema');
SELECT schema_privs_are('finance', 'app_runtime', ARRAY['USAGE'], 'app_runtime should have usage on finance schema');
SELECT schema_privs_are('budget', 'app_runtime', ARRAY['USAGE'], 'app_runtime should have usage on budget schema');
SELECT schema_privs_are('timekeeping', 'app_runtime', ARRAY['USAGE'], 'app_runtime should have usage on timekeeping schema');

-- Verify execution privileges
SELECT ok(
    has_function_privilege('app_runtime', 'core.current_tenant()', 'EXECUTE'),
    'app_runtime should have EXECUTE privilege on core.current_tenant()'
);

-- Verify positive privileges for app_runtime on tenant-owned tables
SELECT table_privs_are('finance', 'account', 'app_runtime', ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE'], 'app_runtime should have DML privileges on finance.account');
SELECT table_privs_are('budget', 'user_category', 'app_runtime', ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE'], 'app_runtime should have DML privileges on budget.user_category');

-- Verify default privileges for newly created tables
SET ROLE app_owner;
CREATE TABLE finance.dummy_test_table (id int);
SELECT table_privs_are('finance', 'dummy_test_table', 'app_runtime', ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE'], 'app_runtime should automatically have DML privileges on newly created tables in finance schema');

SELECT * FROM finish();
ROLLBACK;
