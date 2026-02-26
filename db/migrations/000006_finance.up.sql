CREATE SCHEMA finance;

GRANT USAGE ON SCHEMA finance TO app_owner;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA finance TO app_owner;

ALTER DEFAULT PRIVILEGES IN SCHEMA finance
GRANT ALL PRIVILEGES ON TABLES TO app_owner;

GRANT USAGE ON SCHEMA finance TO app_runtime;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA finance TO app_runtime;

GRANT USAGE ON SCHEMA finance TO app_worker;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA finance TO app_worker;

ALTER DEFAULT PRIVILEGES IN SCHEMA finance
GRANT ALL PRIVILEGES ON TABLES TO app_runtime;

ALTER DEFAULT PRIVILEGES IN SCHEMA finance
GRANT ALL PRIVILEGES ON TABLES TO app_worker;

CREATE TABLE IF NOT EXISTS finance.account_type (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS finance.account_subtype (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type_id UUID NOT NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY(type_id) REFERENCES finance.account_type(id) ON DELETE CASCADE
);

CREATE INDEX idx_subtype_type ON finance.account_subtype(type_id);
CREATE UNIQUE INDEX ux_subtype_type_name ON finance.account_subtype (type_id, name);

CREATE TABLE IF NOT EXISTS finance.account (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  institution_id UUID NOT NULL,
  plaid_account_id UUID,
  plaid_account_external_id TEXT UNIQUE, -- plaid's id for the account
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  available_balance NUMERIC(19,4) NOT NULL,
  current_balance NUMERIC(19,4) NOT NULL,
  currency CHAR(3) NOT NULL,
  account_name TEXT NOT NULL,
  account_subtype_id UUID NOT NULL,
  archived BOOLEAN NOT NULL DEFAULT false,
  FOREIGN KEY (user_id) REFERENCES core.user_data(id) ON DELETE RESTRICT,
  FOREIGN KEY (institution_id) REFERENCES plaid.plaid_institution(id) ON DELETE RESTRICT,
  FOREIGN KEY (plaid_account_id) REFERENCES plaid.plaid_account(id) ON DELETE RESTRICT,
  FOREIGN KEY (account_subtype_id) REFERENCES finance.account_subtype(id) ON DELETE RESTRICT
);

CREATE OR REPLACE TRIGGER audit_account_changes
AFTER INSERT OR UPDATE OR DELETE ON finance.account
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();

CREATE TABLE finance.income_category (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (user_id) REFERENCES core.user_data(id) ON DELETE RESTRICT,
  UNIQUE (user_id, name)
);

CREATE INDEX idx_income_category_name ON finance.income_category(name);
CREATE INDEX idx_income_category_user ON finance.income_category(user_id);

CREATE TABLE IF NOT EXISTS finance.transaction (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  account_id UUID NOT NULL,
  plaid_transaction_id TEXT,
  income_category_id UUID,
  amount NUMERIC(19,4) NOT NULL,
  date DATE NOT NULL,
  name TEXT NOT NULL,
  merchant_name TEXT,
  plaid_metadata JSONB,
  direction TEXT NOT NULL DEFAULT 'outflow',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  pending BOOLEAN NOT NULL DEFAULT true,
  source TEXT NOT NULL,
  currency CHAR(3) NOT NULL,
  FOREIGN KEY (user_id) REFERENCES core.user_data(id) ON DELETE RESTRICT,
  FOREIGN KEY (account_id) REFERENCES finance.account(id) ON DELETE RESTRICT,
  FOREIGN KEY (income_category_id) REFERENCES finance.income_category(id) ON DELETE RESTRICT,
  CHECK (source IN ('plaid', 'manual')),
  CHECK (direction IN ('inflow', 'outflow'))
);

CREATE UNIQUE INDEX ux_plaid_transation ON finance.transaction(plaid_transaction_id) WHERE source = 'plaid';
CREATE INDEX idx_transaction_user ON finance.transaction(user_id);
CREATE INDEX idx_transaction_account ON finance.transaction(account_id);
CREATE INDEX idx_transaction_date ON finance.transaction(date);

CREATE OR REPLACE TRIGGER audit_transactions 
AFTER INSERT OR UPDATE OR DELETE ON finance.transaction
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();

CREATE TABLE IF NOT EXISTS finance.income_stream (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  income_category_id UUID NOT NULL,
  name TEXT NOT NULL,
  cadence TEXT NOT NULL,
  expected_amount NUMERIC(19,4) NOT NULL,
  currency CHAR(3) NOT NULL,
  next_expected_date DATE NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (user_id) REFERENCES core.user_data(id) ON DELETE RESTRICT,
  FOREIGN KEY (income_category_id) REFERENCES finance.income_category(id) ON DELETE RESTRICT,
  CHECK (cadence IN ('weekly', 'biweekly', 'monthly', 'quarterly', 'annual'))
);

CREATE INDEX idx_income_stream_user ON finance.income_stream(user_id);
CREATE INDEX idx_income_stream_category ON finance.income_stream(income_category_id);
CREATE INDEX idx_income_stream_cadence ON finance.income_stream(cadence);

CREATE OR REPLACE TRIGGER audit_income_streams
AFTER INSERT OR UPDATE OR DELETE ON finance.income_stream
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();

CREATE TABLE IF NOT EXISTS finance.transaction_income_override (
  transaction_id UUID PRIMARY KEY,
  income_category_id UUID NOT NULL,
  overridden_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (transaction_id) REFERENCES finance.transaction(id) ON DELETE CASCADE,
  FOREIGN KEY (income_category_id) REFERENCES finance.income_category(id) ON DELETE RESTRICT
);

CREATE OR REPLACE TRIGGER audit_transaction_income_overrrides
AFTER INSERT OR UPDATE OR DELETE ON finance.transaction_income_override
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();

