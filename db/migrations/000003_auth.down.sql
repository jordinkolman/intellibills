SET ROLE app_owner;

DROP TABLE IF EXISTS auth.password_reset;

DROP TABLE IF EXISTS auth.password_credential;

DROP FUNCTION IF EXISTS auth.deactivate_previous_email_verification() CASCADE;

DROP TABLE IF EXISTS auth.email_verification;

DROP TABLE IF EXISTS auth.user_session;

DROP TABLE IF EXISTS auth.hash_algo;

DROP SCHEMA IF EXISTS auth CASCADE;
