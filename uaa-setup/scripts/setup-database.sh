#!/bin/bash

# UAA Database Setup Script
# Creates PostgreSQL user and database for UAA
#
# Usage: Run with PostgreSQL admin credentials
#   ./uaa-setup/scripts/setup-database.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "========================================="
echo "UAA PostgreSQL Database Setup"
echo "========================================="
echo ""

# Database configuration
DB_NAME="uaa"
DB_USER="uaauser"
DB_PASSWORD="uaapassword"
POSTGRES_USER="${POSTGRES_USER:-postgres}"

echo -e "${BLUE}This script will create:${NC}"
echo "  • Database: $DB_NAME"
echo "  • User: $DB_USER"
echo "  • Password: $DB_PASSWORD"
echo ""

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo -e "${RED}Error: PostgreSQL client (psql) not found!${NC}"
    echo "Please install PostgreSQL first."
    exit 1
fi

echo -e "${YELLOW}Connecting to PostgreSQL as '$POSTGRES_USER'...${NC}"
echo ""

# Create user if it doesn't exist
echo -e "${BLUE}Creating database user '$DB_USER'...${NC}"
psql -U "$POSTGRES_USER" -tc "SELECT 1 FROM pg_user WHERE usename = '$DB_USER'" | grep -q 1 && \
echo -e "${YELLOW}User '$DB_USER' already exists, updating password...${NC}" || \
echo -e "${GREEN}Creating new user '$DB_USER'...${NC}"

psql -U "$POSTGRES_USER" <<-EOSQL
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_user WHERE usename = '$DB_USER') THEN
            CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
        ELSE
            ALTER USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
        END IF;
    END
    \$\$;
EOSQL

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ User '$DB_USER' ready${NC}"
else
    echo -e "${RED}✗ Failed to create/update user${NC}"
    exit 1
fi

# Create database if it doesn't exist
echo -e "${BLUE}Creating database '$DB_NAME'...${NC}"
psql -U "$POSTGRES_USER" -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 && \
echo -e "${YELLOW}Database '$DB_NAME' already exists${NC}" || \
psql -U "$POSTGRES_USER" -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database '$DB_NAME' ready${NC}"
else
    echo -e "${RED}✗ Failed to create database${NC}"
    exit 1
fi

# Grant privileges
echo -e "${BLUE}Granting privileges...${NC}"
psql -U "$POSTGRES_USER" <<-EOSQL
    GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOSQL

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Privileges granted${NC}"
else
    echo -e "${RED}✗ Failed to grant privileges${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Database Setup Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Database Details:"
echo "  Host: localhost"
echo "  Port: 5432"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Password: $DB_PASSWORD"
echo ""
echo "Test connection:"
echo "  psql -U $DB_USER -d $DB_NAME -h localhost"
echo ""
echo "Next steps:"
echo "  1. Generate keys: ./uaa-setup/scripts/generate-uaa-keys.sh"
echo "  2. Build UAA: ./gradlew clean :cloudfoundry-identity-uaa:assemble"
echo "  3. Start UAA: docker compose up --build"
