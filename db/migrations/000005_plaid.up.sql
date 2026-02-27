CREATE SCHEMA IF NOT EXISTS plaid AUTHORIZATION app_owner;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA plaid TO app_owner;

ALTER DEFAULT PRIVILEGES IN SCHEMA plaid
GRANT ALL PRIVILEGES ON TABLES TO app_owner;

GRANT USAGE ON SCHEMA plaid TO app_runtime;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA plaid TO app_runtime;

REVOKE INSERT, UPDATE, DELETE ON plaid.plaid_institution FROM app_runtime;

GRANT USAGE ON SCHEMA plaid TO app_worker;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA plaid TO app_worker;

ALTER DEFAULT PRIVILEGES IN SCHEMA plaid
GRANT ALL PRIVILEGES ON TABLES TO app_runtime;

ALTER DEFAULT PRIVILEGES IN SCHEMA plaid
GRANT ALL PRIVILEGES ON TABLES TO app_worker;

CREATE TABLE IF NOT EXISTS plaid.plaid_institution (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plaid_institution_id TEXT NOT NULL UNIQUE, -- Plaid's institution id
  name TEXT NOT NULL, 
  country_codes TEXT[],
  products TEXT[],
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS plaid.link_event(
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL, 
  institution_id UUID NOT NULL,
  status TEXT NOT NULL,
  error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (user_id) REFERENCES core.user_data(id) ON DELETE RESTRICT,
  FOREIGN KEY (institution_id) REFERENCES plaid.plaid_institution(id) ON DELETE RESTRICT,
  CHECK (status IN ('success', 'errored', 'abandoned'))
);

CREATE TABLE IF NOT EXISTS plaid.plaid_item (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  plaid_id TEXT NOT NULL UNIQUE, -- Plaid's item id
  access_token BYTEA NOT NULL,
  institution_id UUID NOT NULL,
  status VARCHAR NOT NULL,
  products TEXT[],
  last_webhook_received_at TIMESTAMPTZ,
  last_successful_sync_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (institution_id) REFERENCES plaid.plaid_institution(id) ON DELETE RESTRICT,
  FOREIGN KEY (user_id) REFERENCES core.user_data(id) ON DELETE RESTRICT,
  CHECK (status IN ('active', 'errored', 'relink_required', 'inactive'))
);

CREATE INDEX idx_plaid_item_user ON plaid.plaid_item(user_id);

CREATE UNIQUE INDEX ux_user_institution_item
ON plaid.plaid_item (user_id, institution_id)
WHERE status = 'active';

CREATE OR REPLACE TRIGGER audit_plaid_items
AFTER INSERT OR UPDATE OR DELETE ON plaid.plaid_item
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();

CREATE TABLE IF NOT EXISTS plaid.plaid_item_status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plaid_item_id UUID NOT NULL,
  old_status TEXT NOT NULL,
  new_status TEXT NOT NULL,
  reason TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (plaid_item_id) REFERENCES plaid.plaid_item(id) ON DELETE RESTRICT,
  CHECK (old_status <> new_status)
);

CREATE TABLE IF NOT EXISTS plaid.plaid_sync_job (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plaid_item_id UUID NOT NULL,
  job_type TEXT NOT NULL,
  status TEXT NOT NULL,
  error TEXT,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  FOREIGN KEY (plaid_item_id) REFERENCES plaid.plaid_item(id) ON DELETE RESTRICT,
  CHECK (job_type IN ('transactions', 'accounts', 'investments')),
  CHECK (status IN ('queued', 'running', 'completed', 'failed')),
  CHECK (completed_at IS NULL OR completed_at >= started_at)
);

CREATE INDEX idx_plaid_sync_job_item_status ON plaid.plaid_sync_job (plaid_item_id, status);

CREATE OR REPLACE TRIGGER audit_plaid_sync_jobs
AFTER INSERT OR UPDATE OR DELETE ON plaid.plaid_sync_job
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();

CREATE TABLE IF NOT EXISTS plaid.plaid_webhook_event (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plaid_item_id UUID NOT NULL,
  delivery_id TEXT UNIQUE, -- Plaid's event id
  webhook_type TEXT NOT NULL,
  webhook_code TEXT NOT NULL,
  payload JSONB NOT NULL,
  received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed BOOLEAN NOT NULL DEFAULT false,
  FOREIGN KEY (plaid_item_id) REFERENCES plaid.plaid_item(id) ON DELETE RESTRICT
);

CREATE OR REPLACE TRIGGER audit_plaid_webhook_events
AFTER INSERT OR UPDATE OR DELETE ON plaid.plaid_webhook_event
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();

CREATE TABLE IF NOT EXISTS plaid.plaid_account(
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plaid_item_id UUID NOT NULL,
  plaid_account_id TEXT NOT NULL, -- Plaid's account id
  name TEXT NOT NULL,
  official_name TEXT,
  type TEXT,
  subtype TEXT,
  mask TEXT,
  currency CHAR(3),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (plaid_item_id) REFERENCES plaid.plaid_item(id) ON DELETE RESTRICT
);

CREATE INDEX idx_plaid_account_item ON plaid.plaid_account (plaid_item_id);
CREATE UNIQUE INDEX ux_item_plaid_account ON plaid.plaid_account (plaid_item_id, plaid_account_id);

CREATE OR REPLACE TRIGGER audit_plaid_accounts
AFTER INSERT OR UPDATE OR DELETE ON plaid.plaid_account
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();

