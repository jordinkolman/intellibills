include .env
export

.PHONY: all clean test db-up db-down db-clean
all: db-up

clean: db-clean

test: restore-schemas
	@echo "Running pgTAP tests..."
	docker-compose exec -T -e PGPASSWORD=${APP_ADMIN_PASSWORD} db sh -c 'pg_prove -U app_admin -d ${POSTGRES_DB} /tests/*.sql'

# Manually execute the Flyway-formatted migration scripts so pgTAP tests have a schema to run against
restore-schemas: db-up
	@echo "Restoring database schemas from Flyway scripts..."
	docker-compose exec -T -e PGPASSWORD=${APP_ADMIN_PASSWORD} db sh -c 'for f in /migrations/V*__*.sql; do psql -U app_admin -d ${POSTGRES_DB} -f "$$f"; done'

# Starts the database and waits for it to become healthy
db-up:
	docker-compose up -d --wait db


# Stops the database safely
db-down:
	docker-compose down

# Nukes the database and the volume (perfect for resetting your test state)
db-clean:
	docker-compose down -v --rmi local
