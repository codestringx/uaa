# UAA Version Upgrade - Quick Summary

## When a New UAA Version is Released

### Option 1: Automated Upgrade (Recommended)
```bash
# 1. Run the upgrade script
./uaa-upgrade/scripts/upgrade-uaa.sh <version>

# Example:
./uaa-upgrade/scripts/upgrade-uaa.sh 77.0.0
```

The script will:
- ✅ Create automatic backups
- ✅ Fetch the new version
- ✅ Merge changes
- ✅ Build and test
- ✅ Preserve all your customizations

### Option 2: Manual Upgrade
```bash
# 1. Backup database
./uaa-upgrade/scripts/backup-database.sh

# 2. Create backup branch
git checkout -b backup-before-upgrade
git add -A && git commit -m "Backup before upgrade"

# 3. Fetch and merge new version
git remote add upstream https://github.com/cloudfoundry/uaa.git
git fetch upstream --tags
git merge v77.0.0  # Replace with desired version

# 4. Resolve any conflicts (if needed)

# 5. Rebuild
./gradlew clean build -x test

# 6. Restart
docker-compose down
docker-compose up -d
```

## What Gets Preserved Automatically

Your customizations are safe because they're in:

1. **config/uaa.yml** - Your custom configuration
2. **app/** - All your certificates and keys
   - SAML cert with Elephant Insurance details
   - JWT signing keys
3. **uaa-setup/** - All your scripts and documentation
4. **docker-compose.yml** - Your Docker setup
5. **Database** - PostgreSQL data (in Docker volume)

## Files That Should NEVER Be Lost

### Critical Files (Keep These!)
```
config/uaa.yml                    # Main configuration
app/saml.key                      # SAML private key
app/saml.crt                      # SAML certificate
app/jwt_key_rsa.pem              # JWT signing key
docker-compose.yml                # Docker setup
uaa-setup/                        # All scripts and docs
```

### How to Protect Them
Add to `.gitignore`:
```bash
cat .gitignore.custom >> .gitignore
```

## After Upgrading - Verification

### 1. Check UAA Health
```bash
curl http://localhost:8080/healthz
# Should return: {"status":"UP"}
```

### 2. Verify Database
```bash
docker-compose exec postgres psql -U uaauser -d uaa -c "SELECT count(*) FROM users;"
```

### 3. Check SAML Certificate
```bash
openssl x509 -in app/saml.crt -text -noout | grep "Subject:"
# Should show: C=US, ST=Virginia, L=Henrico, O=Elephant Insurance...
```

### 4. Test Token Generation
```bash
curl -X POST http://localhost:8080/oauth/token \
  -u "app:appclientsecret" \
  -d "grant_type=password&username=admin&password=adminsecret"
```

## If Something Goes Wrong

### Quick Rollback
```bash
# 1. Stop services
docker-compose down

# 2. Restore from backup branch
git checkout backup-before-upgrade

# 3. Restore database (if needed)
./uaa-upgrade/scripts/restore-database.sh backups/database/uaa_backup_*.sql.gz

# 4. Restart
docker-compose up -d
```

## Common Upgrade Scenarios

### Scenario 1: Minor Version Update (e.g., 76.5 → 76.6)
- Usually safe
- Run automated upgrade script
- Test and verify
- Done! ✅

### Scenario 2: Major Version Update (e.g., 76.x → 77.x)
1. Read release notes carefully
2. Check for breaking changes
3. Backup everything
4. Run upgrade script
5. Test thoroughly
6. May need config adjustments

### Scenario 3: Config Format Changes
If `config/uaa.yml` format changes:
```bash
# Compare your config with new template
diff config/uaa.yml config/uaa.yml.template

# Merge manually
# Keep your database credentials, keys, etc.
# Update format to match new template
```

## Maintenance Schedule

### Monthly
- Check for new UAA releases
- Review security updates

### Quarterly  
- Backup database: `./uaa-upgrade/scripts/backup-database.sh`
- Test restore procedure

### Yearly
- Regenerate SAML certificates (expire after 365 days)
- Review and update documentation

## Quick Reference

### Important Locations
| What | Where |
|------|-------|
| Configuration | `config/uaa.yml` |
| Keys/Certs | `app/` |
| Scripts | `uaa-upgrade/scripts/` |
| Docs | `uaa-setup/docs/` |
| Backups | `backups/database/` |

### Important Scripts
| Script | Purpose |
|--------|---------|
| `upgrade-uaa.sh` | Upgrade to new version |
| `backup-database.sh` | Backup PostgreSQL |
| `restore-database.sh` | Restore from backup |
| `generate-uaa-keys.sh` | Regenerate keys/certs |
| `setup-database.sh` | Setup database user |

### Important Commands
```bash
# Start UAA
docker-compose up -d

# Stop UAA
docker-compose down

# View logs
docker-compose logs -f uaa

# Rebuild
./gradlew clean build -x test

# Database backup
./uaa-upgrade/scripts/backup-database.sh
```

## Getting Help

1. **Check Documentation:**
   - Setup Guide: `uaa-setup/docs/README-UAA-SETUP.md`
   - Upgrade Guide: `uaa-setup/docs/UPGRADE-GUIDE.md`
   - Customizations: `uaa-setup/docs/CUSTOMIZATIONS.md`

2. **Review Logs:**
   ```bash
   docker-compose logs uaa
   docker-compose logs postgres
   ```

3. **Official Resources:**
   - UAA Docs: https://docs.cloudfoundry.org/uaa/
   - GitHub: https://github.com/cloudfoundry/uaa
   - Releases: https://github.com/cloudfoundry/uaa/releases

## Remember

✅ **Always backup before upgrading**
✅ **Test in development first**
✅ **Keep your customizations documented**
✅ **Use version control (Git)**
✅ **Monitor logs after upgrade**

Your setup is well-organized and upgrade-friendly! 🚀
