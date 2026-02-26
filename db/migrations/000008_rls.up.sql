ALTER TABLE core.user_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE finance.account ENABLE ROW LEVEL SECURITY;
ALTER TABLE finance.transaction ENABLE ROW LEVEL SECURITY;

-- Tenant Isolation Policies; Only the authenticated user can access their own records --
-- DB Admin can still access all records --
CREATE POLICY tenant_isolation_policy ON core.user_data
USING (id = current_setting('app.context.current_tenant_id', true)::UUID);

CREATE POLICY tenant_isolation_policy ON finance.account
USING (user_id = current_setting('app.context.current_tenant_id', true)::UUID);

CREATE POLICY tenant_isolation_policy ON finance.transaction
USING (user_id = current_setting('app.context.current_tenant_id', true)::UUID);

