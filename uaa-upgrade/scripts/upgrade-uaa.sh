#!/bin/bash

# UAA Upgrade Script
# This script helps upgrade UAA to a new version while preserving customizations

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Auto-detect UAA root directory (2 levels up from this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UAA_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    UAA Upgrade Script                  ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo ""
echo "UAA Root: $UAA_ROOT"
echo ""

# Check if target version is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: No target version specified${NC}"
    echo ""
    echo "Usage: $0 <version>"
    echo ""
    echo "Examples:"
    echo "  $0 77.0.0"
    echo "  $0 latest"
    echo ""
    echo "To see available versions:"
    echo "  git ls-remote --tags https://github.com/cloudfoundry/uaa.git | grep -v '{}' | awk '{print \$2}' | sed 's|refs/tags/||' | sort -V | tail -n 10"
    exit 1
fi

TARGET_VERSION="$1"

# Change to UAA root directory
cd "$UAA_ROOT"

# Get current version/branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
echo -e "${YELLOW}Current branch:${NC} $CURRENT_BRANCH"
echo -e "${YELLOW}Target version:${NC} $TARGET_VERSION"
echo ""

# Step 1: Pre-upgrade checklist
echo -e "${BLUE}Step 1: Pre-Upgrade Checklist${NC}"
echo "-----------------------------------"

# Check for uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${YELLOW}⚠ You have uncommitted changes${NC}"
    git status --short
    echo ""
    read -p "Do you want to stash these changes? (yes/no): " STASH_CONFIRM
    if [ "$STASH_CONFIRM" = "yes" ]; then
        git stash save "Pre-upgrade stash before v$TARGET_VERSION - $(date +%Y%m%d_%H%M%S)"
        echo -e "${GREEN}✓ Changes stashed${NC}"
    fi
fi

# Step 2: Create backup
echo ""
echo -e "${BLUE}Step 2: Creating Backup${NC}"
echo "-----------------------------------"

# Create backup branch
BACKUP_BRANCH="backup-before-v${TARGET_VERSION}-$(date +%Y%m%d_%H%M%S)"
git checkout -b "$BACKUP_BRANCH"
git add -A
git commit -m "Backup before upgrade to v$TARGET_VERSION" || true
git checkout "$CURRENT_BRANCH"
echo -e "${GREEN}✓ Backup branch created: $BACKUP_BRANCH${NC}"

# Backup database
echo ""
read -p "Create database backup? (yes/no): " DB_BACKUP_CONFIRM
if [ "$DB_BACKUP_CONFIRM" = "yes" ]; then
    ./uaa-upgrade/scripts/backup-database.sh
fi

# Backup configuration files
echo ""
echo "Backing up configuration files..."
cp config/uaa.yml "config/uaa.yml.backup.$(date +%Y%m%d_%H%M%S)"
cp -r app/ "app.backup.$(date +%Y%m%d_%H%M%S)/"
echo -e "${GREEN}✓ Configuration backed up${NC}"

# Step 3: Fetch new version
echo ""
echo -e "${BLUE}Step 3: Fetching New Version${NC}"
echo "-----------------------------------"

# Add upstream if not exists
if ! git remote get-url upstream &>/dev/null; then
    echo "Adding upstream remote..."
    git remote add upstream https://github.com/cloudfoundry/uaa.git
fi

echo "Fetching from upstream..."
git fetch upstream --tags

# Verify version exists
if [ "$TARGET_VERSION" != "latest" ]; then
    if ! git rev-parse "v$TARGET_VERSION" &>/dev/null && ! git rev-parse "$TARGET_VERSION" &>/dev/null; then
        echo -e "${RED}✗ Version $TARGET_VERSION not found${NC}"
        echo ""
        echo "Available recent versions:"
        git tag | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n 10
        exit 1
    fi
fi

echo -e "${GREEN}✓ Version fetched${NC}"

# Step 4: Stop services
echo ""
echo -e "${BLUE}Step 4: Stopping Services${NC}"
echo "-----------------------------------"
docker-compose down
echo -e "${GREEN}✓ Services stopped${NC}"

# Step 5: Perform upgrade
echo ""
echo -e "${BLUE}Step 5: Performing Upgrade${NC}"
echo "-----------------------------------"

if [ "$TARGET_VERSION" = "latest" ]; then
    TARGET_REF="upstream/develop"
else
    # Try with 'v' prefix first
    if git rev-parse "v$TARGET_VERSION" &>/dev/null; then
        TARGET_REF="v$TARGET_VERSION"
    else
        TARGET_REF="$TARGET_VERSION"
    fi
fi

echo "Merging $TARGET_REF..."
if git merge "$TARGET_REF" --no-edit; then
    echo -e "${GREEN}✓ Merge successful${NC}"
else
    echo -e "${RED}✗ Merge conflicts detected${NC}"
    echo ""
    echo "Conflicting files:"
    git diff --name-only --diff-filter=U
    echo ""
    echo "Please resolve conflicts manually:"
    echo "  1. Edit the conflicting files"
    echo "  2. Mark as resolved: git add <file>"
    echo "  3. Complete merge: git commit"
    echo "  4. Re-run this script or continue manually"
    exit 1
fi

# Step 6: Restore customizations
echo ""
echo -e "${BLUE}Step 6: Checking Customizations${NC}"
echo "-----------------------------------"

# Check if critical files were modified
if git diff --name-only HEAD@{1} HEAD | grep -q "config/uaa.yml"; then
    echo -e "${YELLOW}⚠ config/uaa.yml was modified in the upgrade${NC}"
    echo "You may need to manually merge changes"
    echo "Your backup: config/uaa.yml.backup.*"
fi

if git diff --name-only HEAD@{1} HEAD | grep -q "docker-compose.yml"; then
    echo -e "${YELLOW}⚠ docker-compose.yml was modified in the upgrade${NC}"
    echo "Review changes carefully"
fi

# Step 7: Build
echo ""
echo -e "${BLUE}Step 7: Building UAA${NC}"
echo "-----------------------------------"
./gradlew clean build -x test

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Build failed${NC}"
    echo ""
    echo "To rollback:"
    echo "  git checkout $BACKUP_BRANCH"
    echo "  docker-compose up -d"
    exit 1
fi

echo -e "${GREEN}✓ Build successful${NC}"

# Step 8: Start services
echo ""
echo -e "${BLUE}Step 8: Starting Services${NC}"
echo "-----------------------------------"
docker-compose up -d

echo "Waiting for UAA to start (30 seconds)..."
sleep 30

# Step 9: Verify
echo ""
echo -e "${BLUE}Step 9: Verification${NC}"
echo "-----------------------------------"

echo "Checking UAA health..."
if curl -sf http://localhost:8080/healthz > /dev/null; then
    echo -e "${GREEN}✓ UAA is healthy${NC}"
else
    echo -e "${YELLOW}⚠ UAA health check failed (may still be starting)${NC}"
fi

echo ""
echo "Checking database connection..."
if docker-compose exec -T postgres psql -U uaauser -d uaa -c "SELECT count(*) FROM users;" &>/dev/null; then
    USER_COUNT=$(docker-compose exec -T postgres psql -U uaauser -d uaa -t -c "SELECT count(*) FROM users;")
    echo -e "${GREEN}✓ Database connected (Users: $USER_COUNT)${NC}"
else
    echo -e "${YELLOW}⚠ Database check failed${NC}"
fi

# Final summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    Upgrade Complete!                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Summary:"
echo "  Current version: $TARGET_VERSION"
echo "  Backup branch: $BACKUP_BRANCH"
echo "  Config backup: config/uaa.yml.backup.*"
echo ""
echo "Next steps:"
echo "  1. Test your UAA installation thoroughly"
echo "  2. Check logs: docker-compose logs -f uaa"
echo "  3. Test SAML: openssl x509 -in app/saml.crt -text -noout | grep Subject"
echo "  4. Test login and token generation"
echo ""
echo "If something went wrong:"
echo "  Rollback: git checkout $BACKUP_BRANCH"
echo "  Restore DB: ./uaa-setup/scripts/restore-database.sh <backup-file>"
echo ""
echo -e "${GREEN}Happy upgrading! 🚀${NC}"
