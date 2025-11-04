---
applyTo: "uaa-setup/**"
---

# GitHub Copilot Instructions for uaa-setup/ Directory

## Purpose
This directory contains resources for **initial setup and daily operations** of UAA.

## Directory Structure

```
uaa-setup/
├── docs/           # Setup documentation
└── scripts/        # Setup and operation scripts
```

## Documentation (docs/)

### Key Files:
- `README-UAA-SETUP.md` - Main setup guide
- `QUICK-REFERENCE.md` - Quick reference for common tasks
- Other setup-related documentation

### Documentation Standards:
1. Use Markdown format
2. Include emojis for visual navigation (📦, 🚀, ⭐, etc.)
3. Provide both quick start and detailed guides
4. Include practical examples
5. Cross-reference related documentation
6. Keep setup docs separate from upgrade docs

## Scripts (scripts/)

### Key Scripts:
- `generate-uaa-keys.sh` - Generate SAML/JWT keys with Elephant Insurance details
- `setup-database.sh` - Initialize PostgreSQL database
- `run-uaa-locally.sh` - Run UAA without Docker
- `cleanup.sh` - Clean temporary files and caches

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

#### Error Handling (REQUIRED)
```bash
set -e  # Exit on error

# For critical operations
if [ ! -f "important-file" ]; then
    echo -e "${RED}✗ Error: important-file not found${NC}"
    exit 1
fi
```

#### User Confirmations
For destructive operations:
```bash
read -p "Are you sure? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Operation cancelled."
    exit 0
fi
```

## Rules

### ✅ DO:
1. Put initial setup scripts here
2. Put daily operation scripts here
3. Use auto-path detection in all scripts
4. Provide both `.sh` (Bash) and `.bat` (Windows) versions
5. Include colored output and progress indicators
6. Add clear section headers with echo statements
7. Handle errors gracefully with helpful messages
8. Document script usage in comments
9. Make scripts executable (`chmod +x`)
10. Test scripts from different directories

### ❌ DON'T:
1. Put upgrade scripts here (use `uaa-upgrade/scripts/` instead)
2. Put backup scripts here (use `uaa-upgrade/scripts/` instead)
3. Hardcode absolute paths (use auto-detection)
4. Create scripts without error handling
5. Skip user confirmations for destructive operations
6. Use generic certificate details (must be Elephant Insurance)
7. Put scripts in root directory
8. Create scripts that only work from specific directories

## Elephant Insurance Customizations

### generate-uaa-keys.sh
MUST use these certificate details:
```bash
COUNTRY="US"
STATE="Virginia"
LOCALITY="Henrico"
ORGANIZATION="Elephant Insurance"
ORG_UNIT="Digital Development"
COMMON_NAME="elephant.com"
```

### setup-database.sh
MUST use these credentials:
```bash
DB_NAME="uaa"
DB_USER="uaauser"  # NOT postgres superuser
DB_PASSWORD="uaapassword"
```

## Cross-Platform Support

### Bash Scripts (.sh)
- Primary scripts for Linux/macOS/Git Bash on Windows
- Use `/bin/bash` shebang
- Use forward slashes in paths
- Test on Windows Git Bash

### Windows Batch (.bat)
Provide Windows CMD equivalents for key scripts:
```batch
@echo off
setlocal

REM Script description
echo Setting up UAA...

REM Commands here

endlocal
```

## Script Organization

### Setup Scripts (uaa-setup/scripts/)
- `generate-uaa-keys.sh` - Key generation
- `setup-database.sh` - Database initialization
- `run-uaa-locally.sh` - Local development
- `cleanup.sh` - Cleanup operations

### NOT Here (use uaa-upgrade/scripts/)
- `upgrade-uaa.sh` - Version upgrades
- `backup-database.sh` - Database backups
- `restore-database.sh` - Database restoration

## Documentation Standards

### README Structure
1. **Overview** - What this is about
2. **Quick Start** - Get running in 5 minutes
3. **Detailed Guide** - Step-by-step instructions
4. **Troubleshooting** - Common issues and solutions
5. **Next Steps** - What to do after setup

### Code Examples
Always include:
```bash
# What this does
command-to-run

# Expected output
Sample output here
```

## File Paths

### Absolute Paths After Detection
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UAA_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Now use absolute paths
"$UAA_ROOT/app/saml.crt"
"$UAA_ROOT/config/uaa.yml"
```

### Relative Paths in Documentation
```markdown
See `uaa-setup/docs/README-UAA-SETUP.md` for details.
Run `./uaa-setup/scripts/generate-uaa-keys.sh` to create keys.
```

## Testing Scripts

Before committing any script:
```bash
# Test from different directories
cd /tmp
/path/to/uaa/uaa-setup/scripts/your-script.sh

cd ~
/path/to/uaa/uaa-setup/scripts/your-script.sh

# Test error conditions
# (simulate failures to verify error handling)
```

## Related Documentation

- Main instructions: `.github/copilot-instructions.md`
- Upgrade instructions: `uaa-upgrade/.github/copilot-instructions.md`
- Config instructions: `config/.github/copilot-instructions.md`
- Project structure: `PROJECT-STRUCTURE.md`

## When Adding New Scripts

1. Choose correct location (setup vs upgrade)
2. Add auto-path detection
3. Include colored output
4. Add error handling
5. Document usage in header comments
6. Make executable (`chmod +x`)
7. Test from multiple directories
8. Update relevant documentation
9. Consider Windows `.bat` equivalent
