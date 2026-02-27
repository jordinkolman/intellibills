SET ROLE app_owner;

DROP FUNCTION IF EXISTS budget.enforce_budget_category_user_match() CASCADE;

DROP TABLE IF EXISTS budget.budget_line;

DROP TABLE IF EXISTS budget.transaction_category_override;

DROP TABLE IF EXISTS budget.category_mapping;

DROP TABLE IF EXISTS budget.user_category;

DROP SCHEMA IF EXISTS budget CASCADE;
