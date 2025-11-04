# UAA Setup Quick Reference

## 🚀 Initial Setup

```bash
# Generate keys
./generate-uaa-keys.sh        # Linux/Mac/Git Bash
generate-uaa-keys.bat          # Windows CMD

# Build UAA
./gradlew clean :cloudfoundry-identity-uaa:assemble --no-daemon

# Start
docker compose up --build
```

## 🧹 Cleanup

```bash
# Remove old certificates, logs, and temporary files
./cleanup.sh                   # Linux/Mac/Git Bash

# Keeps only active keys:
#   - app/saml.key, app/saml.crt
#   - jwt_key.pem, jwt_key_rsa.pem, jwt_pub.pem
#   - config/uaa.yml
```

## 🔧 Common Commands

```bash
# View logs
docker compose logs -f uaa

# Restart
docker compose restart uaa

# Stop
docker compose down

# Rebuild after code changes
./gradlew clean :cloudfoundry-identity-uaa:assemble --no-daemon
docker compose build
docker compose up -d
```

## 🏥 Health Checks

```bash
# Health endpoint
curl http://localhost:8080/healthz
# Expected: ok

# Login page
curl http://localhost:8080/login
# Expected: HTML content

# OpenID configuration
curl http://localhost:8080/.well-known/openid-configuration
# Expected: JSON configuration
```

## 🔑 Default Credentials

**Admin User:**
- Username: `admin`
- Password: `admin`

**Admin Client:**
- Client ID: `admin`
- Client Secret: `adminsecret`

## 🌐 Key Endpoints

| Endpoint | URL |
|----------|-----|
| Login | http://localhost:8080/login |
| Health | http://localhost:8080/healthz |
| Token | http://localhost:8080/oauth/token |
| Authorize | http://localhost:8080/oauth/authorize |
| User Info | http://localhost:8080/userinfo |
| Token Keys | http://localhost:8080/token_keys |
| OIDC Discovery | http://localhost:8080/.well-known/openid-configuration |

## 📝 Get Access Token

```bash
# Client credentials grant
curl -X POST http://localhost:8080/oauth/token \
  -u admin:adminsecret \
  -d grant_type=client_credentials

# Password grant
curl -X POST http://localhost:8080/oauth/token \
  -u admin:adminsecret \
  -d grant_type=password \
  -d username=admin \
  -d password=admin
```

## 🐛 Troubleshooting

### "Metadata response is missing verification certificates"
```bash
# Regenerate SAML keys
./generate-uaa-keys.sh
docker compose build --no-cache
docker compose up -d
```

### "corrupted stream - out of bounds length found"
```bash
# JWT key is truncated/invalid - regenerate
./generate-uaa-keys.sh
docker compose build --no-cache
docker compose up -d
```

### Database connection issues
```bash
# Check PostgreSQL is running
pg_isready

# Verify database exists
psql -U postgres -l | grep uaa

# Create if missing
psql -U postgres -c "CREATE DATABASE uaa;"
```

### Config changes not applied
```bash
# Rebuild without cache
docker compose build --no-cache
docker compose up -d
```

## 📁 Important Files

| File | Purpose |
|------|---------|
| `config/uaa.yml` | Main configuration |
| `docker-compose.yml` | Docker setup |
| `Dockerfile` | Container definition |
| `generate-uaa-keys.sh` | Key generation script |
| `README-UAA-SETUP.md` | Full setup guide |

## 🔒 Generated Keys Location

| Key Type | File |
|----------|------|
| SAML Private Key | `app/saml.key` |
| SAML Certificate | `app/saml.crt` |
| JWT Private Key | `jwt_key_rsa.pem` |
| JWT Public Key | `jwt_pub.pem` |

## ⚙️ Configuration Sections

```yaml
login:
  entityID: uaa-local
  saml:
    activeKeyId: key1
    keys:
      key1:
        key: |          # SAML private key
        certificate: |  # SAML certificate
    providers: {}       # SAML IDPs (empty)

jwt:
  token:
    signing-key: |      # JWT private key
    verification-key: | # JWT public key

database:
  url: jdbc:postgresql://host.docker.internal:5432/uaa
  username: postgres
  password: ${DATABASE_PASSWORD}
```

## 📊 Environment Variables

Set in `docker-compose.yml`:

```yaml
DATABASE_HOST: host.docker.internal
DATABASE_PORT: 5432
DATABASE_NAME: uaa
DATABASE_USERNAME: postgres
DATABASE_PASSWORD: your_password
JAVA_OPTS: -Xmx512m -Xms256m
```

## 🔄 Development Workflow

1. Make code changes
2. Build: `./gradlew clean :cloudfoundry-identity-uaa:assemble --no-daemon`
3. Rebuild container: `docker compose build`
4. Restart: `docker compose up -d`
5. Check logs: `docker compose logs -f uaa`

## 📚 Resources

- Full Setup Guide: [README-UAA-SETUP.md](README-UAA-SETUP.md)
- UAA Documentation: https://docs.cloudfoundry.org/api/uaa/
- GitHub Repository: https://github.com/cloudfoundry/uaa
