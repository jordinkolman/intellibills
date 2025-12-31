CREATE SCHEMA core;

GRANT USAGE ON SCHEMA core TO indibills_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA core TO indibills_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA app
GRANT ALL PRIVILEGES ON TABLES TO indibills_user;

CREATE TABLE IF NOT EXISTS app.users (
  id UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
  email text NOT NULL,
  password bytea NOT NULL,
  first_name text NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
)

CREATE OR REPLACE TRIGGER audit_user_changes
AFTER INSERT OR UPDATE OR DELETE ON app.users
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();

CREATE INDEX idx_users_created_at ON app.users (created_at);
CREATE INDEX idx_users_updated_at ON app.users (updated_at);

CREATE TABLE IF NOT EXISTS app.institutions (
  id UUID bigserial PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
)

CREATE INDEX idx_institution_name ON app.institutions(name);

CREATE TABLE IF NOT EXISTS app.accounts ( 
  id BIGSERIAL PRIMARY KEY, 
  user_id BIGINT NOT NULL, 
  institution_id BIGINT NOT NULL,
  account_name text NOT NULL, 
  account_type text NOT NULL, 
  account_subtype text NOT NULL, 
  current_balance NUMERIC NOT NULL, 
  available_balance NUMERIC, 
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (user_id) REFERENCES app.users (id),
  FOREIGN KEY (institution_id) REFERENCES app.institutions (id)
);

CREATE OR REPLACE TRIGGER audit_account_changes
AFTER INSERT OR UPDATE OR DELETE ON app.accounts
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();

CREATE INDEX idx_account_account_type ON app.accounts (account_type);
CREATE INDEX idx_account_account_subtype ON app.accounts (account_subtype);
CREATE INDEX idx_account_institution_id ON app.accounts (institution_id);
CREATE INDEX idx_account_created_at ON app.accounts (created_at);
CREATE INDEX idx_account_udpated_at ON app.accounts (updated_at);

CREATE TABLE IF NOT EXISTS app.transactions (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL,
  account_id BIGINT NOT NULL,
  amount NUMERIC NOT NULL,
  date DATE NOT NULL,
  name text NOT NULL,
  merchant_name text NOT NULL,
  pending BOOLEAN NOT NULL,
  category text,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (user_id) REFERENCES app.users (id),
  FOREIGN KEY (account_id) REFERENCES app.accounts (id)
);

CREATE OR REPLACE TRIGGER audit_transaction_changes
AFTER INSERT OR UPDATE OR DELETE ON app.transactions
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();

CREATE INDEX idx_transaction_user_id ON app.transactions(user_id);
CREATE INDEX idx_transaction_account_id ON app.transactions(account_id);
CREATE INDEX idx_transaction_date ON app.transactions(date);
CREATE INDEX idx_transaction_merchant_name ON app.transactions(merchant_name);
CREATE INDEX idx_transaction_category ON app.transactions(category);
CREATE INDEX idx_transaction_created_at ON app.transactions(created_at);
CREATE INDEX idx_transactions_updated_at ON app.transactions(updated_at);
