# UAA Setup Resources

This directory contains all documentation and scripts for setting up and managing the UAA deployment.

## Directory Structure

```
uaa-setup/
├── docs/                           # Setup documentation
│   ├── README-UAA-SETUP.md        # Complete setup guide
│   ├── QUICK-REFERENCE.md         # Command cheat sheet
│   ├── DOCUMENTATION-INDEX.md     # Documentation index and use cases
│   ├── SETUP-SUMMARY.txt          # Quick overview
│   └── CLEANUP-REPORT.txt         # Cleanup operation report
│
└── scripts/                        # Setup scripts
    ├── generate-uaa-keys.sh       # Key generation (Linux/Mac/Git Bash)
    ├── generate-uaa-keys.bat      # Key generation (Windows CMD)
    ├── setup-database.sh          # Database setup (Linux/Mac)
    ├── setup-database.bat         # Database setup (Windows)
    ├── cleanup.sh                 # Project cleanup script
    ├── run-uaa-locally.sh         # Run UAA with Gradle (Linux/Mac)
    └── run-uaa-locally.bat        # Run UAA with Gradle (Windows)
```

**For upgrade resources, see:** [`../uaa-upgrade/`](../uaa-upgrade/README.md)

## Quick Start

### Setup Database

**Linux/Mac/Git Bash:**
```bash
./uaa-setup/scripts/setup-database.sh
```

**Windows CMD:**
```cmd
.\uaa-setup\scripts\setup-database.bat
```

### Generate Keys and Certificates

**Linux/Mac/Git Bash:**
```bash
./uaa-setup/scripts/generate-uaa-keys.sh
```

**Windows CMD:**
```cmd
.\uaa-setup\scripts\generate-uaa-keys.bat
```

### Run UAA

**With Docker (Recommended):**
```bash
docker compose up --build
```

**Locally with Gradle:**
```bash
# Linux/Mac/Git Bash
./uaa-setup/scripts/run-uaa-locally.sh

# Windows CMD
.\uaa-setup\scripts\run-uaa-locally.bat
```

### Upgrade UAA to New Version

**See the dedicated upgrade resources:**

📦 **[uaa-upgrade/](../uaa-upgrade/README.md)** - Complete upgrade documentation and scripts

Quick upgrade:
```bash
./uaa-upgrade/scripts/upgrade-uaa.sh <version>

# Example:
./uaa-upgrade/scripts/upgrade-uaa.sh 77.0.0
```

### Backup and Restore

**Backup Database:**
```bash
./uaa-upgrade/scripts/backup-database.sh
```

**Restore Database:**
```bash
./uaa-upgrade/scripts/restore-database.sh <backup-file>
```

### Clean Up Old Files

```bash
./uaa-setup/scripts/cleanup.sh
```

## Documentation

### Setup & Getting Started
- **[README-UAA-SETUP.md](docs/README-UAA-SETUP.md)** - Complete setup instructions
- **[QUICK-REFERENCE.md](docs/QUICK-REFERENCE.md)** - Quick reference for common commands
- **[DOCUMENTATION-INDEX.md](docs/DOCUMENTATION-INDEX.md)** - Find documentation by use case

### Upgrading & Maintenance
📦 **See [uaa-upgrade/](../uaa-upgrade/README.md) for all upgrade resources**

## Key Features

✅ **Automated Setup** - Scripts for database, keys, and certificates  
✅ **Custom SAML** - Elephant Insurance certificate configuration  
✅ **Cross-Platform** - Scripts for Linux, Mac, and Windows  
✅ **Well-Documented** - Comprehensive guides and references  
✅ **Path Detection** - Scripts work from any directory

**For upgrade capabilities, see** [`uaa-upgrade/`](../uaa-upgrade/README.md)

## Requirements

- OpenSSL (for key generation)
- Docker and Docker Compose
- Gradle 9.2.0 (for building UAA)
- Java 21
- PostgreSQL (running on host machine or external server)

## Support

For issues or questions, refer to:
- Main project [README.md](../README.md)
- CloudFoundry UAA [official documentation](https://docs.cloudfoundry.org/api/uaa/)
