-- schema, table, and trigger owner; cannot login
CREATE ROLE indibills_owner NOLOGIN;

-- application user; app makes connections through this user
CREATE ROLE indibills_user LOGIN;
-- password set out of band

-- read-only access for human audit
CREATE ROLE auditor LOGIN;



