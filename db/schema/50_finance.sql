CREATE SCHEMA finance;

GRANT USAGE ON SCHEMA finance TO app_owner;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA finance TO app_owner;

ALTER DEFAULT PRIVILEGES IN SCHEMA finance
GRANT ALL PRIVILEGES ON TABLES TO app_owner;

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
  FOREIGN KEY (user_id) REFERENCES core."user"(id) ON DELETE RESTRICT,
  FOREIGN KEY (institution_id) REFERENCES plaid.plaid_institution(id) ON DELETE RESTRICT,
  FOREIGN KEY (plaid_account_id) REFERENCES plaid.plaid_account(id) ON DELETE RESTRICT,
  FOREIGN KEY (account_subtype_id) REFERENCES finance.account_subtype(id) ON DELETE RESTRICT
);

CREATE OR REPLACE TRIGGER audit_account_changes
AFTER INSERT OR UPDATE OR DELETE ON finance.account
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();

CREATE TABLE IF NOT EXISTS finance.transaction (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  account_id UUID NOT NULL,
  plaid_transaction_id TEXT,
  amount NUMERIC(19,4) NOT NULL,
  date DATE NOT NULL,
  name TEXT NOT NULL,
  merchant_name TEXT,
  plaid_metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  pending BOOLEAN NOT NULL DEFAULT true,
  source TEXT NOT NULL,
  currency CHAR(3) NOT NULL,
  FOREIGN KEY (user_id) REFERENCES core."user"(id) ON DELETE RESTRICT,
  FOREIGN KEY (account_id) REFERENCES finance.account(id) ON DELETE RESTRICT,
  CHECK (source IN ('plaid', 'manual'))
);

CREATE UNIQUE INDEX ux_plaid_transation ON finance.transaction(plaid_transaction_id) WHERE source = 'plaid';
CREATE INDEX idx_transaction_user ON finance.transaction(user_id);
CREATE INDEX idx_transaction_account ON finance.transaction(account_id);
CREATE INDEX idx_transaction_date ON finance.transaction(date);

CREATE OR REPLACE TRIGGER audit_transactions 
AFTER INSERT OR UPDATE OR DELETE ON finance.transaction
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();
