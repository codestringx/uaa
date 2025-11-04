---
applyTo: "uaa-upgrade/**"
---

# GitHub Copilot Instructions for uaa-upgrade/ Directory

## Purpose
This directory contains resources for **version upgrades and maintenance** of UAA.

## Directory Structure

```
uaa-upgrade/
├── docs/           # Upgrade documentation
│   ├── UPGRADE-QUICK-SUMMARY.md
│   ├── UPGRADE-GUIDE.md
│   └── CUSTOMIZATIONS.md
└── scripts/        # Upgrade and maintenance scripts
    ├── upgrade-uaa.sh
    ├── backup-database.sh
    └── restore-database.sh
```

## Documentation (docs/)

### Key Files:
- `UPGRADE-QUICK-SUMMARY.md` - Quick upgrade reference
- `UPGRADE-GUIDE.md` - Detailed upgrade procedures (3 methods)
- `CUSTOMIZATIONS.md` - Track all Elephant Insurance customizations

### Documentation Standards:
1. Use Markdown format
2. Include version numbers and dates
3. Document what gets preserved during upgrades
4. Provide rollback procedures
5. Include verification steps
6. Warn about breaking changes

## Scripts (scripts/)

### Key Scripts:
- `upgrade-uaa.sh` - Automated upgrade with backups and testing
- `backup-database.sh` - PostgreSQL backup with compression
- `restore-database.sh` - Database restoration with safety checks

### Script Conventions

#### Auto-Path Detection (REQUIRED)
Every script MUST include:
```bash
#!/bin/bash
set -e

# Determine script directory and UAA root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UAA_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$UAA_ROOT"
```

#### Colored Output (REQUIRED)
```bash
# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}✓ Success message${NC}"
echo -e "${YELLOW}⚠ Warning message${NC}"
echo -e "${RED}✗ Error message${NC}"
echo -e "${BLUE}ℹ Info message${NC}"
```

## Critical Upgrade Rules

### Files to PRESERVE During Upgrades
1. `config/uaa.yml` - All configuration
2. `app/` - All keys and certificates (SAML, JWT)
3. `uaa-setup/` - All setup resources
4. `uaa-upgrade/` - All upgrade resources (this directory)
5. `docker-compose.yml` - Docker configuration
6. Database volume data

### Files to UPDATE from Upstream
1. Core Java source code (`server/src/`, `model/src/`, etc.)
2. Gradle configuration (`build.gradle`, `dependencies.gradle`)
3. Documentation (`docs/`)
4. Default configurations (but preserve customizations)

### Backup Strategy
ALWAYS create backups before upgrades:
```bash
# Git backup branch
git checkout -b backup-$(date +%Y%m%d)

# Database backup
./uaa-upgrade/scripts/backup-database.sh
```

## Rules

### ✅ DO:
1. Create Git backup branches before upgrades
2. Backup database before any changes
3. Test upgrades in development first
4. Document all customizations in CUSTOMIZATIONS.md
5. Verify UAA health after upgrade
6. Keep last 10 database backups
7. Use timestamped backup filenames
8. Compress database backups (gzip)
9. Provide rollback procedures
10. Check for breaking changes in release notes

### ❌ DON'T:
1. Upgrade without backing up first
2. Delete customized configuration files
3. Overwrite Elephant Insurance certificates
4. Skip testing in development
5. Create backups without timestamps
6. Keep unlimited backups (clean old ones)
7. Forget to update CUSTOMIZATIONS.md
8. Skip database migrations
9. Ignore merge conflicts
10. Upgrade directly to production

## Elephant Insurance Customizations to Preserve

### Database Configuration
```yaml
spring:
  datasource:
    username: uaauser  # NOT postgres
    password: uaapassword
```

### SAML Certificates
Must contain:
```
C=US, ST=Virginia, L=Henrico, O=Elephant Insurance, 
OU=Digital Development, CN=elephant.com
```

### Directory Structure
- `uaa-setup/` - Setup resources
- `uaa-upgrade/` - Upgrade resources (this directory)
- `app/` - Keys and certificates
- `config/` - Configuration files

