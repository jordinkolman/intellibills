CREATE DATABASE intellibills
  OWNER app_owner
  ENCODING 'UTF8'
  LC_COLLATE 'en_US.utf8'
  LC_CTYPE 'en_US.utf8';

GRANT CONNECT ON DATABASE intellibills TO app_runtime;
GRANT CONNECT ON DATABASE intellibills TO app_admin;
GRANT CONNECT ON DATABASE intellibills TO app_worker;
GRANT CONNECT ON DATABASE intellibills TO auditor;

