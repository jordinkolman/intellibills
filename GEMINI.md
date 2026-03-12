# Intellibills: Project Specification & Architecture Context

This document serves as the technical source of truth for the Intellibills project. It outlines the database architecture, security paradigms, application contracts, and testing infrastructure.

## 1. Architectural Foundation
* **Stack:** Java (Backend API) + PostgreSQL 16 (Database).
* **Pattern:** Thin Database Architecture 
* **Execution:** The Java application executes standard `SELECT`, `INSERT`, `UPDATE`, and `DELETE` queries directly against base tables. The database engine is strictly responsible for enforcing data integrity, tenant isolation, and audit logging.

## 2. Role-Based Access Control (RBAC)
The database operates on a strict least-privilege model using five specific roles:
* **`app_owner`**: The non-login role that owns all schemas, tables, functions, and triggers. 
* **`app_admin`**: Used exclusively by Flyway (or other Java migration tools) via Spring Boot to execute schema changes. Migration files must begin with `SET ROLE app_owner;` to ensure newly created objects are assigned to the correct owner when Flyway runs them.
* **`app_runtime`**: The identity used by the Java API for standard user requests. It is restricted by Row Level Security (RLS) and relies on transaction-scoped session variables to access data. Write access to global lookup tables is explicitly revoked.
* **`app_worker`**: The identity used by background services (e.g., Plaid webhook processing). It possesses the `BYPASSRLS` attribute to update records globally without requiring a tenant context.
* **`auditor`**: A strictly read-only role confined exclusively to the `audit` schema. It does not possess `BYPASSRLS` and cannot query live application tables.

## 3. Row-Level Security (RLS)
Tenant isolation is enforced dynamically at the database engine level.
* **Symmetrical Policies:** Read and write policies are identical. We utilize the `USING` clause exclusively, relying on PostgreSQL to automatically enforce it as the `WITH CHECK` constraint for mutations.
* **Context Extraction:** RLS policies rely on a centralized stable function: `core.current_tenant()`. This function extracts the tenant ID safely: `NULLIF(current_setting('app.context.current_tenant_id', true), '')::UUID`.
* **Hierarchical Enforcement:** Tables without a direct `user_id` column (e.g., `plaid.plaid_account`, `finance.transaction_income_override`) enforce RLS by traversing foreign keys up to the parent record via a subquery.

## 4. Audit & Tamper-Proofing
All modifications to financial and operational data are logged immutably.
* **Trigger Mechanism:** The `audit.log_row_change()` trigger fires on all `INSERT`, `UPDATE`, and `DELETE` operations across the `core`, `auth`, `finance`, `budget`, `timekeeping`, and `plaid` schemas.
* **Payload Structure:** The trigger captures the `app.context.request_id`, the active tenant ID, the database role, and the complete JSONB `before_data` and `after_data` payloads, storing them in `audit.audit_row_change`.
* **Global Tables:** Lookup tables (e.g., `auth.hash_algo`, `finance.account_type`, `finance.account_subtype`) are global. The Java API cannot write to them. They are populated strictly via migration seed scripts or the `app_worker`. User-defined categories (e.g., `budget.user_category`) remain writable by `app_runtime`.

## 5. The Java API Contract
To prevent connection pooling leaks and correctly trigger RLS and audit logs, every authenticated database interaction by `app_runtime` MUST be wrapped in a single database transaction (e.g., via `@Transactional` or manual connection management).

Before executing any business logic query, the repository must inject the context:
```java
try (PreparedStatement stmt1 = connection.prepareStatement("SET LOCAL app.context.current_tenant_id = ?");
     PreparedStatement stmt2 = connection.prepareStatement("SET LOCAL app.context.request_id = ?")) {
    stmt1.setObject(1, tenantId);
    stmt1.execute();
    
    stmt2.setObject(1, requestId);
    stmt2.execute();
}
```
## 6. Docker & Tooling Infrastructure
Migrations: Executed natively via Flyway integrated within the Java application lifecycle. The Spring Boot application inherently handles migrating on startup.

Makefile Integration: Standard commands manage the local environment footprint and testing boundaries.

make db-up: Starts the database in the background and waits for it to become healthy. It no longer implicitly runs migrations.

make db-clean: Tears down the database, deletes the persistent volume, and prunes images for a clean test state.

## 7. Testing Strategy
Database-Native Unit Testing (pgTAP): SQL-based tests executed via pg_prove to verify schema definitions, foreign key integrity, RLS enforcement, and role permissions. Run against the container directly.

Ephemeral Container Testing (Testcontainers for Java): The Java test suite programmatically spins up isolated PostgreSQL instances, runs migrations, executes integration tests, and destroys the container.

Application-Layer Integration: Java tests utilize the Transaction Rollback Pattern (executing queries inside a transaction and rolling back instead of committing) to ensure test isolation and database cleanliness.

## 8. Data Seeding Strategy
Data seeding is explicitly decoupled from schema structure to prevent mock data leakage.

Production Seed (Static): Handled via versioned migrations in Flyway (e.g., `V10__seed_static.sql`). Contains immutable system taxonomy required for the application to function.

Development Seed (Mock): A standalone SQL script (db/scripts/seed_dev.sql) executed manually or via make to populate the local environment with mock users and transactions.

Test Seed (Dynamic): Handled dynamically by the Java test suite at runtime to ensure precise, deterministic setups for each test case.

