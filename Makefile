.PHONY: run clean build test integration-test check-db setup-db help

# Default target
.DEFAULT_GOAL := help

# Variables
DB_USER = uaauser
DB_PASS = uaapass
DB_NAME = uaa
GRADLE = ./gradlew

# Colors for help output
BLUE = \033[36m
NC = \033[0m

help:
	@echo "$(BLUE)UAA Management Commands:$(NC)"
	@echo "  make run              - Run UAA with PostgreSQL"
	@echo "  make build            - Build the project"
	@echo "  make clean            - Clean build directories"
	@echo "  make test             - Run unit tests"
	@echo "  make integration-test - Run integration tests"
	@echo "  make check-db         - Check PostgreSQL connection"
	@echo "  make setup-db         - Set up PostgreSQL database and permissions"
	@echo "  make all              - Clean, build, and run tests"

run:
	$(GRADLE) -Ddatabase.username=$(DB_USER) \
		-Ddatabase.password=$(DB_PASS) \
		-Dspring.profiles.active=default,postgresql \
		:cloudfoundry-identity-uaa:bootRun

build:
	$(GRADLE) build -x test

clean:
	$(GRADLE) clean

test:
	$(GRADLE) test

integration-test:
	$(GRADLE) integrationTest

check-db:
	@echo "Checking PostgreSQL connection..."
	@psql -U $(DB_USER) -d $(DB_NAME) -c "\conninfo" || echo "Connection failed!"

setup-db:
	@echo "Setting up PostgreSQL database..."
	@psql -U postgres -c "CREATE DATABASE $(DB_NAME);" || echo "Database may already exist"
	@psql -U postgres -c "CREATE USER $(DB_USER) WITH PASSWORD '$(DB_PASS)';" || echo "User may already exist"
	@psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE $(DB_NAME) TO $(DB_USER);"
	@psql -U postgres -d $(DB_NAME) -c "GRANT ALL ON SCHEMA public TO $(DB_USER);"
	@psql -U postgres -d $(DB_NAME) -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $(DB_USER);"
	@psql -U postgres -d $(DB_NAME) -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $(DB_USER);"
	@echo "Database setup completed!"

all: clean build test