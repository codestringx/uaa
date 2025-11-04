# UAA Docker Setup Guide

This guide explains how to set up and run CloudFoundry UAA (User Account and Authentication) in Docker.

## Overview

UAA is an OAuth2 and OpenID Connect provider. This setup runs UAA with:
- PostgreSQL database
- JWT token signing
- SAML infrastructure (required even if not using SAML authentication)
- Docker containerization

## Prerequisites

- Docker and Docker Compose
- OpenSSL (for generating keys and certificates)
- Java 21 (for building UAA from source)
- Gradle (included via gradlew)
- PostgreSQL running on host machine (default: localhost:5432)

## Quick Start

### 1. Generate Required Keys and Certificates

Run the provided script to generate all necessary cryptographic materials:

```bash
./generate-uaa-keys.sh
```

This script will generate:
- SAML Service Provider private key and certificate
- JWT signing RSA private key and public key
- Update the `config/uaa.yml` file with the generated keys

**Alternatively, generate keys manually** (see [Manual Key Generation](#manual-key-generation) section below).

### 2. Configure Database

Ensure PostgreSQL is running on your host machine. Default connection settings:
- Host: `localhost` (accessible as `host.docker.internal` from container)
- Port: `5432`
- Database: `uaa`
- Username: `postgres`
- Password: Set in `docker-compose.yml` or `.env` file

Create the database if it doesn't exist:
```bash
psql -U postgres -c "CREATE DATABASE uaa;"
```

### 3. Build UAA

Build the UAA WAR file:
```bash
./gradlew clean :cloudfoundry-identity-uaa:assemble --no-daemon
```

The WAR file will be created at: `uaa/build/libs/cloudfoundry-identity-uaa-*.war`

### 4. Start UAA with Docker

Build and start the container:
```bash
docker compose up --build
```

Or run in detached mode:
```bash
docker compose up -d
```

### 5. Verify UAA is Running

Check health endpoint:
```bash
curl http://localhost:8080/healthz
# Should return: ok
```

Access the login page:
```bash
curl http://localhost:8080/login
# Should return HTML login page
```

## Configuration Details

### Why SAML Keys are Required

**Important:** UAA requires SAML Service Provider keys to be configured even if you're not using SAML authentication. This is because:

1. SAML components are deeply integrated into UAA's architecture
2. UAA creates internal SAML metadata during bootstrap
3. The application fails to start without valid SAML keys

The SAML configuration includes:
- Private key for signing SAML requests
- Certificate for SAML metadata
- Empty providers list (no external SAML IDPs configured)

### Configuration File Structure

The main configuration is in `config/uaa.yml`:

```yaml
login:
  entityID: uaa-local
  saml:
    activeKeyId: key1
    keys:
      key1:
        key: |
          -----BEGIN PRIVATE KEY-----
          [SAML private key]
          -----END PRIVATE KEY-----
        certificate: |
          -----BEGIN CERTIFICATE-----
          [SAML certificate]
          -----END CERTIFICATE-----
    providers: {}  # Empty - no SAML IDPs configured

jwt:
  token:
    signing-key: |
      -----BEGIN RSA PRIVATE KEY-----
      [JWT signing private key]
      -----END RSA PRIVATE KEY-----
    verification-key: |
      -----BEGIN PUBLIC KEY-----
      [JWT verification public key]
      -----END PUBLIC KEY-----
```

## Manual Key Generation

If you prefer to generate keys manually instead of using the script:

### Generate SAML Keys

```bash
# Generate SAML Service Provider private key and certificate (2048-bit RSA)
openssl req -newkey rsa:2048 -nodes -keyout app/saml.key \
  -x509 -days 365 -out app/saml.crt \
  -subj "//CN=UAA SAML SP"
```

### Generate JWT Signing Keys

```bash
# Generate RSA private key for JWT signing
openssl genrsa -out jwt_key.pem 2048

# Convert to RSA format (required by UAA)
openssl rsa -in jwt_key.pem -out jwt_key_rsa.pem

# Extract public key
openssl rsa -in jwt_key.pem -pubout -out jwt_pub.pem
```

### Update Configuration

Manually edit `config/uaa.yml` and insert the generated keys:

1. Copy content of `app/saml.key` to `login.saml.keys.key1.key`
2. Copy content of `app/saml.crt` to `login.saml.keys.key1.certificate`
3. Copy content of `jwt_key_rsa.pem` to `jwt.token.signing-key`
4. Copy content of `jwt_pub.pem` to `jwt.token.verification-key`

**Important:** Maintain proper YAML indentation (2 spaces per level).

## Troubleshooting

### Application Fails to Start

**Error: "Metadata response is missing verification certificates"**
- Cause: SAML keys are missing or invalid
- Solution: Run `./generate-uaa-keys.sh` to regenerate keys

**Error: "corrupted stream - out of bounds length found"**
- Cause: JWT signing key is truncated or in wrong format
- Solution: Regenerate JWT keys using the script or manual steps above

### Database Connection Issues

**Error: "Connection refused" or "Unknown host"**
- Verify PostgreSQL is running: `pg_isready`
- Check database exists: `psql -U postgres -l | grep uaa`
- Ensure host.docker.internal is accessible from container

### Configuration Not Applied

**Changes to uaa.yml not taking effect**
- Make sure you're editing `config/uaa.yml` (not root `uaa.yml`)
- Rebuild Docker image: `docker compose build --no-cache`
- Restart container: `docker compose up -d`

### Check Container Logs

```bash
# View all logs
docker compose logs uaa

# Follow logs in real-time
docker compose logs -f uaa

# View last 100 lines
docker compose logs uaa --tail 100
```

## Default Users and Clients

### Admin User
- Username: `admin`
- Password: `admin`
- Email: `admin@test.org`
- Authorities: `uaa.admin`, `scim.write`, `scim.read`, `clients.read`, `clients.write`, `clients.secret`, `password.write`

### Admin Client
- Client ID: `admin`
- Client Secret: `adminsecret`
- Grant Types: `client_credentials`
- Authorities: `clients.read`, `clients.write`, `clients.secret`, `uaa.admin`, `scim.read`, `scim.write`, `password.write`

## OAuth2/OIDC Endpoints

Once UAA is running, the following endpoints are available:

- Authorization: `http://localhost:8080/oauth/authorize`
- Token: `http://localhost:8080/oauth/token`
- User Info: `http://localhost:8080/userinfo`
- Token Keys: `http://localhost:8080/token_keys`
- OpenID Configuration: `http://localhost:8080/.well-known/openid-configuration`

### Example: Get Access Token

```bash
curl -X POST http://localhost:8080/oauth/token \
  -u admin:adminsecret \
  -d grant_type=client_credentials
```

## File Structure

```
.
├── config/
│   └── uaa.yml              # Main UAA configuration
├── app/
│   ├── saml.key          # SAML private key (generated)
│   └── saml.crt          # SAML certificate (generated)
├── jwt_key.pem              # JWT private key (generated)
├── jwt_key_rsa.pem          # JWT private key RSA format (generated)
├── jwt_pub.pem              # JWT public key (generated)
├── Dockerfile               # Docker image definition
├── docker-compose.yml       # Docker Compose configuration
├── generate-uaa-keys.sh     # Key generation script
└── README-UAA-SETUP.md      # This file
```

## Production Considerations

### Security

1. **Change default passwords**: Update admin user and client passwords
2. **Use strong keys**: Generate 4096-bit RSA keys for production
3. **Secure key storage**: Store keys in secrets management system
4. **Enable HTTPS**: Configure TLS/SSL termination
5. **Database security**: Use strong passwords, enable SSL connections

### Performance

1. **Adjust JVM settings**: Modify `JAVA_OPTS` in docker-compose.yml
2. **Database tuning**: Optimize PostgreSQL for your workload
3. **Connection pooling**: Configure `maxactive` and `maxidle` in database settings

### High Availability

1. **Multiple UAA instances**: Run behind a load balancer
2. **Shared database**: All instances connect to same PostgreSQL
3. **Session management**: Use sticky sessions or stateless tokens
4. **Database replication**: Configure PostgreSQL clustering

## Building from Source

To rebuild UAA after making code changes:

```bash
# Clean and build
./gradlew clean :cloudfoundry-identity-uaa:assemble --no-daemon

# Rebuild Docker image
docker compose build

# Restart
docker compose up -d
```

## Environment Variables

Key environment variables in `docker-compose.yml`:

- `DATABASE_HOST`: PostgreSQL host (default: `host.docker.internal`)
- `DATABASE_PORT`: PostgreSQL port (default: `5432`)
- `DATABASE_NAME`: Database name (default: `uaa`)
- `DATABASE_USERNAME`: Database user (default: `postgres`)
- `DATABASE_PASSWORD`: Database password
- `JAVA_OPTS`: JVM options (memory, debugging, etc.)

## Additional Resources

- [UAA Documentation](https://docs.cloudfoundry.org/api/uaa/)
- [CloudFoundry UAA GitHub](https://github.com/cloudfoundry/uaa)
- [OAuth2 RFC](https://tools.ietf.org/html/rfc6749)
- [OpenID Connect Specification](https://openid.net/specs/openid-connect-core-1_0.html)

## License

CloudFoundry UAA is licensed under the Apache License 2.0. See LICENSE file for details.
