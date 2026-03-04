BEGIN;
SELECT plan(8);

-- Verify Schema Ownership
SELECT schema_owner_is('audit', 'app_owner', 'audit schema should be owned by app_owner');
SELECT schema_owner_is('core', 'app_owner', 'core schema should be owned by app_owner');
SELECT schema_owner_is('auth', 'app_owner', 'auth schema should be owned by app_owner');
SELECT schema_owner_is('plaid', 'app_owner', 'plaid schema should be owned by app_owner');
SELECT schema_owner_is('finance', 'app_owner', 'finance schema should be owned by app_owner');
SELECT schema_owner_is('budget', 'app_owner', 'budget schema should be owned by app_owner');
SELECT schema_owner_is('timekeeping', 'app_owner', 'timekeeping schema should be owned by app_owner');

-- Verify critical table ownership
SELECT table_owner_is('core', 'user_data', 'app_owner', 'core.user_data should be owned by app_owner');

SELECT * FROM finish();
ROLLBACK;
