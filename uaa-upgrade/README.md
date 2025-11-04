# UAA Upgrade Resources

This directory contains all documentation and scripts for upgrading UAA to new versions while preserving your customizations and database.

## Directory Structure

```
uaa-upgrade/
├── docs/                           # Upgrade documentation
│   ├── UPGRADE-QUICK-SUMMARY.md   # Quick upgrade reference ⭐ START HERE
│   ├── UPGRADE-GUIDE.md           # Detailed version upgrade guide
│   └── CUSTOMIZATIONS.md          # Track all your customizations
│
└── scripts/                        # Upgrade automation scripts
    ├── upgrade-uaa.sh             # Automated upgrade script ⭐ MAIN SCRIPT
    ├── backup-database.sh         # Database backup
    └── restore-database.sh        # Database restore
```

## Quick Start - Upgrading UAA

### When a New Version is Released

**Simple 2-Step Process:**

```bash
# Step 1: Run upgrade script with target version
./uaa-upgrade/scripts/upgrade-uaa.sh 77.0.0

# Step 2: Test and verify
curl http://localhost:8080/healthz
```

### What the Upgrade Script Does

✅ Creates automatic backups (Git + Database)  
✅ Fetches the new UAA version  
✅ Merges changes intelligently  
✅ Preserves ALL your customizations  
✅ Builds and tests the new version  
✅ Restarts UAA with new code  
✅ Verifies health and database connection  

## Your Customizations Are Protected

These files are automatically preserved during upgrades:

- **`config/uaa.yml`** - Database credentials, SAML keys, JWT keys
- **`app/`** - All certificates with Elephant Insurance details
- **`uaa-setup/`** - All setup scripts and documentation
- **`docker-compose.yml`** - Docker configuration
- **Database volume** - All user data in PostgreSQL

## Common Upgrade Scenarios

### Scenario 1: Minor Update (e.g., 77.0 → 77.1)
```bash
./uaa-upgrade/scripts/upgrade-uaa.sh 77.1.0
# Usually seamless, minimal changes
```

### Scenario 2: Major Update (e.g., 76.x → 77.x)
```bash
# 1. Read release notes first
# 2. Run upgrade
./uaa-upgrade/scripts/upgrade-uaa.sh 77.0.0

# 3. Test thoroughly
curl http://localhost:8080/healthz
docker-compose logs uaa
```

### Scenario 3: Upgrade to Latest Development Version
```bash
./uaa-upgrade/scripts/upgrade-uaa.sh latest
```

## Backup & Restore

### Create Backup Before Upgrade (Automatic)
The upgrade script creates backups automatically, but you can also create manual backups:

```bash
# Backup database
./uaa-upgrade/scripts/backup-database.sh

# Output: backups/database/uaa_backup_YYYYMMDD_HHMMSS.sql.gz
```

### Restore from Backup (If Needed)
```bash
# List available backups
ls -lh backups/database/

# Restore specific backup
./uaa-upgrade/scripts/restore-database.sh backups/database/uaa_backup_20241105_143022.sql.gz
```

### Git Rollback (If Upgrade Fails)
```bash
# The upgrade script creates a backup branch
git checkout backup-before-v77.0.0-20241105_143022

# Restart services
docker-compose up -d
```

## Verification After Upgrade

### 1. Check UAA Health
```bash
curl http://localhost:8080/healthz
# Expected: {"status":"UP"}
```

### 2. Verify Database Connection
```bash
docker-compose exec postgres psql -U uaauser -d uaa -c "SELECT count(*) FROM users;"
```

### 3. Check SAML Certificate (Elephant Insurance)
```bash
openssl x509 -in app/saml.crt -text -noout | grep "Subject:"
# Expected: C=US, ST=Virginia, L=Henrico, O=Elephant Insurance, OU=Digital Development, CN=elephant.com
```

### 4. Test OAuth Token Generation
```bash
curl -X POST http://localhost:8080/oauth/token \
  -u "app:appclientsecret" \
  -d "grant_type=password&username=admin&password=adminsecret"
```

### 5. Review Logs
```bash
docker-compose logs -f uaa
```

## Documentation

### Start Here
- **[UPGRADE-QUICK-SUMMARY.md](docs/UPGRADE-QUICK-SUMMARY.md)** - Quick reference guide ⭐

### Detailed Guides
- **[UPGRADE-GUIDE.md](docs/UPGRADE-GUIDE.md)** - Complete upgrade procedures
- **[CUSTOMIZATIONS.md](docs/CUSTOMIZATIONS.md)** - Track your customizations

## Troubleshooting

### Issue: Merge Conflicts During Upgrade
```bash
# View conflicting files
git diff --name-only --diff-filter=U

# Resolve manually, then:
git add <resolved-files>
git commit
./gradlew clean build -x test
docker-compose up -d
```

### Issue: Build Fails After Upgrade
```bash
# Clean and rebuild
./gradlew clean
rm -rf build/ */build/
./gradlew build -x test
```

### Issue: UAA Won't Start
```bash
# Check logs
docker-compose logs uaa

# Check database
docker-compose logs postgres

# Rollback if needed
git checkout backup-before-v<version>-<timestamp>
docker-compose up -d
```

### Issue: Database Migration Failed
```bash
# Check migration history
docker-compose exec postgres psql -U uaauser -d uaa -c "SELECT * FROM flyway_schema_history ORDER BY installed_rank DESC LIMIT 5;"

# If needed, restore from backup
./uaa-upgrade/scripts/restore-database.sh <backup-file>
```

## Best Practices

### Before Upgrading
1. ✅ Read release notes for breaking changes
2. ✅ Backup database (automatic with upgrade script)
3. ✅ Test in development environment first
4. ✅ Document any manual changes needed

### During Upgrade
1. ✅ Use the automated upgrade script
2. ✅ Resolve conflicts carefully
3. ✅ Preserve your customizations
4. ✅ Build and test before restarting

### After Upgrade
1. ✅ Verify health endpoints
2. ✅ Test authentication flows
3. ✅ Monitor logs for errors
4. ✅ Update CUSTOMIZATIONS.md

## Maintenance Schedule

### Monthly
- Check for new UAA releases
- Review security updates
- Test backup/restore process

### Quarterly
- Create database backup
- Review and update documentation
- Clean old backups (keeps last 10)

### Yearly
- Regenerate SAML certificates (365-day expiry)
- Review all customizations
- Update dependencies

## Additional Resources

### Internal Documentation
- Setup Guide: `../uaa-setup/docs/README-UAA-SETUP.md`
- Quick Reference: `../uaa-setup/docs/QUICK-REFERENCE.md`

### Official UAA Resources
- UAA Documentation: https://docs.cloudfoundry.org/uaa/
- GitHub Repository: https://github.com/cloudfoundry/uaa
- Release Notes: https://github.com/cloudfoundry/uaa/releases

## Support

For issues or questions:
1. Check documentation in `docs/`
2. Review logs with `docker-compose logs`
3. Consult official UAA documentation
4. Check GitHub issues

---

**Your UAA setup is upgrade-ready!** 🚀

The automated scripts make upgrading safe and simple while preserving all your custom configurations and data.
