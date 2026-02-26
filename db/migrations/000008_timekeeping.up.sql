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
    user_id UUID NOT NULL, -- Assuming your standard user reference
    income_stream_id UUID NOT NULL REFERENCES finance.income_stream(id) ON DELETE RESTRICT,
    planned_start_time TIMESTAMPTZ NOT NULL,
    planned_end_time TIMESTAMPTZ NOT NULL,
    actual_start_time TIMESTAMPTZ,
    actual_end_time TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'active', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS timekeeping.shift_transaction (
    shift_id UUID NOT NULL REFERENCES timekeeping.shift(id) ON DELETE RESTRICT,
    transaction_id UUID NOT NULL REFERENCES finance.transaction(id) ON DELETE RESTRICT,
    user_id UUID NOT NULL,        -- Denormalized for standard RLS checks
    amount DECIMAL(12, 2) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('income', 'expense')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (shift_id, transaction_id)
);

