# Intellibills

Intellibills is a personal finance application designed to track earnings and expenses, featuring an integrated schedule planner and timekeeping system. The application analyzes historical earnings data to recommend optimal work schedules, specifically targeting the needs of independent contractors and gig workers.

## Architecture

This project utilizes a **Thin Database Architecture** prioritizing strict separation of concerns, robust security, and automated testing.

* **Backend Application:** Go
* **Database:** PostgreSQL
* **Infrastructure:** Docker

### Security & Access Control

The database layer enforces strict security policies at the transaction level:
* **Role-Based Access Control (RBAC):** Access is explicitly isolated across dedicated roles (`app_owner`, `app_runtime`, `app_worker`, `auditor`).
* **Row-Level Security (RLS):** Data access is governed by dynamic, transaction-scoped session variables to ensure users and workers only interact with their permitted records.

## Development & Testing

The development environment relies on containerization to ensure parity between local development, testing, and production.

### Prerequisites
* Docker & Docker Compose
* Go 1.22+
* PostgreSQL client tools (e.g., DataGrip, psql)

### Testing Stack
Testing is divided into database-level unit tests and application-level integration tests:
* **Database Unit Testing:** `pgTAP` is used to validate schema definitions, RBAC policies, and RLS constraints directly within PostgreSQL.
* **Integration Testing:** `Go Testcontainers` spins up ephemeral database instances to run automated integration tests against the Go API.

## Getting Started

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/jordinkolman/intellibills.git
    cd intellibills
    ```

2.  **Start the local environment:**
    ```bash
    docker-compose up -d
    ```

3.  **Run database migrations and tests:**
    ```bash
    # Command to run your specific migration tool (e.g., golang-migrate or goose)
    # Command to execute pgTAP tests
    ```

4.  **Run the Go application:**
    ```bash
    go run main.go
    ```

## Roadmap
* Finalize MVP database schema and RLS policies.
* Develop Go API endpoints for core transaction tracking.
* Develop Next.js Web App
* Develop core budgeting tools and transaction syncing with Plaid.
* Implement AI toolchain for category recommendations, user chat interaction, etc.
* Implement historical earnings analysis algorithm.
* Build the schedule recommendation engine.
* Develop mobile application(s) for Android and iOS
* Develop location and mileage tracking for expense tracking.
