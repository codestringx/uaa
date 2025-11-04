#!/bin/bash

# UAA Database Backup Script
# This script creates a backup of the UAA PostgreSQL database

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Auto-detect UAA root directory (2 levels up from this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UAA_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo -e "${GREEN}UAA Database Backup Script${NC}"
echo "UAA Root: $UAA_ROOT"
echo "-----------------------------------"

# Change to UAA root directory
cd "$UAA_ROOT"

# Configuration
BACKUP_DIR="$UAA_ROOT/backups/database"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="uaa_backup_${TIMESTAMP}.sql"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE"

# Database credentials (from config/uaa.yml)
DB_NAME="uaa"
DB_USER="uaauser"
DB_PASSWORD="uaapassword"
DB_HOST="localhost"
DB_PORT="5432"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo -e "${YELLOW}Creating database backup...${NC}"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo "Host: $DB_HOST:$DB_PORT"
echo "Backup file: $BACKUP_FILE"
echo ""

# Check if PostgreSQL is running
if ! docker-compose ps postgres | grep -q "Up"; then
    echo -e "${RED}Error: PostgreSQL container is not running${NC}"
    echo "Start it with: docker-compose up -d postgres"
    exit 1
fi

# Create backup using pg_dump through Docker
echo "Executing pg_dump..."
docker-compose exec -T postgres pg_dump -U "$DB_USER" "$DB_NAME" > "$BACKUP_PATH"

if [ $? -eq 0 ]; then
    # Compress the backup
    echo "Compressing backup..."
    gzip "$BACKUP_PATH"
    BACKUP_PATH="${BACKUP_PATH}.gz"
    
    # Get file size
    FILESIZE=$(du -h "$BACKUP_PATH" | cut -f1)
    
    echo ""
    echo -e "${GREEN}✓ Backup completed successfully!${NC}"
    echo "Backup location: $BACKUP_PATH"
    echo "Backup size: $FILESIZE"
    
    # Keep only last 10 backups
    echo ""
    echo "Cleaning old backups (keeping last 10)..."
    cd "$BACKUP_DIR"
    ls -t uaa_backup_*.sql.gz | tail -n +11 | xargs -r rm -f
    
    BACKUP_COUNT=$(ls -1 uaa_backup_*.sql.gz 2>/dev/null | wc -l)
    echo "Current backups: $BACKUP_COUNT"
    
    echo ""
    echo -e "${GREEN}To restore this backup, run:${NC}"
    echo "  ./uaa-setup/scripts/restore-database.sh $BACKUP_FILE.gz"
else
    echo -e "${RED}✗ Backup failed!${NC}"
    exit 1
fi
