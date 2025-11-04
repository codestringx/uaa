# UAA Upgrade Guide

## Overview
This guide explains how to upgrade your UAA installation to a new version while preserving your custom configuration and database.

## Pre-Upgrade Checklist

### 1. Backup Current State
Before upgrading, always create backups:

```bash
# Backup database
cd /d/Workspace/Java/uaa
./uaa-upgrade/scripts/backup-database.sh

# Backup configuration files
cp config/uaa.yml config/uaa.yml.backup.$(date +%Y%m%d_%H%M%S)
cp -r app/ app.backup.$(date +%Y%m%d_%H%M%S)/

# Backup Docker volumes (if using Docker)
docker-compose down
docker run --rm -v uaa_postgres_data:/data -v $(pwd)/backups:/backup alpine tar czf /backup/postgres_data_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .
```

### 2. Document Your Customizations
Keep track of what you've customized:
- Database credentials (uaauser/uaapassword)
- SAML certificates (Elephant Insurance details)
- JWT signing keys
- Environment variables
- Docker Compose settings

### 3. Review Release Notes
Check the UAA release notes for:
- Breaking changes
- Database migration requirements
- Configuration format changes
- Deprecated features
- New dependencies

## Upgrade Methods

### Method 1: Git-Based Upgrade (Recommended)

#### Step 1: Check Current State
```bash
cd /d/Workspace/Java/uaa
git status
git branch
```

#### Step 2: Stash Your Changes
```bash
# Stash all local changes
git stash save "Local customizations before upgrade to vX.X.X"

# Or create a backup branch
git checkout -b backup-before-upgrade-$(date +%Y%m%d)
git add -A
git commit -m "Backup before upgrade to vX.X.X"
git checkout develop
```

#### Step 3: Fetch New Version
```bash
# Add upstream if not already added
git remote add upstream https://github.com/cloudfoundry/uaa.git

# Fetch latest tags
git fetch upstream --tags

# View available versions
git tag | sort -V | tail -n 10
```

#### Step 4: Merge or Rebase
```bash
# Option A: Merge new version
git merge vX.X.X

# Option B: Rebase (cleaner history)
git rebase vX.X.X

# Resolve conflicts if any
```

#### Step 5: Restore Your Customizations
```bash
# Apply stashed changes
git stash pop

# Or cherry-pick from backup branch
git cherry-pick <commit-hash>
```

### Method 2: Fresh Clone + Manual Migration

#### Step 1: Clone New Version
```bash
cd /d/Workspace/Java
git clone --branch vX.X.X https://github.com/cloudfoundry/uaa.git uaa-new
cd uaa-new
```

#### Step 2: Copy Your Custom Files
```bash
# Copy configuration
cp ../uaa/config/uaa.yml ./config/

# Copy certificates and keys
cp -r ../uaa/app/ ./app/

# Copy custom scripts
cp -r ../uaa/uaa-setup/ ./uaa-setup/

# Copy Docker setup
cp ../uaa/docker-compose.yml ./
```

#### Step 3: Review and Update Configurations
```bash
# Check if config format changed
diff ../uaa/config/uaa.yml.template ./config/uaa.yml.template

# Update if needed
```

### Method 3: Patch-Based Upgrade

#### Step 1: Download New Version
```bash
cd /d/Workspace/Java/uaa
wget https://github.com/cloudfoundry/uaa/archive/refs/tags/vX.X.X.tar.gz
tar -xzf vX.X.X.tar.gz
```

#### Step 2: Create Patch
```bash
# Compare and create patch
diff -Naur . ../uaa-vX.X.X > upgrade.patch
```

#### Step 3: Apply Patch Selectively
```bash
# Review patch
less upgrade.patch

# Apply (may require manual conflict resolution)
patch -p1 < upgrade.patch
```

## Post-Upgrade Steps

### 1. Update Dependencies
```bash
./gradlew clean build -x test
```

### 2. Check Configuration Compatibility
```bash
# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('config/uaa.yml'))"

# Or use yq if available
yq eval '.' config/uaa.yml > /dev/null && echo "Valid YAML"
```

### 3. Run Database Migrations
```bash
# UAA handles migrations automatically on startup
# But check migration logs
docker-compose up -d postgres
docker-compose logs postgres | grep -i migration
```

### 4. Test in Development
```bash
# Build and start
docker-compose build
docker-compose up -d

# Wait for startup
sleep 30

# Check health
curl http://localhost:8080/healthz

# Check login page
curl http://localhost:8080/login
```

