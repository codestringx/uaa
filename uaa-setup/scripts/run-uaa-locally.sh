#!/bin/bash

# UAA Local Run Script (without Docker)
# Runs UAA directly with Gradle and local PostgreSQL
#
# Usage: Run from UAA root directory
#   ./uaa-setup/scripts/run-uaa-locally.sh

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the UAA root directory (2 levels up from script location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UAA_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Change to UAA root directory
cd "$UAA_ROOT"

echo "Working directory: $UAA_ROOT"
echo ""

# Configuration
DB_USER="uaauser"
DB_PASS="uaapass"
DB_NAME="uaa"
PROFILES="default,postgresql"

echo -e "${BLUE}Starting UAA with PostgreSQL (local mode)...${NC}"

# Check if PostgreSQL is running
if ! command -v psql &> /dev/null; then
    echo -e "${RED}PostgreSQL client not found. Please install PostgreSQL.${NC}"
    exit 1
fi

# Test database connection
if ! psql -U "$DB_USER" -d "$DB_NAME" -c "\conninfo" &> /dev/null; then
    echo -e "${RED}Cannot connect to database. Please check if:${NC}"
    echo "1. PostgreSQL is running"
    echo "2. Database '$DB_NAME' exists"
    echo "3. User '$DB_USER' has correct permissions"
    echo -e "${BLUE}You can run 'make setup-db' to initialize the database.${NC}"
    exit 1
fi

echo -e "${GREEN}Database connection successful.${NC}"
echo -e "${BLUE}Starting UAA server...${NC}"

# Run UAA
./gradlew -Ddatabase.username="$DB_USER" \
    -Ddatabase.password="$DB_PASS" \
    -Dspring.profiles.active="$PROFILES" \
    :cloudfoundry-identity-uaa:bootRun