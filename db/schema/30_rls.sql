ALTER TABLE app.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.transactions ENABLE ROW LEVEL SECURITY;

-- Tenant Isolation Policies; Only the authenticated user can access their own records --
-- DB Admin can still access all records --
CREATE POLICY tenant_isolation_policy ON app.users
USING (id = current_setting('app.current_tenant_id', true)::BIGINT -- current_tenant_id set by app auth flow
OR pg_has_role(current_user, 'rls_admin', 'member');

CREATE POLICY tenant_isolation_policy ON app.accounts
USING (user_id = current_setting('app.current_tenant_id', true)::BIGINT
OR pg_has_role(current_user, 'rls_admin', 'member');

CREATE POLICY tenant_isolation_policy ON app.transactions
USING (user_id = current_setting('app.current_tenant_id', true)::BIGINT
OR pg_has_role(current_user, 'rls_admin', 'member');

