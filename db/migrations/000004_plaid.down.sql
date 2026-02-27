SET ROLE app_owner;

DROP TABLE IF EXISTS plaid.plaid_account;

DROP TABLE IF EXISTS plaid.plaid_webhook_event;

DROP TABLE IF EXISTS plaid.plaid_sync_job;

DROP TABLE IF EXISTS plaid.plaid_item_status_history;

DROP TABLE IF EXISTS plaid.plaid_item;

DROP TABLE IF EXISTS plaid.link_event;

DROP TABLE IF EXISTS plaid.plaid_institution;

DROP SCHEMA IF EXISTS plaid CASCADE;
