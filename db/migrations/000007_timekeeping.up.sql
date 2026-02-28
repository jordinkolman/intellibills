SET ROLE app_owner;

CREATE SCHEMA IF NOT EXISTS timekeeping AUTHORIZATION app_owner;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA timekeeping TO app_owner;

ALTER DEFAULT PRIVILEGES IN SCHEMA timekeeping
GRANT ALL PRIVILEGES ON TABLES TO app_owner;

GRANT USAGE ON SCHEMA timekeeping TO app_runtime;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA timekeeping TO app_runtime;

GRANT USAGE ON SCHEMA timekeeping TO app_worker;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA timekeeping TO app_worker;

ALTER DEFAULT PRIVILEGES IN SCHEMA timekeeping
GRANT ALL PRIVILEGES ON TABLES TO app_runtime;

ALTER DEFAULT PRIVILEGES IN SCHEMA timekeeping
GRANT ALL PRIVILEGES ON TABLES TO app_worker;

CREATE TABLE IF NOT EXISTS timekeeping.shift (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES core.user_data(id) ON DELETE RESTRICT,
    income_stream_id UUID NOT NULL REFERENCES finance.income_stream(id) ON DELETE RESTRICT,
    planned_start_time TIMESTAMPTZ NOT NULL,
    planned_end_time TIMESTAMPTZ NOT NULL,
    actual_start_time TIMESTAMPTZ,
    actual_end_time TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'active', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CHECK (planned_end_time > planned_start_time),
    CHECK (
      actual_start_time IS NULL
      OR actual_end_time IS NULL
      OR actual_end_time >= actual_start_time
    )
);

CREATE OR REPLACE TRIGGER audit_shifts
AFTER INSERT OR UPDATE OR DELETE ON timekeeping.shift
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();

CREATE TABLE IF NOT EXISTS timekeeping.shift_transaction (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_id UUID NOT NULL REFERENCES timekeeping.shift(id) ON DELETE RESTRICT,
    transaction_id UUID NOT NULL REFERENCES finance.transaction(id) ON DELETE RESTRICT,
    user_id UUID NOT NULL REFERENCES core.user_data(id) ON DELETE RESTRICT,
    amount DECIMAL(12, 2) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('income', 'expense')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (shift_id, transaction_id)
);

CREATE OR REPLACE TRIGGER audit_shift_transactions
AFTER INSERT OR UPDATE OR DELETE ON timekeeping.shift_transaction
FOR EACH ROW
EXECUTE FUNCTION audit.log_row_change();

CREATE OR REPLACE FUNCTION timekeeping.enforce_shift_transaction_user_match()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_shift_user UUID;
  v_transaction_user UUID;
BEGIN
  SELECT user_id INTO v_shift_user
  FROM timekeeping.shift
  WHERE id = NEW.shift_id;

  IF v_shift_user IS NULL THEN
    RAISE EXCEPTION 'Shift % does not exist', NEW.shift_id USING ERRCODE = '23503';
  END IF;

  SELECT user_id INTO v_transaction_user
  FROM finance.transaction
  WHERE id = NEW.transaction_id;

  IF v_transaction_user IS NULL THEN
    RAISE EXCEPTION 'Transaction % does not exist', NEW.transaction_id USING ERRCODE = '23503';
  END IF;

  IF NEW.user_id <> v_shift_user OR NEW.user_id <> v_transaction_user THEN
    RAISE EXCEPTION 'shift_transaction user mismatch' USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_shift_transaction_user_match
BEFORE INSERT OR UPDATE ON timekeeping.shift_transaction
FOR EACH ROW
EXECUTE FUNCTION timekeeping.enforce_shift_transaction_user_match();

RESET ROLE;