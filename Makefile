.PHONY: db-up db-down db-clean


# Starts the database and runs the ephemeral migration container

db-up:
	docker-compose up -d db
	docker-compose run --rm migrate


# Stops the database safely
db-down:
	docker-compose down

# Nukes the database and the volume (perfect for resetting your test state)
db-clean:

	docker-compose down -v
	docker image prune -f
