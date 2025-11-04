# GitHub Copilot Instructions for UAA Project

You are working on a CloudFoundry UAA (User Account and Authentication) installation with **specific customizations for Elephant Insurance**. Follow these guidelines strictly when suggesting code, making changes, or answering questions.

## Project Overview

- **Project**: CloudFoundry UAA
- **Organization**: Elephant Insurance
- **Location**: Henrico, Virginia, USA
- **Purpose**: Authentication and authorization service
- **Version**: Based on CloudFoundry UAA (check gradle.properties for current version)

## Critical Customizations - NEVER CHANGE

### 1. SAML Certificate Details (Elephant Insurance)
When working with SAML certificates or generating new keys, ALWAYS use these organization details:

```
C  = US
ST = Virginia
L  = Henrico
O  = Elephant Insurance
OU = Digital Development
CN = elephant.com
```

**Files**: `app/saml.crt`, `app/saml.key`
**Script**: `uaa-setup/scripts/generate-uaa-keys.sh`

### 2. Database Configuration
- **Database Type**: PostgreSQL 18 (running on local machine, NOT in Docker)
- **Database Name**: `uaa`
- **Database User**: `uaauser` (NOT postgres superuser)
- **Database Password**: `uaapassword`
- **Host**: localhost (from host machine), host.docker.internal (from UAA container)
- **Port**: 5432

**Configuration**: `config/uaa.yml`
**Never suggest** using the `postgres` superuser directly.

**Note**: PostgreSQL runs natively on the host machine. The UAA application runs in Docker and connects to PostgreSQL via `host.docker.internal`.

### 3. File Organization

#### Setup & Operations → `uaa-setup/`
- Documentation: `uaa-setup/docs/`
- Scripts: `uaa-setup/scripts/`
  - `generate-uaa-keys.sh` - Generate SAML/JWT keys
  - `setup-database.sh` - Database setup
  - `run-uaa-locally.sh` - Run without Docker
  - `cleanup.sh` - Clean temporary files

#### Upgrade & Maintenance → `uaa-upgrade/`
- Documentation: `uaa-upgrade/docs/`
- Scripts: `uaa-upgrade/scripts/`
  - `upgrade-uaa.sh` - Main upgrade script
  - `backup-database.sh` - Database backup
  - `restore-database.sh` - Database restore

#### Keys & Certificates → `app/`
All cryptographic keys and certificates go here:
- `saml.crt`, `saml.key` - SAML SP keys
- `jwt_key.pem`, `jwt_key_rsa.pem`, `jwt_pub.pem` - JWT signing keys

**Never suggest** putting keys in the root directory or any other location.

### 4. Docker Configuration
- **File**: `docker-compose.yml`
- **Simplified**: Only essential environment variables
  - `SPRING_PROFILES_ACTIVE`
  - `JAVA_OPTS`
- **Database env vars removed** - All in `config/uaa.yml`
- **No `.env` file** - Deleted intentionally

### 5. Script Conventions

#### Auto-Path Detection
All scripts MUST include auto-path detection to work from any directory:

```bash
# For scripts in uaa-setup/scripts/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UAA_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# For scripts in uaa-upgrade/scripts/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UAA_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
```

#### Cross-Platform Support
Provide both `.sh` (Bash) and `.bat` (Windows CMD) versions for setup scripts.

#### Script Location Rules
- **Setup scripts** → `uaa-setup/scripts/`
- **Upgrade scripts** → `uaa-upgrade/scripts/`
- **Backup scripts** → `uaa-upgrade/scripts/`

## Code Style & Conventions

### Shell Scripts
- Use `#!/bin/bash` shebang
- Include colored output (GREEN, YELLOW, RED, BLUE, NC)
- Add clear section headers with echo statements
- Always include error handling with `set -e`
- Provide helpful error messages
- Add confirmation prompts for destructive operations

### YAML Files
- Use 2-space indentation
- Inline secrets are acceptable for development (document security concerns)
- Use environment variable fallbacks: `${VAR:default}`

### Documentation
- Use Markdown format
- Include emojis for visual navigation (📦, 🚀, ⭐, etc.)
- Provide both quick start and detailed guides
- Always include examples
- Cross-reference related documentation

## Configuration Management

### Single Source of Truth
`config/uaa.yml` is the PRIMARY configuration file. All settings should be here, not in:
- `.env` files (deleted)
- `docker-compose.yml` environment variables (minimal only)
- Hardcoded values

### Environment Variables
When suggesting environment variables in `config/uaa.yml`, use this pattern:
```yaml
DATABASE_USERNAME=${DATABASE_USERNAME:uaauser}
DATABASE_PASSWORD=${DATABASE_PASSWORD:uaapassword}
```

### Secrets Handling
- Keys and certificates are embedded inline in `config/uaa.yml`
- UAA architecture requires this (cannot use file references)
- Private files go in `app/` directory
- Add `.gitignore` entries for sensitive files

## Directory Structure Rules

```
uaa/
├── app/                    # Keys & certs ONLY
├── config/                 # Configuration ONLY
│   └── uaa.yml
├── uaa-setup/             # Initial setup & operations
│   ├── docs/
│   └── scripts/
├── uaa-upgrade/           # Upgrades & maintenance
│   ├── docs/
│   └── scripts/
├── backups/               # Database backups
│   └── database/
└── docker-compose.yml     # Docker orchestration
```

**Never suggest** putting files in wrong directories.

## Upgrade Strategy

### Before Suggesting Upgrades
1. Always recommend backing up first
2. Reference `uaa-upgrade/scripts/upgrade-uaa.sh`
3. Mention the backup branch creation
4. Warn about potential breaking changes

