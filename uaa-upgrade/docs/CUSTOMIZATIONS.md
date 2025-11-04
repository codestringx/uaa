# UAA Customizations Documentation

This document tracks all customizations made to the CloudFoundry UAA installation. Keep this updated whenever you make changes.

## Overview

This UAA instance has been customized for Elephant Insurance with specific configurations, certificates, and database setup.

**Last Updated:** $(date +%Y-%m-%d)
**UAA Version:** Check with `git describe --tags` or see `gradle.properties`
**Installation Location:** /d/Workspace/Java/uaa

---

## 1. Database Configuration

### PostgreSQL Setup
- **Database Name:** `uaa`
- **Database User:** `uaauser` (not the postgres superuser)
- **Database Password:** `uaapassword`
- **Database Host:** `localhost` (via Docker)
- **Database Port:** `5432`

### Configuration File Location
- `config/uaa.yml` - Contains database connection details
- Uses default values with environment variable fallbacks:
  ```yaml
  DATABASE_USERNAME=${DATABASE_USERNAME:uaauser}
  DATABASE_PASSWORD=${DATABASE_PASSWORD:uaapassword}
  ```

### Setup Scripts
- `uaa-setup/scripts/setup-database.sh` - Automates PostgreSQL user/database creation
- `uaa-setup/scripts/setup-database.bat` - Windows version

---

## 2. SAML Configuration

### SAML Service Provider Certificate
- **Location:** `app/saml.crt` (public certificate)
- **Private Key:** `app/saml.key`
- **Key Type:** RSA 2048-bit
- **Validity:** 365 days
- **Self-Signed:** Yes

### Certificate Subject Details (Elephant Insurance)
```
C  = US
ST = Virginia
L  = Henrico
O  = Elephant Insurance
OU = Digital Development
CN = elephant.com
```

### Configuration in UAA
- Embedded in `config/uaa.yml` under `login.saml.keys.key1`
- UAA requires **inline** certificate/key content (cannot use file references)

### Generation Script
- `uaa-setup/scripts/generate-uaa-keys.sh` - Linux/Mac/Git Bash
- `uaa-setup/scripts/generate-uaa-keys.bat` - Windows CMD
- Both scripts auto-detect UAA root and generate keys with Elephant Insurance details

---

## 3. JWT Signing Keys

### RSA Keys for OAuth2/OIDC
- **Location:** `app/` directory
  - `jwt_key.pem` - Legacy format
  - `jwt_key_rsa.pem` - RSA private key (used by UAA)
  - `jwt_pub.pem` - RSA public key

### Configuration
- Private key content embedded in `config/uaa.yml` under `jwt.token.signing-key`
- Generated using same scripts as SAML keys

---

## 4. Docker Configuration

### Docker Compose Setup
- **File:** `docker-compose.yml`
- **Simplified:** Only essential environment variables
  - `SPRING_PROFILES_ACTIVE=default,hsqldb` (or `postgresql` in production)
  - `JAVA_OPTS=-Djava.security.egd=file:/dev/./urandom`

### Services
1. **postgres** - PostgreSQL 18
   - Volume: `postgres_data` (persistent)
   - Port: 5432:5432

2. **uaa** - UAA Server
   - Build from local Dockerfile
   - Port: 8080:8080
   - Config mounted from `./config/uaa.yml`
   - Depends on postgres

### Environment Variables
- **Removed redundant vars:** Database settings now only in `config/uaa.yml`
- **Deleted:** `.env` file (was outdated)

---

## 5. Project Structure Customizations

### Directory Organization
```
uaa/
├── app/                          # Certificates and keys (CUSTOM)
│   ├── saml.crt
│   ├── saml.key
│   ├── jwt_key.pem
│   ├── jwt_key_rsa.pem
│   └── jwt_pub.pem
├── config/                       # Configuration (CUSTOMIZED)
│   └── uaa.yml
├── uaa-setup/                    # Custom setup resources (CUSTOM)
│   ├── docs/                     # All documentation
│   │   ├── README-UAA-SETUP.md
│   │   ├── QUICK-REFERENCE.md
│   │   ├── UPGRADE-GUIDE.md
│   │   └── CUSTOMIZATIONS.md (this file)
│   └── scripts/                  # All automation scripts
│       ├── generate-uaa-keys.sh
│       ├── generate-uaa-keys.bat
│       ├── setup-database.sh
│       ├── setup-database.bat
│       ├── run-uaa-locally.sh
│       ├── run-uaa-locally.bat
│       ├── cleanup.sh
│       ├── backup-database.sh
│       ├── restore-database.sh
│       └── upgrade-uaa.sh
├── backups/                      # Database backups (CUSTOM)
│   └── database/
└── docker-compose.yml            # Docker orchestration (CUSTOMIZED)
```

### Script Features
- **Auto-path detection:** All scripts detect UAA root automatically
- **Can run from anywhere:** No need to be in specific directory
- **Cross-platform:** Both .sh (Bash) and .bat (Windows) versions

---

## 6. Configuration Files

### config/uaa.yml
**Customized sections:**

1. **Database Settings** (lines ~20-30)
   ```yaml
   DATABASE_USERNAME=${DATABASE_USERNAME:uaauser}
   DATABASE_PASSWORD=${DATABASE_PASSWORD:uaapassword}
   ```

2. **SAML Keys** (lines ~200-250)
   - Embedded SAML certificate with Elephant Insurance organization
   - Private key content inline

3. **JWT Token Settings** (lines ~100-150)
   - Custom RSA signing key
   - Token validity periods

### docker-compose.yml
**Customizations:**
- Simplified environment variables
- PostgreSQL 18 instead of default version
- Custom volume mount for `config/uaa.yml`
- All keys/certs accessed from `app/` directory

