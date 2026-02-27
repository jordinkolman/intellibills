SET ROLE app_owner;

ALTER TABLE core.user_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.archived_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth.user_session ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth.email_verification ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth.password_credential ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth.password_reset ENABLE ROW LEVEL SECURITY;
ALTER TABLE plaid.link_event ENABLE ROW LEVEL SECURITY;
ALTER TABLE plaid.plaid_item ENABLE ROW LEVEL SECURITY;
ALTER TABLE plaid.plaid_account ENABLE ROW LEVEL SECURITY;
ALTER TABLE plaid.plaid_sync_job ENABLE ROW LEVEL SECURITY;
ALTER TABLE plaid.plaid_webhook_event ENABLE ROW LEVEL SECURITY;
ALTER TABLE plaid.plaid_item_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE finance.account ENABLE ROW LEVEL SECURITY;
ALTER TABLE finance.transaction ENABLE ROW LEVEL SECURITY;
ALTER TABLE finance.income_category ENABLE ROW LEVEL SECURITY;
ALTER TABLE finance.income_stream ENABLE ROW LEVEL SECURITY;
ALTER TABLE finance.transaction_income_override ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget.user_category ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget.category_mapping ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget.transaction_category_override ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget.budget_line ENABLE ROW LEVEL SECURITY;
ALTER TABLE timekeeping.shift ENABLE ROW LEVEL SECURITY;
ALTER TABLE timekeeping.shift_transaction ENABLE ROW LEVEL SECURITY;

-- Checker for current tenant context
CREATE OR REPLACE FUNCTION core.current_tenant()
RETURNS uuid
LANGUAGE sql STABLE
AS $$
   SELECT NULLIF(current_setting('app.context.current_tenant_id', true), '')::UUID;
$$;

-- Tenant Isolation Policies; Only the authenticated user can access their own records --
CREATE POLICY tenant_isolation_policy ON core.user_data
TO app_runtime
USING (id = core.current_tenant());

CREATE POLICY tenant_isolation_policy ON core.archived_user
TO app_runtime
USING (user_id = core.current_tenant());

CREATE POLICY tenant_isolation_policy ON auth.user_session
TO app_runtime
USING (user_id = core.current_tenant());

CREATE POLICY tenant_isolation_policy ON auth.email_verification
TO app_runtime
USING (user_id = core.current_tenant());

CREATE POLICY tenant_isolation_policy ON auth.password_credential
TO app_runtime
USING (user_id = core.current_tenant());

CREATE POLICY tenant_isolation_policy ON auth.password_reset
TO app_runtime
USING (
  password_credential_id IN (
    SELECT id FROM auth.password_credential WHERE user_id = core.current_tenant()
  )
);

CREATE POLICY tenant_isolation_policy ON plaid.link_event
TO app_runtime
USING (user_id = core.current_tenant());

CREATE POLICY tenant_isolation_policy ON plaid.plaid_item
TO app_runtime
USING (user_id = core.current_tenant());

CREATE POLICY tenant_isolation_policy ON plaid.plaid_account
TO app_runtime
USING (
  plaid_item_id IN (
    SELECT id FROM plaid.plaid_item WHERE user_id = core.current_tenant()
  )
)
WITH CHECK (
  plaid_item_id IN (
    SELECT id FROM plaid.plaid_item WHERE user_id = core.current_tenant()
  )
);

CREATE POLICY tenant_isolation_policy ON plaid.plaid_sync_job
TO app_runtime
USING (
  plaid_item_id IN (
    SELECT id FROM plaid.plaid_item WHERE user_id = core.current_tenant()
  )
)
WITH CHECK (
  plaid_item_id IN (
    SELECT id FROM plaid.plaid_item WHERE user_id = core.current_tenant()
  )
);

CREATE POLICY tenant_isolation_policy ON plaid.plaid_webhook_event
TO app_runtime
USING (
  plaid_item_id IN (
    SELECT id FROM plaid.plaid_item WHERE user_id = core.current_tenant()
  )
)
WITH CHECK (
  plaid_item_id IN (
    SELECT id FROM plaid.plaid_item WHERE user_id = core.current_tenant()
  )
);

CREATE POLICY tenant_isolation_policy ON plaid.plaid_item_status_history
TO app_runtime
USING (
  plaid_item_id IN (
    SELECT id FROM plaid.plaid_item WHERE user_id = core.current_tenant()
  )
)
WITH CHECK (
  plaid_item_id IN (
    SELECT id FROM plaid.plaid_item WHERE user_id = core.current_tenant()
  )
);

CREATE POLICY tenant_isolation_policy ON finance.account
TO app_runtime
USING (user_id = core.current_tenant());

CREATE POLICY tenant_isolation_policy ON finance.transaction
TO app_runtime
USING (user_id = core.current_tenant());

CREATE POLICY tenant_isolation_policy ON finance.income_category
TO app_runtime
USING (user_id = core.current_tenant());

CREATE POLICY tenant_isolation_policy ON finance.income_stream
TO app_runtime
USING (user_id = core.current_tenant());

CREATE POLICY tenant_isolation_policy ON finance.transaction_income_override
TO app_runtime
USING (
  transaction_id IN (
    SELECT id FROM finance.transaction WHERE user_id = core.current_tenant()
  )
)
WITH CHECK (
  transaction_id IN (
    SELECT id FROM finance.transaction WHERE user_id = core.current_tenant()
  )
);

CREATE POLICY tenant_isolation_policy ON budget.user_category
TO app_runtime
USING (user_id = core.current_tenant());

CREATE POLICY tenant_isolation_policy ON budget.category_mapping
TO app_runtime
USING (user_id = core.current_tenant());

CREATE POLICY tenant_isolation_policy ON budget.transaction_category_override
TO app_runtime
USING (
    user_category_id IN (
        SELECT id FROM budget.user_category WHERE user_id = core.current_tenant()
    )
)
WITH CHECK (
    user_category_id IN (
        SELECT id FROM budget.user_category WHERE user_id = core.current_tenant()
    )
);

CREATE POLICY tenant_isolation_policy ON budget.budget_line
TO app_runtime
USING (user_id = core.current_tenant());

CREATE POLICY tenant_isolation_policy ON timekeeping.shift
TO app_runtime
USING (user_id = core.current_tenant());

CREATE POLICY tenant_isolation_policy ON timekeeping.shift_transaction
TO app_runtime
USING (user_id = core.current_tenant());

