BEGIN;
SELECT plan(3);

SELECT schema_owner_is('core', 'app_owner', 'Core schema should be owned by app_owner role');
SELECT has_table('finance', 'account', 'finance.account table should exist');
SELECT col_is_fk('budget', 'budget_line', 'user_id', 'budget_line.user_id should be a foreign key to user_data.id');

SELECT * FROM finish();
ROLLBACK;
