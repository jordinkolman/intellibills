CREATE DATABASE indibills
  OWNER app_owner
  ENCODING 'UTF8'
  LC_COLLATE 'en_US.utf8'
  LC_CTYPE 'en_US.utf8'
  TEMPLATE template0;

GRANT CONNECT ON DATABASE indibills TO app_runtime;
GRANT CONNECT ON DATABASE indibills TO app_admin;
GRANT CONNECT ON DATABASE indibills TO migrator;
GRANT CONNECT ON DATABASE indibills TO auditor;