---

## 7. Removed/Cleaned Files

### Deleted Files
- `.env` - Contained outdated postgres credentials
- `config/uaa.yml.backup.*` - Old backup files
- `UAA-Setup-Guide.md` - Replaced with structured docs in uaa-setup/
- Root `jwt_key*.pem` - Moved to `app/` folder
- Root `run-uaa.sh/bat` - Moved to `uaa-setup/scripts/run-uaa-locally.sh/bat`

### Reason for Cleanup
- Single source of truth for configuration
- Better organization
- Eliminate duplication
- Clearer project structure

---

## 8. Security Considerations

### Secrets Management
⚠️ **IMPORTANT:** The following files contain sensitive data:
- `config/uaa.yml` - Database passwords, signing keys
- `app/saml.key` - SAML private key
- `app/jwt_key_rsa.pem` - JWT signing key

**Recommendations:**
1. **Do NOT commit** these files to public repositories
2. Use `.gitignore` to exclude sensitive files
3. Store secrets in environment variables or secret management system for production
4. Use different keys/passwords for dev/staging/production

### Current State
- Keys are self-signed (suitable for development)
- Database password is simple (change for production)
- All secrets are in plain text in config files

---

## 9. Integration Points

### SAML Integration
- SP Entity ID: Configured in `config/uaa.yml`
- Metadata endpoint: `http://localhost:8080/saml/metadata`
- Certificate: Contains Elephant Insurance organization details

### OAuth2/OIDC
- Token endpoint: `http://localhost:8080/oauth/token`
- Authorization endpoint: `http://localhost:8080/oauth/authorize`
- JWK Set endpoint: `http://localhost:8080/token_keys`

---

## 10. Maintenance Notes

### Regular Tasks
1. **Backup Database:** Run `./uaa-upgrade/scripts/backup-database.sh` before major changes
2. **Regenerate Certificates:** SAML cert expires after 365 days
3. **Update Dependencies:** Check for UAA updates monthly
4. **Review Logs:** Monitor `docker-compose logs uaa` for issues

### Certificate Renewal
When SAML certificate expires:
```bash
./uaa-setup/scripts/generate-uaa-keys.sh
# Review changes in config/uaa.yml
docker-compose restart uaa
```

### Database Maintenance
```bash
# Backup
./uaa-upgrade/scripts/backup-database.sh

# Restore
./uaa-upgrade/scripts/restore-database.sh backups/database/uaa_backup_YYYYMMDD_HHMMSS.sql.gz

# Vacuum (optimize)
docker-compose exec postgres psql -U uaauser -d uaa -c "VACUUM ANALYZE;"
```

---

## 11. Testing Checklist

After any changes, verify:

1. **UAA Health:**
   ```bash
   curl http://localhost:8080/healthz
   ```

2. **Database Connection:**
   ```bash
   docker-compose exec postgres psql -U uaauser -d uaa -c "SELECT version();"
   ```

3. **SAML Certificate:**
   ```bash
   openssl x509 -in app/saml.crt -text -noout | grep "Subject:"
   ```

4. **OAuth Token Generation:**
   ```bash
   curl -X POST http://localhost:8080/oauth/token \
     -u "app:appclientsecret" \
     -d "grant_type=password&username=admin&password=adminsecret"
   ```

5. **JWT Signature:**
   ```bash
   curl http://localhost:8080/token_keys
   ```

---

## 12. Upgrade Strategy

See `uaa-upgrade/docs/UPGRADE-GUIDE.md` for detailed upgrade instructions.

### Quick Upgrade Process
```bash
# 1. Backup
./uaa-upgrade/scripts/backup-database.sh

# 2. Run upgrade script
./uaa-upgrade/scripts/upgrade-uaa.sh <version>

# 3. Test thoroughly
```

### Files to Preserve During Upgrade
- `config/uaa.yml`
- `app/` directory (all keys/certs)
- `uaa-setup/` directory (all custom scripts/docs)
- `docker-compose.yml`
- Database volume data

---

## 13. Troubleshooting Common Issues

### Issue: IDE Shows Error on `result.setOrigin()`
**Solution:** This is a Lombok annotation processing issue
```bash
./gradlew clean build -x test
# Then refresh/invalidate IDE caches
```

### Issue: Database Connection Failed
**Solution:** Check credentials and ensure postgres is running
```bash
docker-compose up -d postgres
docker-compose logs postgres
```

### Issue: SAML Certificate Expired
**Solution:** Regenerate with generate-uaa-keys.sh
```bash
./uaa-setup/scripts/generate-uaa-keys.sh
docker-compose restart uaa
```

---

## 14. Contact & Support

### Internal Resources
- Setup Guide: `uaa-upgrade/docs/README-UAA-SETUP.md`
- Quick Reference: `uaa-upgrade/docs/QUICK-REFERENCE.md`
- Upgrade Guide: `uaa-upgrade/docs/UPGRADE-GUIDE.md`

### External Resources
- Official UAA Docs: https://docs.cloudfoundry.org/uaa/
- GitHub Repository: https://github.com/cloudfoundry/uaa
- Issues: https://github.com/cloudfoundry/uaa/issues

---

## Change Log

### 2024-11-05
- Initial setup with Elephant Insurance customizations
- Created custom directory structure (uaa-setup/)
- Moved all keys to app/ folder
- Simplified docker-compose.yml
- Changed database to uaauser/uaapassword
- Removed .env file
- Added comprehensive documentation

### Future Changes
Document all future customizations here with date and description.

---

**Note:** Keep this document updated whenever you make changes to the UAA installation. This will be invaluable during upgrades and troubleshooting.
