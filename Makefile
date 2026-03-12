include .env
export

.PHONY: all clean test db-up db-down db-clean
all: db-up

clean: db-clean

test: db-up
	@echo "Running pgTAP tests..."
	docker-compose exec -T -e PGPASSWORD=${APP_ADMIN_PASSWORD} db sh -c 'pg_prove -U app_admin -d ${POSTGRES_DB} /tests/*.sql'

# Starts the database and waits for it to become healthy
db-up:
	docker-compose up -d --wait db


# Stops the database safely
db-down:
	docker-compose down

# Nukes the database and the volume (perfect for resetting your test state)
db-clean:
	docker-compose down -v --rmi local
