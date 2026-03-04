BEGIN;
SELECT plan(5);

-- Ensure we have a hash algo for the session test
INSERT INTO auth.hash_algo (name) VALUES ('argon2id') ON CONFLICT DO NOTHING;

-- Setup Test Data using CTEs for relational integrity
WITH test_users AS (
    INSERT INTO core.user_data (id, email)
    VALUES 
        (gen_random_uuid(), 'user_a@example.com'),
        (gen_random_uuid(), 'user_b@example.com')
    RETURNING id, email
),
user_a AS (SELECT id FROM test_users WHERE email = 'user_a@example.com'),
user_b AS (SELECT id FROM test_users WHERE email = 'user_b@example.com'),
mock_inst AS (
    INSERT INTO plaid.plaid_institution (plaid_institution_id, name)
    VALUES ('ins_123', 'Mock Institution')
    RETURNING id
),
user_a_item AS (
    INSERT INTO plaid.plaid_item (user_id, plaid_id, access_token, institution_id, status)
    SELECT user_a.id, 'item_a', 'token_a', mock_inst.id, 'active' 
    FROM user_a, mock_inst
    RETURNING id
)
INSERT INTO plaid.plaid_account (plaid_item_id, plaid_account_id, name, mask, official_name, type, subtype, currency)
SELECT id, 'acc_a', 'Account A', '1234', 'Official A', 'depository', 'checking', 'USD' FROM user_a_item;

-- Capture User A ID before switching role to app_runtime (which would be restricted by RLS)
SELECT set_config('app.context.current_tenant_id', (SELECT id::text FROM core.user_data WHERE email = 'user_a@example.com'), true);
SELECT set_config('app.test.user_b_id', (SELECT id::text FROM core.user_data WHERE email = 'user_b@example.com'), true);

-- Test User A isolation
SET ROLE app_runtime;

SELECT is(
    (SELECT COUNT(*)::integer FROM core.user_data),
    1,
    'User A should only see their own record in core.user_data'
);

SELECT is(
    (SELECT email FROM core.user_data LIMIT 1),
    'user_a@example.com',
    'The visible record should be user_a'
);

-- Test hierarchical RLS: User A should see their plaid account
SELECT is(
    (SELECT COUNT(*)::integer FROM plaid.plaid_account),
    1,
    'User A should see their own plaid account'
);

-- Test negative case: User A should NOT see User B's record even if they try to query it directly
SELECT is(
    (SELECT COUNT(*)::integer FROM core.user_data WHERE email = 'user_b@example.com'),
    0,
    'User A should not see User B''s record'
);

-- Test Insert Restriction: User A cannot insert data for User B
-- We reset role to get user_b_id safely for the test setup, or use subquery
SELECT throws_ok(
    'INSERT INTO auth.user_session (user_id, ...) VALUES (current_setting(''app.test.user_b_id'', true)::uuid, ...)',
    '42501', 
    NULL,
    'User A should not be able to insert a session for User B'
);

SELECT * FROM finish();
ROLLBACK;
