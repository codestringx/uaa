#!/bin/bash

# UAA Database Restore Script
# This script restores a UAA PostgreSQL database from backup

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Auto-detect UAA root directory (2 levels up from this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UAA_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo -e "${GREEN}UAA Database Restore Script${NC}"
echo "UAA Root: $UAA_ROOT"
echo "-----------------------------------"

# Check if backup file is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: No backup file specified${NC}"
    echo ""
    echo "Usage: $0 <backup_file>"
    echo ""
    echo "Available backups:"
    ls -lh "$UAA_ROOT/backups/database/"uaa_backup_*.sql.gz 2>/dev/null || echo "  No backups found"
    exit 1
fi

BACKUP_FILE="$1"

# If relative path, look in backups directory
if [[ ! "$BACKUP_FILE" = /* ]]; then
    BACKUP_FILE="$UAA_ROOT/backups/database/$BACKUP_FILE"
fi

# Check if file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}Error: Backup file not found: $BACKUP_FILE${NC}"
    exit 1
fi

# Change to UAA root directory
cd "$UAA_ROOT"

# Database credentials (from config/uaa.yml)
DB_NAME="uaa"
DB_USER="uaauser"
DB_PASSWORD="uaapassword"

echo -e "${YELLOW}Restoring database from backup...${NC}"
echo "Backup file: $BACKUP_FILE"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo ""

# Warning
echo -e "${RED}WARNING: This will replace all data in the UAA database!${NC}"
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

# Check if PostgreSQL is running
if ! docker-compose ps postgres | grep -q "Up"; then
    echo -e "${RED}Error: PostgreSQL container is not running${NC}"
    echo "Start it with: docker-compose up -d postgres"
    exit 1
fi

# Stop UAA server to prevent database access
echo "Stopping UAA server..."
docker-compose stop uaa

# Decompress if needed
TEMP_SQL=""
if [[ "$BACKUP_FILE" == *.gz ]]; then
    echo "Decompressing backup..."
    TEMP_SQL="/tmp/uaa_restore_$$.sql"
    gunzip -c "$BACKUP_FILE" > "$TEMP_SQL"
    RESTORE_FILE="$TEMP_SQL"
else
    RESTORE_FILE="$BACKUP_FILE"
fi

# Drop and recreate database
echo "Dropping existing database..."
docker-compose exec -T postgres psql -U "$DB_USER" -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;"

echo "Creating new database..."
docker-compose exec -T postgres psql -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"

# Restore backup
echo "Restoring data..."
docker-compose exec -T postgres psql -U "$DB_USER" -d "$DB_NAME" < "$RESTORE_FILE"

# Clean up temp file
if [ -n "$TEMP_SQL" ]; then
    rm -f "$TEMP_SQL"
fi

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Database restored successfully!${NC}"
    echo ""
    echo "Starting UAA server..."
    docker-compose up -d uaa
    
    echo ""
    echo "Waiting for UAA to start..."
    sleep 10
    
    echo "Checking UAA health..."
    curl -s http://localhost:8080/healthz && echo "" || echo -e "${YELLOW}UAA is still starting up...${NC}"
else
    echo -e "${RED}✗ Restore failed!${NC}"
    docker-compose up -d uaa
    exit 1
fi
