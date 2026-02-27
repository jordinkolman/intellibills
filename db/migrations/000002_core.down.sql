SET ROLE app_owner;

DROP FUNCTION IF EXISTS core.archive_user(uuid);

DROP TABLE IF EXISTS core.archived_user;

DROP TABLE IF EXISTS core.user_data;

DROP SCHEMA IF EXISTS core CASCADE;
