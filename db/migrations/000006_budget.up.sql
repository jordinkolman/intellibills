SET ROLE app_owner;

CREATE SCHEMA IF NOT EXISTS budget AUTHORIZATION app_owner;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA budget TO app_owner;

ALTER DEFAULT PRIVILEGES IN SCHEMA budget
GRANT ALL PRIVILEGES ON TABLES TO app_owner;

GRANT USAGE ON SCHEMA budget TO app_runtime;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA budget TO app_runtime;

GRANT USAGE ON SCHEMA budget TO app_worker;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA budget TO app_worker;

ALTER DEFAULT PRIVILEGES IN SCHEMA budget
GRANT ALL PRIVILEGES ON TABLES TO app_runtime;

ALTER DEFAULT PRIVILEGES IN SCHEMA budget
GRANT ALL PRIVILEGES ON TABLES TO app_worker;

CREATE TABLE IF NOT EXISTS budget.user_category (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  name TEXT NOT NULL, 
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (user_id) REFERENCES core.user_data(id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX ux_user_category_name ON budget.user_category(user_id, name) WHERE is_active = true;
CREATE INDEX idx_user_category_user_id ON budget.user_category(user_id);

CREATE TABLE IF NOT EXISTS budget.category_mapping (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  user_category_id UUID NOT NULL,
  plaid_category TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (user_id) REFERENCES core.user_data(id) ON DELETE RESTRICT,
  FOREIGN KEY (user_category_id) REFERENCES budget.user_category(id) ON DELETE RESTRICT
);

CREATE INDEX idx_category_mapping_user_id ON budget.category_mapping(user_id);
CREATE INDEX idx_category_mapping_plaid_category ON budget.category_mapping(plaid_category);
CREATE UNIQUE INDEX ux_category_mapping_user_plaid_category ON budget.category_mapping(user_id, plaid_category);

CREATE TABLE IF NOT EXISTS budget.transaction_category_override (
  transaction_id UUID PRIMARY KEY,
  user_category_id UUID NOT NULL,
  overridden_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (transaction_id) REFERENCES finance.transaction(id) ON DELETE CASCADE,
  FOREIGN KEY (user_category_id) REFERENCES budget.user_category(id) ON DELETE RESTRICT
);

CREATE INDEX idx_override_category_id ON budget.transaction_category_override(user_category_id);

CREATE TABLE IF NOT EXISTS budget.budget_line (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  category_id UUID NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  period_type TEXT NOT NULL,
  limit_amount NUMERIC(19,4) NOT NULL,
  rollover BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (user_id) REFERENCES core.user_data(id) ON DELETE RESTRICT,
  FOREIGN KEY (category_id) REFERENCES budget.user_category(id) ON DELETE RESTRICT,
  CHECK (period_end > period_start),
  CHECK (period_type IN ('weekly', 'biweekly', 'monthly', 'monthly_user_defined')),
  EXCLUDE USING gist (
    user_id WITH =,
    category_id WITH =,
    daterange(period_start, period_end, '[]') WITH &&
  )
);

CREATE INDEX idx_budget_user_id ON budget.budget_line(user_id);
CREATE INDEX idx_budget_period_type ON budget.budget_line(period_type);
CREATE INDEX idx_budget_categories ON budget.budget_line(category_id);
CREATE INDEX idx_budget_period_start ON budget.budget_line(period_start);
CREATE INDEX idx_budget_period_end ON budget.budget_line(period_end);
CREATE UNIQUE INDEX ux_budget_category_period ON budget.budget_line(user_id, category_id, period_start, period_end);

CREATE OR REPLACE FUNCTION budget.enforce_budget_category_user_match()
RETURNS TRIGGER
SET search_path = budget, public
AS $$
DECLARE v_category_user_id UUID;
BEGIN
SELECT uc.user_id INTO v_category_user_id FROM budget.user_category uc
WHERE uc.id = NEW.category_id;

IF v_category_user_id IS NULL THEN
RAISE EXCEPTION 
'Category % does not exist', NEW.category_id;
END IF;

IF v_category_user_id <> NEW.user_id THEN
RAISE EXCEPTION 
'User % cannot use category % owned by user %', NEW.user_id, NEW.category_id,v_category_user_id
USING ERRCODE = '23514';
END IF;

RETURN NEW;
END; $$
LANGUAGE PLPGSQL;

CREATE TRIGGER trg_budget_line_user_category_consistency
BEFORE INSERT OR UPDATE on budget.budget_line
FOR EACH ROW
EXECUTE FUNCTION budget.enforce_budget_category_user_match();
