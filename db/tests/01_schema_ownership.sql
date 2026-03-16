BEGIN;
SELECT plan(40);

-- Verify Schema Ownership
SELECT schema_owner_is('audit', 'app_owner', 'audit schema should be owned by app_owner');
SELECT schema_owner_is('core', 'app_owner', 'core schema should be owned by app_owner');
SELECT schema_owner_is('auth', 'app_owner', 'auth schema should be owned by app_owner');
SELECT schema_owner_is('plaid', 'app_owner', 'plaid schema should be owned by app_owner');
SELECT schema_owner_is('finance', 'app_owner', 'finance schema should be owned by app_owner');
SELECT schema_owner_is('budget', 'app_owner', 'budget schema should be owned by app_owner');
SELECT schema_owner_is('timekeeping', 'app_owner', 'timekeeping schema should be owned by app_owner');

-- Verify function ownership
SELECT function_owner_is('core', 'current_tenant', '{}', 'app_owner', 'core.current_tenant() should be owned by app_owner');
SELECT function_owner_is('audit', 'log_row_change', '{}', 'app_owner', 'audit.log_row_change() should be owned by app_owner');

-- Verify critical table ownership (audit)
SELECT table_owner_is('audit', 'audit_event', 'app_owner', 'audit.audit_event should be owned by app_owner');
SELECT table_owner_is('audit', 'audit_row_change', 'app_owner', 'audit.audit_row_change should be owned by app_owner');

-- Verify critical table ownership (core)
SELECT table_owner_is('core', 'user_data', 'app_owner', 'core.user_data should be owned by app_owner');
SELECT table_owner_is('core', 'archived_user', 'app_owner', 'core.archived_user should be owned by app_owner');

-- Verify critical table ownership (auth)
SELECT table_owner_is('auth', 'hash_algo', 'app_owner', 'auth.hash_algo should be owned by app_owner');
SELECT table_owner_is('auth', 'user_session', 'app_owner', 'auth.user_session should be owned by app_owner');
SELECT table_owner_is('auth', 'email_verification', 'app_owner', 'auth.email_verification should be owned by app_owner');
SELECT table_owner_is('auth', 'password_credential', 'app_owner', 'auth.password_credential should be owned by app_owner');
SELECT table_owner_is('auth', 'password_reset', 'app_owner', 'auth.password_reset should be owned by app_owner');

-- Verify critical table ownership (plaid)
SELECT table_owner_is('plaid', 'plaid_institution', 'app_owner', 'plaid.plaid_institution should be owned by app_owner');
SELECT table_owner_is('plaid', 'link_event', 'app_owner', 'plaid.link_event should be owned by app_owner');
SELECT table_owner_is('plaid', 'plaid_item', 'app_owner', 'plaid.plaid_item should be owned by app_owner');
SELECT table_owner_is('plaid', 'plaid_item_status_history', 'app_owner', 'plaid.plaid_item_status_history should be owned by app_owner');
SELECT table_owner_is('plaid', 'plaid_sync_job', 'app_owner', 'plaid.plaid_sync_job should be owned by app_owner');
SELECT table_owner_is('plaid', 'plaid_webhook_event', 'app_owner', 'plaid.plaid_webhook_event should be owned by app_owner');
SELECT table_owner_is('plaid', 'plaid_account', 'app_owner', 'plaid.plaid_account should be owned by app_owner');

-- Verify critical table ownership (finance)
SELECT table_owner_is('finance', 'account_type', 'app_owner', 'finance.account_type should be owned by app_owner');
SELECT table_owner_is('finance', 'account_subtype', 'app_owner', 'finance.account_subtype should be owned by app_owner');
SELECT table_owner_is('finance', 'account', 'app_owner', 'finance.account should be owned by app_owner');
SELECT table_owner_is('finance', 'income_category', 'app_owner', 'finance.income_category should be owned by app_owner');
SELECT table_owner_is('finance', 'transaction', 'app_owner', 'finance.transaction should be owned by app_owner');
SELECT table_owner_is('finance', 'income_stream', 'app_owner', 'finance.income_stream should be owned by app_owner');
SELECT table_owner_is('finance', 'transaction_income_override', 'app_owner', 'finance.transaction_income_override should be owned by app_owner');

-- Verify critical table ownership (budget)
SELECT table_owner_is('budget', 'user_category', 'app_owner', 'budget.user_category should be owned by app_owner');
SELECT table_owner_is('budget', 'category_mapping', 'app_owner', 'budget.category_mapping should be owned by app_owner');
SELECT table_owner_is('budget', 'transaction_category_override', 'app_owner', 'budget.transaction_category_override should be owned by app_owner');
SELECT table_owner_is('budget', 'budget_line', 'app_owner', 'budget.budget_line should be owned by app_owner');

-- Verify critical table ownership (timekeeping)
SELECT table_owner_is('timekeeping', 'shift', 'app_owner', 'timekeeping.shift should be owned by app_owner');
SELECT table_owner_is('timekeeping', 'shift_transaction', 'app_owner', 'timekeeping.shift_transaction should be owned by app_owner');

SELECT * FROM finish();
ROLLBACK;
