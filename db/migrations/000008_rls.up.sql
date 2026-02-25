ALTER TABLE core.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE finance.accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE finance.transactions ENABLE ROW LEVEL SECURITY;

-- Tenant Isolation Policies; Only the authenticated user can access their own records --
-- DB Admin can still access all records --
CREATE POLICY tenant_isolation_policy ON app.users
USING (id = current_setting('app.current_tenant_id', true)::BIGINT;

CREATE POLICY tenant_isolation_policy ON app.accounts
USING (user_id = current_setting('app.current_tenant_id', true)::BIGINT;

CREATE POLICY tenant_isolation_policy ON app.transactions
USING (user_id = current_setting('app.current_tenant_id', true)::BIGINT;

