SET ROLE app_owner;

DROP FUNCTION IF EXISTS core.purge_stale_users();

DROP FUNCTION IF EXISTS core.purge_user(uuid);

DROP FUNCTION IF EXISTS core.restore_user(uuid);

DROP FUNCTION IF EXISTS core.archive_user(uuid);