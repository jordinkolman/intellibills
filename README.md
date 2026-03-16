# Intellibills

Intellibills is a personal finance application designed to track earnings and expenses, featuring an integrated schedule planner and timekeeping system. The application analyzes historical earnings data to recommend optimal work schedules, specifically targeting the needs of independent contractors and gig workers.

## Architecture & Stack Plans

This project utilizes a **Thin Database Architecture** prioritizing strict separation of concerns, robust security, and automated testing. It is planned as a full-stack system with a cohesive ecosystem of native and web clients consuming a centralized business API.

* **Backend API:** Java (Spring Boot)
* **Database:** PostgreSQL 16
* **Web Application:** Next.js (Planned)
* **Mobile Applications:** Android & iOS (Planned)
* **Infrastructure:** Docker & Docker Compose
* **Migrations:** Flyway (integrated in Spring Boot lifecycle)

### Security & Access Control

The database layer enforces strict security policies at the transaction level:
* **Role-Based Access Control (RBAC):** Access is explicitly isolated across dedicated roles (`app_owner`, `app_runtime`, `app_worker`, `auditor`).
* **Row-Level Security (RLS):** Data access is governed by dynamic, transaction-scoped session variables to ensure users and workers only interact with their permitted records.

## Development & Testing

The development environment relies on containerization to ensure parity between local development, testing, and production.

### Prerequisites
* Docker & Docker Compose
* Java (e.g., JDK 21)
* Maven or Gradle (or use the wrapper)
* PostgreSQL client tools (e.g., DataGrip, psql)

### Testing Stack
Testing is divided into database-level unit tests and application-level integration tests:
* **Database Unit Testing:** `pgTAP` is used to validate schema definitions, RBAC policies, and RLS constraints directly within PostgreSQL.
* **Integration Testing:** `Testcontainers for Java` spins up ephemeral database instances to run automated integration tests against the Java API.

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
    # Migrations run automatically on startup via Flyway in Spring Boot.
    # Command to execute pgTAP tests can be run via Makefile or docker-compose
    ```

4.  **Run the Java API:**
    *Note: The Java Spring Boot API and Maven setup is planned for a future iteration and is not currently available to run.*

## Roadmap
* Finalize MVP database schema and RLS policies.
* Develop Java Spring Boot API endpoints for core transaction tracking.
* Develop Next.js Web App
* Develop core budgeting tools and transaction syncing with Plaid.
* Implement AI toolchain for category recommendations, user chat interaction, etc.
* Implement historical earnings analysis algorithm.
* Build the schedule recommendation engine.
* Develop mobile application(s) for Android and iOS
* Develop location and mileage tracking for expense tracking.
