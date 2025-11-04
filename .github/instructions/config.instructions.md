---
applyTo: "config/**"
---

# GitHub Copilot Instructions for config/ Directory

## Purpose
This directory contains **configuration files ONLY**. Primary configuration file for UAA service.

## Critical File

### uaa.yml
**The single source of truth** for all UAA configuration.

## Configuration Principles

### 1. Single Source of Truth
`config/uaa.yml` is the PRIMARY and ONLY configuration file:
- All database settings go here
- All SAML/JWT keys embedded inline here
- All OAuth clients defined here
- All LDAP/external auth settings here
- All logging configuration here

### 2. Environment Variables
Always use environment variable fallbacks:
```yaml
DATABASE_USERNAME: ${DATABASE_USERNAME:uaauser}
DATABASE_PASSWORD: ${DATABASE_PASSWORD:uaapassword}
DATABASE_URL: ${DATABASE_URL:jdbc:postgresql://localhost:5432/uaa}
```

Pattern: `${VARIABLE_NAME:default_value}`

### 3. Inline Secrets
UAA architecture requires inline key content:
```yaml
login:
  serviceProviderKey: |
    -----BEGIN PRIVATE KEY-----
    [key content here]
    -----END PRIVATE KEY-----
```

**Never suggest** using file paths instead of inline content.

## Elephant Insurance Settings

### Database Configuration
```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/uaa
    username: uaauser  # NOT postgres superuser
    password: uaapassword
    driver-class-name: org.postgresql.Driver
```

### SAML Configuration
SAML certificates must contain:
- Organization: Elephant Insurance
- Location: Henrico, Virginia, USA
- Domain: elephant.com

## Rules

### ✅ DO:
1. Keep all configuration in `config/uaa.yml`
2. Use environment variable fallbacks
3. Embed keys inline (UAA requirement)
4. Use 2-space YAML indentation
5. Add comments for Elephant Insurance customizations
6. Document non-obvious settings
7. Test configuration changes before committing

### ❌ DON'T:
1. Create `.env` files (deleted intentionally)
2. Put database credentials in `docker-compose.yml`
3. Use file references for keys (UAA doesn't support this)
4. Hardcode values without environment variable fallbacks
5. Use `postgres` superuser (use `uaauser`)
6. Mix tabs and spaces in YAML
7. Commit production secrets to version control

## Configuration Sections

### Database
```yaml
spring:
  datasource:
    url: ${DATABASE_URL:jdbc:postgresql://localhost:5432/uaa}
    username: ${DATABASE_USERNAME:uaauser}
    password: ${DATABASE_PASSWORD:uaapassword}
```

### SAML Keys
```yaml
login:
  serviceProviderKey: |
    -----BEGIN PRIVATE KEY-----
    [Elephant Insurance private key]
    -----END PRIVATE KEY-----
  serviceProviderCertificate: |
    -----BEGIN CERTIFICATE-----
    [Elephant Insurance certificate]
    -----END CERTIFICATE-----
```

### JWT Signing
```yaml
jwt:
  token:
    signing-key: |
      -----BEGIN RSA PRIVATE KEY-----
      [JWT signing key]
      -----END RSA PRIVATE KEY-----
    verification-key: |
      -----BEGIN PUBLIC KEY-----
      [JWT public key]
      -----END PUBLIC KEY-----
```

## Security Considerations

1. **Sensitive File**: Contains passwords and private keys
2. **Git Ignore**: Should be in `.gitignore` for production
3. **Development**: OK to commit with development credentials
4. **Production**: Use environment variables, never commit secrets
5. **Encryption**: Consider encrypted secrets for production

## Configuration Changes

### Before Changes:
1. Backup current configuration
2. Document the change in `uaa-upgrade/docs/CUSTOMIZATIONS.md`
3. Test in development environment

### After Changes:
1. Restart UAA service: `docker-compose restart uaa`
2. Check logs: `docker-compose logs uaa`
3. Verify health: `curl http://localhost:8080/healthz`
4. Test authentication flow

## YAML Best Practices

1. **Indentation**: Always 2 spaces
2. **Quotes**: Use quotes for values with special characters
3. **Multiline**: Use `|` for multiline strings (keys)
4. **Comments**: Add `#` comments for customizations
5. **Anchors**: Use YAML anchors to avoid repetition

## Related Documentation

- Setup guide: `uaa-setup/docs/README-UAA-SETUP.md`
- Customizations: `uaa-upgrade/docs/CUSTOMIZATIONS.md`
- Quick reference: `uaa-setup/docs/QUICK-REFERENCE.md`

## Validation

After editing `uaa.yml`:
```bash
# Check YAML syntax
docker-compose config

# Test UAA startup
docker-compose up uaa

# Verify database connection
docker-compose exec postgres psql -U uaauser -d uaa -c "SELECT 1;"
```