### Preserve During Upgrades
These MUST be preserved:
- `config/uaa.yml` - All configuration
- `app/` - All keys and certificates
- `uaa-setup/` - All setup resources
- `uaa-upgrade/` - All upgrade resources
- `docker-compose.yml` - Docker configuration
- Database volume data

### Version Strategy
- Use Git tags for version management
- Create backup branches before upgrades
- Test upgrades in development first

## Common Pitfalls to Avoid

### ❌ DON'T Suggest:
1. Using `postgres` user instead of `uaauser`
2. Putting keys in root directory
3. Creating `.env` files
4. Hardcoding secrets without environment variable fallbacks
5. Putting database credentials in `docker-compose.yml`
6. Using file references for SAML/JWT keys (UAA requires inline)
7. Creating backup files without timestamps
8. Mixing setup and upgrade scripts in same directory
9. Generic SAML certificates (must use Elephant Insurance details)
10. Scripts without auto-path detection

### ✅ DO Suggest:
1. Using `uaauser` for database operations
2. Putting all keys in `app/` directory
3. Consolidating config in `config/uaa.yml`
4. Environment variables with defaults
5. Cross-platform scripts (.sh and .bat)
6. Auto-path detection in all scripts
7. Timestamped backups
8. Separate upgrade functionality in `uaa-upgrade/`
9. Elephant Insurance org details in certificates
10. Colored output and clear error messages

## Testing & Verification

### After Any Changes, Suggest:
```bash
# Health check
curl http://localhost:8080/healthz

# Database connection
docker-compose exec postgres psql -U uaauser -d uaa -c "SELECT count(*) FROM users;"

# SAML certificate verification
openssl x509 -in app/saml.crt -text -noout | grep "Subject:"
# Should show: C=US, ST=Virginia, L=Henrico, O=Elephant Insurance...

# OAuth token test
curl -X POST http://localhost:8080/oauth/token \
  -u "app:appclientsecret" \
  -d "grant_type=password&username=admin&password=adminsecret"

# View logs
docker-compose logs -f uaa
```

## Documentation References

When answering questions, reference these docs:
- Setup: `uaa-setup/docs/README-UAA-SETUP.md`
- Quick ref: `uaa-setup/docs/QUICK-REFERENCE.md`
- Upgrade: `uaa-upgrade/docs/UPGRADE-QUICK-SUMMARY.md`
- Customizations: `uaa-upgrade/docs/CUSTOMIZATIONS.md`
- Project structure: `PROJECT-STRUCTURE.md`

## Security Considerations

### Always Remind About:
1. `.gitignore` entries for sensitive files
2. Different credentials for prod/dev/staging
3. Certificate expiration (365 days for self-signed)
4. Regular database backups
5. Testing before production deployment

### Sensitive Files (Never Commit to Public Repos):
- `config/uaa.yml` - Contains passwords, keys
- `app/saml.key` - SAML private key
- `app/jwt_key_rsa.pem` - JWT signing key
- `backups/` - Database dumps

## Java & Spring Boot Context

- **Java Version**: 21
- **Spring Boot Version**: 3.5.7 (check gradle.properties)
- **Gradle Version**: 9.2.0
- **Lombok**: Used extensively (suggest IDE annotation processing)
- **Database Migrations**: Flyway (automatic on startup)

## When Suggesting Code Changes

### For Test Files
- Respect existing test patterns
- UAA uses JUnit 5 (Jupiter)
- MockMvc for integration tests
- Follow existing naming conventions

### For Configuration
- Preserve existing structure
- Add comments for Elephant Insurance customizations
- Use YAML anchors/references when appropriate
- Maintain environment variable fallbacks

### For Scripts
- Follow existing color scheme
- Include progress indicators
- Add confirmation for destructive operations
- Provide rollback instructions

## Special Notes

### Lombok Issues
If IDE shows errors like "method not found" for Lombok classes:
```bash
./gradlew clean build -x test
# Then refresh IDE caches
```

### Path References
Always use:
- Absolute paths in scripts after auto-detection
- Relative paths in documentation
- Forward slashes in paths (works on Windows Git Bash)

### Backup Strategy
- Automatic: Created by `upgrade-uaa.sh`
- Manual: Use `backup-database.sh`
- Retention: Keep last 10 backups
- Compression: Always gzip SQL dumps

## Directory-Specific Instructions

For detailed guidelines specific to each directory, see:

- **`app/`** - Keys & Certificates: `.github/instructions/app.instructions.md`
- **`config/`** - Configuration: `.github/instructions/config.instructions.md`
- **`uaa-setup/`** - Setup & Operations: `.github/instructions/uaa-setup.instructions.md`
- **`uaa-upgrade/`** - Upgrades & Maintenance: `.github/instructions/uaa-upgrade.instructions.md`

These files contain context-specific rules, examples, and best practices for working in each area.

## Summary

This is a **production-ready UAA setup** with enterprise-grade organization and automation. When making suggestions:

1. ✅ Maintain Elephant Insurance branding in certificates
2. ✅ Keep organized directory structure
3. ✅ Use dedicated database user (uaauser)
4. ✅ Follow script conventions (auto-path, colors, error handling)
5. ✅ Reference appropriate documentation
6. ✅ Suggest backups before changes
7. ✅ Test suggestions with provided verification commands
8. ✅ Respect the separation of setup vs upgrade concerns
9. ✅ Consult directory-specific instructions when working in specialized areas

**When in doubt, preserve the existing patterns and organization.**
