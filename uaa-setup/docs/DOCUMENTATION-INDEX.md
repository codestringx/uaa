# UAA Documentation Index

This directory contains comprehensive documentation for setting up and running CloudFoundry UAA with Docker.

## ��� Documentation Files

### [SETUP-SUMMARY.txt](SETUP-SUMMARY.txt)
**Start here!** Quick overview of all files created and a condensed quick start guide.
- Lists all documentation and scripts
- Quick start commands
- Key explanations
- Default credentials
- Common troubleshooting

### [README-UAA-SETUP.md](README-UAA-SETUP.md) ���
**Complete setup guide** with detailed instructions.
- Prerequisites and installation
- Automated setup with script
- Manual key generation steps
- Configuration explanations
- Troubleshooting guide
- Production considerations
- OAuth2/OIDC endpoint documentation

### [QUICK-REFERENCE.md](QUICK-REFERENCE.md) ⚡
**Command cheat sheet** for daily operations.
- Common Docker commands
- Health check commands
- API endpoint URLs
- Credential reference
- Quick troubleshooting
- Configuration snippets

### [README.md](README.md)
**Main project README** (updated with Docker quick start section)
- Original CloudFoundry UAA documentation
- Docker Quick Start section added at top
- Links to detailed setup guide

## ��� Automation Scripts

### [generate-uaa-keys.sh](generate-uaa-keys.sh) ���
**Linux/Mac/Git Bash script** for automated key generation.
- Generates SAML Service Provider keys
- Generates JWT signing keys
- Automatically updates `config/uaa.yml`
- Creates timestamped backups
- **Usage:** `./generate-uaa-keys.sh`

### [generate-uaa-keys.bat](generate-uaa-keys.bat) 🪟
**Windows CMD script** for key generation.
- Generates SAML Service Provider keys
- Generates JWT signing keys
- Provides manual update instructions
- Creates timestamped backups
- **Usage:** `generate-uaa-keys.bat`

### [cleanup.sh](cleanup.sh) 🧹
**Cleanup script** to remove old/temporary files.
- Removes old certificates and keys
- Cleans up log files
- Removes duplicate configuration files
- Keeps only active keys in use by Docker setup
- **Usage:** `./cleanup.sh`

## ��� Quick Start by Operating System

### Linux / Mac / Git Bash
```bash
./generate-uaa-keys.sh
./gradlew clean :cloudfoundry-identity-uaa:assemble --no-daemon
docker compose up --build
curl http://localhost:8080/healthz
```

### Windows CMD
```cmd
generate-uaa-keys.bat
REM Follow script instructions to update config\uaa.yml
gradlew clean :cloudfoundry-identity-uaa:assemble --no-daemon
docker compose up --build
curl http://localhost:8080/healthz
```

## ��� Documentation Flow

```
┌─────────────────────────┐
│  SETUP-SUMMARY.txt      │ ← Start here for overview
│  Quick orientation      │
└────────────┬────────────┘
             │
             ├─────────────────────────────┐
             │                             │
             ▼                             ▼
┌────────────────────────┐    ┌────────────────────────┐
│ README-UAA-SETUP.md    │    │ QUICK-REFERENCE.md     │
│ Complete setup guide   │    │ Daily command cheat    │
│ Read for first setup   │    │ sheet - keep handy     │
└────────────────────────┘    └────────────────────────┘
```

## ��� Use Cases

| I want to... | Read this... |
|--------------|--------------|
| Get started quickly | SETUP-SUMMARY.txt |
| Do first-time setup | README-UAA-SETUP.md |
| Find a specific command | QUICK-REFERENCE.md |
| Troubleshoot an issue | README-UAA-SETUP.md → Troubleshooting section |
| See all endpoints | QUICK-REFERENCE.md → Key Endpoints table |
| Understand why SAML keys needed | README-UAA-SETUP.md → Configuration Details |
| Generate keys automatically | Run `./generate-uaa-keys.sh` |
| Generate keys manually | README-UAA-SETUP.md → Manual Key Generation |

## ��� Generated Files (after running scripts)

The key generation scripts create these files:

```
app/
├── saml.key          # SAML Service Provider private key
└── saml.crt          # SAML Service Provider certificate

jwt_key.pem              # JWT signing key (PKCS#8 format)
jwt_key_rsa.pem          # JWT signing key (RSA format for UAA)
jwt_pub.pem              # JWT verification public key

config/
└── uaa.yml.backup.*     # Timestamped backup of original config
```

## ��� What Each Key Does

| Key File | Purpose | Format |
|----------|---------|--------|
| `app/saml.key` | SAML signing | RSA Private Key (PKCS#8) |
| `app/saml.crt` | SAML metadata | X.509 Certificate |
| `jwt_key_rsa.pem` | JWT token signing | RSA Private Key |
| `jwt_pub.pem` | JWT token verification | RSA Public Key |

## ⚠️ Important Notes

1. **SAML keys are required** even if not using SAML authentication - this is a UAA architectural requirement
2. **JWT keys** are used for signing OAuth2/OIDC tokens
3. **Config location**: Make sure to edit `config/uaa.yml` (not root `uaa.yml`)
4. **Rebuild required**: After updating config, rebuild Docker image
5. **Backups created**: Scripts automatically backup your config before updating

## ��� Getting Help

1. **First time setup issue?** → README-UAA-SETUP.md
2. **Can't remember a command?** → QUICK-REFERENCE.md
3. **Error during startup?** → README-UAA-SETUP.md → Troubleshooting
4. **Need OAuth2 examples?** → README-UAA-SETUP.md → OAuth2/OIDC Endpoints

## ��� File Sizes

```
README-UAA-SETUP.md     9.2 KB  (Comprehensive guide)
generate-uaa-keys.sh    5.8 KB  (Automated script - Linux/Mac)
QUICK-REFERENCE.md      4.3 KB  (Command reference)
generate-uaa-keys.bat   3.5 KB  (Automated script - Windows)
SETUP-SUMMARY.txt       ~4 KB   (Quick overview)
```

---

**Ready to start?** Open [SETUP-SUMMARY.txt](SETUP-SUMMARY.txt) for a quick overview, then follow the Quick Start guide above! ���
