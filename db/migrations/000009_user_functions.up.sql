SET ROLE app_owner;

-- Schema Functions --
CREATE OR REPLACE FUNCTION core.archive_user(p_user_id uuid)
RETURNS void
SET search_path = core, public
AS $$
BEGIN
UPDATE core.user_data
SET archived=true
WHERE id = p_user_id;
INSERT INTO core.archived_user (user_id, expires_at)
VALUES (p_user_id, now() + interval '30 days')
ON CONFLICT (user_id)
DO UPDATE SET expires_at = EXCLUDED.expires_at;
END; $$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION core.restore_user(p_user_id uuid)
RETURNS void
SET search_path = core, public
AS $$
BEGIN
    UPDATE core.user_data
    SET archived=false
    WHERE id = p_user_id;

    DELETE FROM core.archived_user
    WHERE user_id = p_user_id;
END; $$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION core.purge_user(p_user_id uuid)
RETURNS void
SET search_path = core, public
AS $$
BEGIN
    -- 1. Purge Budget Data
    DELETE FROM budget.budget_line WHERE user_id = p_user_id;
    DELETE FROM budget.transaction_category_override
        WHERE user_category_id IN (SELECT id FROM budget.user_category WHERE user_id = p_user_id);
    DELETE FROM budget.category_mapping WHERE user_id = p_user_id;
    DELETE FROM budget.user_category WHERE user_id = p_user_id;

    -- 2. Purge Timekeeping Data
    DELETE FROM timekeeping.shift_transaction WHERE user_id = p_user_id;
    DELETE FROM timekeeping.shift WHERE user_id = p_user_id;


    -- 3. Purge Finance Data
    DELETE FROM finance.transaction_income_override
        WHERE transaction_id IN (SELECT id FROM finance.transaction WHERE account_id IN (SELECT id FROM finance.account WHERE user_id = p_user_id));
    DELETE FROM finance.transaction
        WHERE account_id IN (SELECT id FROM finance.account WHERE user_id = p_user_id);
    DELETE FROM finance.income_stream WHERE user_id = p_user_id;
    DELETE FROM finance.income_category WHERE user_id = p_user_id;
    DELETE FROM finance.account WHERE user_id = p_user_id;

  -- 4. Purge Plaid Data
  -- Clear item dependencies before deleting the items
    DELETE FROM plaid.plaid_webhook_event
        WHERE plaid_item_id IN (SELECT id FROM plaid.plaid_item WHERE user_id = p_user_id);
    DELETE FROM plaid.plaid_account
        WHERE plaid_item_id IN (SELECT id FROM plaid.plaid_item WHERE user_id = p_user_id);
    DELETE FROM plaid.plaid_sync_job
        WHERE plaid_item_id IN (SELECT id FROM plaid.plaid_item WHERE user_id = p_user_id);
    DELETE FROM plaid.plaid_item_status_history
        WHERE plaid_item_id IN (SELECT id FROM plaid.plaid_item WHERE user_id = p_user_id);
    DELETE FROM plaid.plaid_item WHERE user_id = p_user_id;
    DELETE FROM plaid.link_event WHERE user_id = p_user_id;

    -- 5. Purge Auth Data
  -- Clear password resets before the credential itself
    DELETE FROM auth.password_reset
        WHERE password_credential_id IN (SELECT id FROM auth.password_credential WHERE user_id = p_user_id);
    DELETE FROM auth.password_credential WHERE user_id = p_user_id;
    DELETE FROM auth.email_verification WHERE user_id = p_user_id;
    DELETE FROM auth.user_session WHERE user_id = p_user_id;

    -- 6. Purge Core Data
    DELETE FROM core.archived_user WHERE user_id = p_user_id;
    DELETE FROM core.user_data WHERE id = p_user_id;
END; $$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION core.purge_stale_users()
RETURNS integer
SET search_path = core, public
AS $$
DECLARE
    v_user_record RECORD;
    v_purge_count integer := 0;
BEGIN
    FOR v_user_record IN
        SELECT user_id
        FROM core.archived_user
        WHERE expires_at <= NOW()
    LOOP
        PERFORM core.purge_user(v_user_record.user_id);
        v_purge_count := v_purge_count + 1;
    END LOOP;

    RETURN v_purge_count;
END; $$
LANGUAGE PLPGSQL;