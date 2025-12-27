-- RLS rules for app.users -- 
ALTER TABLE app.users ENABLE ROW LEVEL SECURITY;

-- deny all by default
CREATE POLICY deny_all_policy
ON app.users;

CREATE POLICY tenant_isolation_policy ON users
USING (user_id = current_setting('app.current_tenant_id', true)::BIGINT
OR EXISTS (SELECT 1 FROM rls_admins WHERE db_user = current_user));


