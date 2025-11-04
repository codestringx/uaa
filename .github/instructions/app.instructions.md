---
applyTo: "app/**"
---

# GitHub Copilot Instructions for app/ Directory

## Purpose
This directory contains **cryptographic keys and certificates ONLY**. No other files should be placed here.

## Critical Files

### SAML Keys
- `saml.crt` - SAML Service Provider certificate
- `saml.key` - SAML Service Provider private key

### JWT Keys
- `jwt_key.pem` - JWT signing key (main)
- `jwt_key_rsa.pem` - JWT RSA private key
- `jwt_pub.pem` - JWT public key

## Elephant Insurance Certificate Details

When generating or regenerating any certificates in this directory, ALWAYS use these details:

```
C  = US
ST = Virginia
L  = Henrico
O  = Elephant Insurance
OU = Digital Development
CN = elephant.com
```

## Rules

### ✅ DO:
1. Store all SAML certificates here
2. Store all JWT keys here
3. Use Elephant Insurance organization details in certificates
4. Keep private keys secure (add to `.gitignore`)
5. Document certificate expiration dates
6. Use 365-day validity for self-signed certificates

### ❌ DON'T:
1. Put configuration files here (use `config/` instead)
2. Put scripts here (use `uaa-setup/scripts/` or `uaa-upgrade/scripts/`)
3. Put documentation here (use `uaa-setup/docs/` or `uaa-upgrade/docs/`)
4. Use generic certificate details (must be Elephant Insurance)
5. Commit private keys to public repositories
6. Put keys in root directory or any other location

## Key Generation

Use the provided script to generate all keys:
```bash
./uaa-setup/scripts/generate-uaa-keys.sh
```

This script will:
- Generate SAML certificate with Elephant Insurance details
- Generate JWT signing keys
- Place all keys in this `app/` directory
- Set appropriate file permissions

## Security Notes

1. **Private Keys**: All `.key` and `_rsa.pem` files are sensitive
2. **Git Ignore**: Ensure `.gitignore` excludes private keys
3. **Permissions**: Keep restrictive permissions (600 for private keys)
4. **Rotation**: Plan to rotate keys annually
5. **Backup**: Backup keys before rotation or upgrades

## Certificate Verification

Verify SAML certificate details:
```bash
openssl x509 -in app/saml.crt -text -noout | grep "Subject:"
```

Expected output should contain:
```
Subject: C=US, ST=Virginia, L=Henrico, O=Elephant Insurance, OU=Digital Development, CN=elephant.com
```

## File References

These keys are referenced inline in `config/uaa.yml`:
- UAA requires inline key content (not file paths)
- Keys are embedded in YAML configuration
- Never suggest using file references instead of inline content

## When Making Changes

1. **Backup First**: Always backup existing keys before regeneration
2. **Test**: Test new keys in development before production
3. **Document**: Update CUSTOMIZATIONS.md with any key changes
4. **Coordinate**: Key changes require UAA restart and may affect clients
