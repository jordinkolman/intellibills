-- schema, table, and trigger owner; cannot login
CREATE ROLE app_owner NOLOGIN;

-- Holder for BYPASSRLS privilege
CREATE ROLE rls_bypasser NOLOGIN BYPASSRLS;

-- LOGIN ROLES (IDENTITIES)

-- Standard API User
CREATE ROLE app_runtime LOGIN;

-- Background Workers (Plaid Sync, Mileage Tracking, etc.) 
-- Require multi-tenant writes asynchronously across multiple tables
-- So RLS must be bypassed
CREATE ROLE app_worker LOGIN IN ROLE rls_bypasser;

-- Human Database Admin User
CREATE ROLE app_admin LOGIN IN ROLE rls_bypasser, app_owner;

-- read-only access for human audit
CREATE ROLE auditor LOGIN;

