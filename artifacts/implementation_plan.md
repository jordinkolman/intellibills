# Flyway Migration Preparation Plan

This document outlines the final steps to prepare the codebase's existing database migrations for integration into a Spring Boot application using Flyway.

The aim is to keep the files in their current location but standardize their structure so that when the project adopts Spring Boot, they can be immediately dropped in.

## Current State (golang-migrate)
* Valid migration scripts reside in `./db/migrations/`.
* Managed via `golang-migrate` syntax: e.g., [000001_audit.up.sql](file://wsl.localhost/Ubuntu/home/jordinkolman/workspace/java-projects/intellibills/db/migrations/000001_audit.up.sql) and [000001_audit.down.sql](file://wsl.localhost/Ubuntu/home/jordinkolman/workspace/java-projects/intellibills/db/migrations/000001_audit.down.sql).
* Orchestrated by [docker-compose.yml](file://wsl.localhost/Ubuntu/home/jordinkolman/workspace/java-projects/intellibills/docker-compose.yml) and the [Makefile](file://wsl.localhost/Ubuntu/home/jordinkolman/workspace/java-projects/intellibills/Makefile) executing the `migrate` Docker container.

## Proposed Strategy (In-Place Preparation)

As generating a Spring Boot project (e.g., via Spring Initializr) typically handles its own directory structure, we will avoid creating the target `src/main/resources/db/migration/` explicitly. Instead, we will clean up and rename the files *in place* within `./db/migrations/`.

### 1. Stripping Go Dependency Tooling
We will remove the orchestration tools associated with the Go migration model safely:
*   **Remove the `migrate` service** from [docker-compose.yml](file://wsl.localhost/Ubuntu/home/jordinkolman/workspace/java-projects/intellibills/docker-compose.yml).
*   **Simplify the [Makefile](file://wsl.localhost/Ubuntu/home/jordinkolman/workspace/java-projects/intellibills/Makefile)**: Prevent any commands from invoking the obsolete migration container. We'll simply leave `docker-compose up -d --wait db` as a stubbed utility to launch postgres.

### 2. Rename and Cleanup Migrations
Standard Flyway requires migrations to adhere to Versioned naming: `V<Version>__<Description>.sql` (note the **double underscore**).
*   **Delete All [.down.sql](file://wsl.localhost/Ubuntu/home/jordinkolman/workspace/java-projects/intellibills/db/migrations/000008_rls.down.sql) Files:** Flyway Community Edition uses a "roll-forward" model natively. We will delete all nine rollback scripts completely.
*   **Rename [.up.sql](file://wsl.localhost/Ubuntu/home/jordinkolman/workspace/java-projects/intellibills/db/migrations/000008_rls.up.sql) scripts to `VX__...sql`** directly within `./db/migrations`:
    *   [000001_audit.up.sql](file://wsl.localhost/Ubuntu/home/jordinkolman/workspace/java-projects/intellibills/db/migrations/000001_audit.up.sql) -> `V1__audit.sql`
    *   [000002_core.up.sql](file://wsl.localhost/Ubuntu/home/jordinkolman/workspace/java-projects/intellibills/db/migrations/000002_core.up.sql) -> `V2__core.sql`
    *   [000003_auth.up.sql](file://wsl.localhost/Ubuntu/home/jordinkolman/workspace/java-projects/intellibills/db/migrations/000003_auth.up.sql) -> `V3__auth.sql`
    *   [000004_plaid.up.sql](file://wsl.localhost/Ubuntu/home/jordinkolman/workspace/java-projects/intellibills/db/migrations/000004_plaid.up.sql) -> `V4__plaid.sql`
    *   [000005_finance.up.sql](file://wsl.localhost/Ubuntu/home/jordinkolman/workspace/java-projects/intellibills/db/migrations/000005_finance.up.sql) -> `V5__finance.sql`
    *   [000006_budget.up.sql](file://wsl.localhost/Ubuntu/home/jordinkolman/workspace/java-projects/intellibills/db/migrations/000006_budget.up.sql) -> `V6__budget.sql`
    *   [000007_timekeeping.up.sql](file://wsl.localhost/Ubuntu/home/jordinkolman/workspace/java-projects/intellibills/db/migrations/000007_timekeeping.up.sql) -> `V7__timekeeping.sql`
    *   [000008_rls.up.sql](file://wsl.localhost/Ubuntu/home/jordinkolman/workspace/java-projects/intellibills/db/migrations/000008_rls.up.sql) -> `V8__rls.sql`
    *   [000009_user_functions.up.sql](file://wsl.localhost/Ubuntu/home/jordinkolman/workspace/java-projects/intellibills/db/migrations/000009_user_functions.up.sql) -> `V9__user_functions.sql`

## The Final Cleanup
When Spring Boot is introduced later, you can seamlessly cut and paste these 9 files directly into your newly generated `src/main/resources/db/migration/` folder, and Flyway will immediately be capable of running them.

## Verification
1.  Verify exactly 9 renamed [.sql](file://wsl.localhost/Ubuntu/home/jordinkolman/workspace/java-projects/intellibills/db/migrations/000008_rls.up.sql) files exist in `./db/migrations/`.
2.  Verify no [.down.sql](file://wsl.localhost/Ubuntu/home/jordinkolman/workspace/java-projects/intellibills/db/migrations/000008_rls.down.sql) files remain.
3.  Ensure [docker-compose.yml](file://wsl.localhost/Ubuntu/home/jordinkolman/workspace/java-projects/intellibills/docker-compose.yml) no longer attempts to bring up the `migrate/migrate` image.