### 5. Verify Customizations
```bash
# Check SAML certificate
openssl x509 -in app/saml.crt -text -noout | grep "Subject:"
# Should show: C=US, ST=Virginia, L=Henrico, O=Elephant Insurance...

# Check database connection
docker-compose exec postgres psql -U uaauser -d uaa -c "SELECT version();"

# Test login
curl -X POST http://localhost:8080/oauth/token \
  -u "app:appclientsecret" \
  -d "grant_type=password&username=admin&password=adminsecret"
```

## Handling Specific Scenarios

### Database Schema Changes
```bash
# UAA uses Flyway for migrations
# Migrations run automatically on startup
# Check migration status:
docker-compose logs uaa | grep -i flyway

# If migration fails, rollback:
docker-compose down
docker volume rm uaa_postgres_data
# Restore from backup
```

### Configuration Format Changes
```bash
# Compare old vs new config templates
diff config/uaa.yml config/uaa.yml.template.new

# Look for deprecated settings in release notes
# Update config/uaa.yml accordingly
```

### Breaking Changes
- Always read CHANGELOG.md and release notes
- Check for deprecated APIs
- Update custom code if you have any
- Test thoroughly before production

## Rollback Procedure

If upgrade fails:

### Quick Rollback
```bash
# Stop services
docker-compose down

# Restore from Git
git reset --hard backup-before-upgrade-YYYYMMDD

# Or restore from stash
git stash pop

# Restore database
./uaa-upgrade/scripts/restore-database.sh backups/backup_YYYYMMDD_HHMMSS.sql

# Restart
docker-compose up -d
```

## Best Practices

### 1. Version Control Your Customizations
- Keep `config/uaa.yml` in version control
- Track `app/` certificates in private repo
- Document all changes in `uaa-upgrade/docs/CUSTOMIZATIONS.md`

### 2. Use Feature Branches
```bash
git checkout -b upgrade-vX.X.X
# Do upgrade work
# Test thoroughly
git checkout develop
git merge upgrade-vX.X.X
```

### 3. Test Upgrades in Non-Production First
- Use separate Docker Compose profile for testing
- Test with production-like data
- Verify all integrations work

### 4. Automate Testing
```bash
# Run unit tests
./gradlew test

# Run integration tests
./uaa-upgrade/scripts/run-integration-tests.sh
```

### 5. Monitor After Upgrade
```bash
# Watch logs for errors
docker-compose logs -f uaa

# Check metrics
curl http://localhost:8080/metrics

# Monitor database connections
docker-compose exec postgres psql -U uaauser -d uaa -c "SELECT count(*) FROM pg_stat_activity;"
```

## Troubleshooting

### Issue: Build Fails After Upgrade
```bash
# Clean everything
./gradlew clean
rm -rf build/ */build/

# Update Gradle wrapper if needed
./gradlew wrapper --gradle-version=9.2.0

# Rebuild
./gradlew build -x test
```

### Issue: Database Migration Fails
```bash
# Check migration status
docker-compose exec postgres psql -U uaauser -d uaa -c "SELECT * FROM flyway_schema_history ORDER BY installed_rank DESC LIMIT 5;"

# If needed, manually fix and mark as repaired
# (Consult Flyway documentation)
```

### Issue: Configuration Not Recognized
```bash
# Check for renamed properties in release notes
grep -r "DEPRECATED" CHANGELOG.md

# Update config/uaa.yml with new property names
```

## Automation Scripts

### Create Backup Script
See: `uaa-upgrade/scripts/backup-database.sh`

### Create Upgrade Script
See: `uaa-upgrade/scripts/upgrade-uaa.sh`

### Create Rollback Script
See: `uaa-upgrade/scripts/rollback-upgrade.sh`

## Version-Specific Notes

### Upgrading from 4.x to 75.x+
- Major Spring Boot version change
- Database migration required
- Check LDAP configuration changes
- SAML configuration may need updates

### Upgrading from 76.x to 77.x+
- Minor updates
- Usually backward compatible
- Check release notes for specifics

## Resources

- Official UAA Releases: https://github.com/cloudfoundry/uaa/releases
- Migration Guide: https://docs.cloudfoundry.org/uaa/
- Breaking Changes: Check CHANGELOG.md in each release

## Your Custom Setup Preservation

Your setup includes:
1. **Database**: PostgreSQL with uaauser/uaapassword
2. **SAML Keys**: Elephant Insurance organization details in app/
3. **JWT Keys**: Custom signing keys in app/
4. **Scripts**: All in uaa-upgrade/scripts/
5. **Documentation**: All in uaa-upgrade/docs/
6. **Docker Setup**: Custom docker-compose.yml with minimal env vars

Always preserve:
- `config/uaa.yml`
- `app/` directory (all keys/certs)
- `uaa-setup/` directory
- `docker-compose.yml`
- Database data (PostgreSQL volume)