## Upgrade Methods

### 1. Automated (Recommended)
```bash
./uaa-upgrade/scripts/upgrade-uaa.sh <version>
```

Automatically:
- Creates backup branch
- Backs up database
- Fetches updates
- Merges changes
- Rebuilds application
- Runs health checks

### 2. Git-Based Manual
```bash
git remote add upstream https://github.com/cloudfoundry/uaa.git
git fetch upstream
git merge upstream/develop
# Resolve conflicts preserving customizations
./gradlew clean build
```

### 3. Fresh Clone + Customization
For major version upgrades:
1. Clone new version
2. Reapply customizations from CUSTOMIZATIONS.md
3. Migrate database if needed
4. Test thoroughly

## Backup Script Standards

### backup-database.sh
```bash
# Timestamped filename
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backups/database/uaa_backup_${TIMESTAMP}.sql.gz"

# Compression
docker-compose exec -T postgres pg_dump -U uaauser uaa | gzip > "$BACKUP_FILE"

# Retention (keep last 10)
ls -t backups/database/uaa_backup_*.sql.gz | tail -n +11 | xargs -r rm
```

### restore-database.sh
```bash
# Safety confirmation
read -p "This will DROP the current database. Are you sure? (yes/no): " confirm

# Auto-decompress detection
if [[ $BACKUP_FILE == *.gz ]]; then
    gunzip -c "$BACKUP_FILE" | docker-compose exec -T postgres psql -U uaauser -d uaa
else
    docker-compose exec -T postgres psql -U uaauser -d uaa < "$BACKUP_FILE"
fi
```

## Version Strategy

### Git Tags
```bash
# Tag stable versions
git tag -a v1.0.0-elephant -m "Elephant Insurance UAA v1.0.0"

# List tags
git tag -l "*-elephant"
```

### Backup Branches
```bash
# Before upgrade
git checkout -b backup-20251105

# After successful upgrade
git checkout develop
git merge backup-20251105  # If needed
```

## Testing Upgrades

### Pre-Upgrade Checklist
- [ ] Read upstream release notes
- [ ] Check for breaking changes
- [ ] Backup database
- [ ] Create Git backup branch
- [ ] Document current version
- [ ] Test in development environment

### Post-Upgrade Verification
```bash
# Health check
curl http://localhost:8080/healthz

# Database connection
docker-compose exec postgres psql -U uaauser -d uaa -c "SELECT count(*) FROM users;"

# OAuth token test
curl -X POST http://localhost:8080/oauth/token \
  -u "app:appclientsecret" \
  -d "grant_type=password&username=admin&password=adminsecret"

# SAML certificate check
openssl x509 -in app/saml.crt -text -noout | grep "Subject:"
# Should show: Elephant Insurance details

# View logs
docker-compose logs uaa --tail 100
```

## Rollback Procedures

### Database Rollback
```bash
./uaa-upgrade/scripts/restore-database.sh backups/database/uaa_backup_YYYYMMDD_HHMMSS.sql.gz
```

### Code Rollback
```bash
# Option 1: Git reset
git reset --hard backup-20251105

# Option 2: Restore from backup branch
git checkout backup-20251105
git checkout -b develop-restored
```

## Documentation Updates

### After Each Upgrade
Update `CUSTOMIZATIONS.md`:
```markdown
## Upgrade History
- 2025-11-05: Upgraded to v78.5.0
  - Preserved: config/uaa.yml, app/ keys
  - Changed: Updated dependencies
  - Issues: None
```

## Related Documentation

- Main instructions: `.github/copilot-instructions.md`
- Setup instructions: `uaa-setup/.github/copilot-instructions.md`
- Config instructions: `config/.github/copilot-instructions.md`
- Project structure: `PROJECT-STRUCTURE.md`

## When Adding Upgrade Features

1. Update `UPGRADE-GUIDE.md` with new procedures
2. Update `upgrade-uaa.sh` if automating new steps
3. Test upgrade path thoroughly
4. Document in `CUSTOMIZATIONS.md`
5. Provide rollback procedures
6. Update version compatibility notes
