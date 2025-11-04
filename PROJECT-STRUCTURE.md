# UAA Project Structure - Overview

This UAA installation is organized into clear functional areas for easy management and upgrades.

## Directory Organization

```
uaa/
├── uaa-setup/                      📦 Initial Setup & Daily Operations
│   ├── docs/                       # Setup documentation
│   │   ├── README-UAA-SETUP.md    # Complete setup guide
│   │   ├── QUICK-REFERENCE.md     # Command cheat sheet
│   │   └── DOCUMENTATION-INDEX.md # Find docs by use case
│   └── scripts/                    # Setup & operation scripts
│       ├── generate-uaa-keys.sh   # Generate SAML/JWT keys
│       ├── setup-database.sh      # Database setup
│       ├── run-uaa-locally.sh     # Run UAA with Gradle
│       └── cleanup.sh             # Project cleanup
│
├── uaa-upgrade/                    🚀 Upgrade & Maintenance
│   ├── docs/                       # Upgrade documentation
│   │   ├── UPGRADE-QUICK-SUMMARY.md   ⭐ Quick upgrade guide
│   │   ├── UPGRADE-GUIDE.md       # Detailed upgrade procedures
│   │   └── CUSTOMIZATIONS.md      # Track your customizations
│   └── scripts/                    # Upgrade automation
│       ├── upgrade-uaa.sh         ⭐ Main upgrade script
│       ├── backup-database.sh     # Database backup
│       └── restore-database.sh    # Database restore
│
├── app/                            🔐 Keys & Certificates
│   ├── saml.crt                   # SAML certificate (Elephant Insurance)
│   ├── saml.key                   # SAML private key
│   ├── jwt_key.pem                # JWT signing key
│   ├── jwt_key_rsa.pem           # JWT RSA key
│   └── jwt_pub.pem               # JWT public key
│
├── config/                         ⚙️  Configuration
│   └── uaa.yml                    # Main UAA configuration
│
├── backups/                        💾 Backups
│   └── database/                  # Database backups
│
└── docker-compose.yml              🐳 Docker setup
```

## Quick Navigation

### 🆕 First Time Setup
Start here: **[uaa-setup/README.md](uaa-setup/README.md)**

Key tasks:
1. Setup database: `./uaa-setup/scripts/setup-database.sh`
2. Generate keys: `./uaa-setup/scripts/generate-uaa-keys.sh`
3. Start UAA: `docker-compose up -d`

### 🔄 Upgrading to New Version
Go to: **[uaa-upgrade/README.md](uaa-upgrade/README.md)**

Quick upgrade:
```bash
./uaa-upgrade/scripts/upgrade-uaa.sh 77.0.0
```

### 📚 Documentation by Purpose

| Need | Location |
|------|----------|
| Initial setup | [uaa-setup/docs/README-UAA-SETUP.md](uaa-setup/docs/README-UAA-SETUP.md) |
| Command reference | [uaa-setup/docs/QUICK-REFERENCE.md](uaa-setup/docs/QUICK-REFERENCE.md) |
| Upgrade guide | [uaa-upgrade/docs/UPGRADE-QUICK-SUMMARY.md](uaa-upgrade/docs/UPGRADE-QUICK-SUMMARY.md) ⭐ |
| Track customizations | [uaa-upgrade/docs/CUSTOMIZATIONS.md](uaa-upgrade/docs/CUSTOMIZATIONS.md) |

### 🛠️ Scripts by Purpose

#### Setup & Operations (uaa-setup/scripts/)
- `generate-uaa-keys.sh` - Generate SAML/JWT keys with Elephant Insurance details
- `setup-database.sh` - Create PostgreSQL user and database
- `run-uaa-locally.sh` - Run UAA with Gradle (non-Docker)
- `cleanup.sh` - Clean up temporary files

#### Upgrade & Backup (uaa-upgrade/scripts/)
- `upgrade-uaa.sh` ⭐ - Automated upgrade to new version
- `backup-database.sh` - Backup PostgreSQL database
- `restore-database.sh` - Restore from backup

## Common Tasks

### Start UAA
```bash
docker-compose up -d
```

### Stop UAA
```bash
docker-compose down
```

### Check Health
```bash
curl http://localhost:8080/healthz
```

### View Logs
```bash
docker-compose logs -f uaa
```

### Backup Database
```bash
./uaa-upgrade/scripts/backup-database.sh
```

### Upgrade UAA
```bash
./uaa-upgrade/scripts/upgrade-uaa.sh <version>
```

### Generate New Keys
```bash
./uaa-setup/scripts/generate-uaa-keys.sh
```

## Key Features

✅ **Organized Structure** - Clear separation of setup vs upgrade  
✅ **Automated Upgrades** - One command to upgrade safely  
✅ **Auto-Backup** - Database backup/restore included  
✅ **Custom SAML** - Elephant Insurance certificate details  
✅ **Cross-Platform** - Scripts for Linux, Mac, and Windows  
✅ **Well-Documented** - Comprehensive guides and references  
✅ **Path Detection** - Scripts work from any directory  

## File Locations Reference

### Configuration Files
- Main config: `config/uaa.yml`
- Docker setup: `docker-compose.yml`

### Keys & Certificates (all in `app/`)
- SAML cert: `app/saml.crt` (Elephant Insurance: C=US, ST=Virginia, L=Henrico...)
- SAML key: `app/saml.key`
- JWT keys: `app/jwt_key*.pem`

### Database
- User: `uaauser`
- Password: `uaapassword`
- Database: `uaa`
- Backups: `backups/database/`

## Getting Help

1. **Setup Issues** → Check [uaa-setup/docs/](uaa-setup/docs/)
2. **Upgrade Issues** → Check [uaa-upgrade/docs/](uaa-upgrade/docs/)
3. **Errors** → Review logs: `docker-compose logs uaa`
4. **Official Docs** → https://docs.cloudfoundry.org/uaa/

## Project Highlights

### Custom Configuration
- Database: PostgreSQL with dedicated `uaauser` (not postgres superuser)
- SAML: Custom certificate with Elephant Insurance organization details
- JWT: Custom signing keys for OAuth2/OIDC
- Docker: Simplified environment variables

### Best Practices Implemented
- 📦 Modular organization (setup vs upgrade)
- 🔒 Sensitive data protection guidelines
- 📝 Comprehensive documentation
- 🤖 Automated scripts with error handling
- 💾 Automatic backup before upgrades
- ✅ Health check verification

## Version Control

### Important: Protect Sensitive Data

Add to `.gitignore`:
```bash
cat .gitignore.custom >> .gitignore
```

Files to **never commit publicly**:
- `config/uaa.yml` (contains passwords and keys)
- `app/saml.key` (private key)
- `app/jwt_key_rsa.pem` (signing key)

### Files to Preserve During Upgrades

The upgrade script automatically preserves:
- ✅ `config/uaa.yml`
- ✅ `app/` directory
- ✅ `uaa-setup/` directory
- ✅ `uaa-upgrade/` directory
- ✅ `docker-compose.yml`
- ✅ Database volume data

---

**Quick Links:**
- 🆕 [Initial Setup](uaa-setup/README.md)
- 🚀 [Upgrade Guide](uaa-upgrade/README.md)
- 📖 [Full Documentation Index](uaa-setup/docs/DOCUMENTATION-INDEX.md)

**Your UAA installation is organized for success!** 🎯
