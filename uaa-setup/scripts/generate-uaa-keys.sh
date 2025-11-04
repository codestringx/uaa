#!/bin/bash

# UAA Key Generation Script
# This script generates all required keys and certificates for UAA setup
# and updates the config/uaa.yml file with the generated values
#
# Usage: Run from UAA root directory
#   ./uaa-setup/scripts/generate-uaa-keys.sh

set -e

echo "========================================="
echo "UAA Key and Certificate Generation"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the UAA root directory (2 levels up from script location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UAA_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Change to UAA root directory
cd "$UAA_ROOT"

echo "Working directory: $UAA_ROOT"
echo ""

# Check if required commands are available
command -v openssl >/dev/null 2>&1 || { echo -e "${RED}Error: openssl is required but not installed.${NC}" >&2; exit 1; }

# Create app directory if it doesn't exist
mkdir -p app

echo -e "${YELLOW}Step 1: Generating SAML Service Provider Keys${NC}"
echo "Generating SAML private key and certificate (RSA 2048-bit, valid for 365 days)..."

# Generate SAML SP key and certificate
openssl req -newkey rsa:2048 -nodes -keyout app/saml.key \
  -x509 -days 365 -out app/saml.crt \
  -subj "//C=US/ST=Virginia/L=Henrico/O=Elephant Insurance/OU=Digital Development/CN=elephant.com" 2>/dev/null || \
openssl req -newkey rsa:2048 -nodes -keyout app/saml.key \
  -x509 -days 365 -out app/saml.crt \
  -subj "/C=US/ST=Virginia/L=Henrico/O=Elephant Insurance/OU=Digital Development/CN=elephant.com"

echo -e "${GREEN}✓ SAML keys generated:${NC}"
echo "  - app/saml.key (private key)"
echo "  - app/saml.crt (certificate)"
echo ""

echo -e "${YELLOW}Step 2: Generating JWT Signing Keys${NC}"
echo "Generating JWT RSA private key (2048-bit)..."

# Generate JWT private key
openssl genrsa -out app/jwt_key.pem 2048 2>/dev/null

# Convert to RSA format (required by UAA)
openssl rsa -in app/jwt_key.pem -out app/jwt_key_rsa.pem 2>/dev/null

# Extract public key
openssl rsa -in app/jwt_key.pem -pubout -out app/jwt_pub.pem 2>/dev/null

echo -e "${GREEN}✓ JWT keys generated:${NC}"
echo "  - app/jwt_key.pem (private key)"
echo "  - app/jwt_key_rsa.pem (RSA format private key)"
echo "  - app/jwt_pub.pem (public key)"
echo ""

echo -e "${YELLOW}Step 3: Updating config/uaa.yml${NC}"

# Check if config/uaa.yml exists
if [ ! -f "config/uaa.yml" ]; then
    echo -e "${RED}Error: config/uaa.yml not found!${NC}"
    echo "Please ensure you're running this script from the UAA root directory."
    exit 1
fi

# Backup existing config
BACKUP_FILE="config/uaa.yml.backup.$(date +%Y%m%d_%H%M%S)"
cp config/uaa.yml "$BACKUP_FILE"
echo "Created backup: $BACKUP_FILE"

# Read the generated keys
SAML_KEY=$(cat app/saml.key)
SAML_CERT=$(cat app/saml.crt)
JWT_SIGNING_KEY=$(cat app/jwt_key_rsa.pem)
JWT_VERIFICATION_KEY=$(cat app/jwt_pub.pem)

# Create a temporary Python script to update the YAML (preserves formatting better than sed)
cat > /tmp/update_uaa_config.py << 'PYTHON_SCRIPT'
import sys
import re

def indent_text(text, spaces):
    """Indent each line of text by specified number of spaces"""
    lines = text.strip().split('\n')
    return '\n'.join(' ' * spaces + line for line in lines)

def update_config(config_path, saml_key, saml_cert, jwt_signing, jwt_verification):
    with open(config_path, 'r') as f:
        content = f.read()
    
    # Update SAML key
    saml_key_indented = indent_text(saml_key, 10)
    content = re.sub(
        r'(login:\s+.*?saml:\s+.*?keys:\s+.*?key1:\s+.*?key:\s+\|)\s*-----BEGIN[^-]*-----.*?-----END[^-]*-----',
        r'\1\n' + saml_key_indented,
        content,
        flags=re.DOTALL
    )
    
    # Update SAML certificate
    saml_cert_indented = indent_text(saml_cert, 10)
    content = re.sub(
        r'(certificate:\s+\|)\s*-----BEGIN[^-]*-----.*?-----END[^-]*-----',
        r'\1\n' + saml_cert_indented,
        content,
        flags=re.DOTALL
    )
    
    # Update JWT signing key
    jwt_signing_indented = indent_text(jwt_signing, 6)
    content = re.sub(
        r'(jwt:\s+.*?token:\s+.*?signing-key:\s+\|)\s*-----BEGIN[^-]*-----.*?-----END[^-]*-----',
        r'\1\n' + jwt_signing_indented,
        content,
        flags=re.DOTALL
    )
    
    # Update JWT verification key
    jwt_verification_indented = indent_text(jwt_verification, 6)
    content = re.sub(
        r'(verification-key:\s+\|)\s*-----BEGIN[^-]*-----.*?-----END[^-]*-----',
        r'\1\n' + jwt_verification_indented,
        content,
        flags=re.DOTALL
    )
    
    with open(config_path, 'w') as f:
        f.write(content)

if __name__ == '__main__':
    config_path = sys.argv[1]
    saml_key = sys.argv[2]
    saml_cert = sys.argv[3]
    jwt_signing = sys.argv[4]
    jwt_verification = sys.argv[5]
    
    update_config(config_path, saml_key, saml_cert, jwt_signing, jwt_verification)
PYTHON_SCRIPT

# Check if Python is available
if command -v python3 >/dev/null 2>&1; then
    python3 /tmp/update_uaa_config.py "config/uaa.yml" "$SAML_KEY" "$SAML_CERT" "$JWT_SIGNING_KEY" "$JWT_VERIFICATION_KEY"
    echo -e "${GREEN}✓ config/uaa.yml updated successfully${NC}"
elif command -v python >/dev/null 2>&1; then
    python /tmp/update_uaa_config.py "config/uaa.yml" "$SAML_KEY" "$SAML_CERT" "$JWT_SIGNING_KEY" "$JWT_VERIFICATION_KEY"
    echo -e "${GREEN}✓ config/uaa.yml updated successfully${NC}"
else
    echo -e "${YELLOW}Warning: Python not found. Please manually update config/uaa.yml with the generated keys.${NC}"
    echo ""
    echo "Generated key files:"
    echo "  - SAML Key: app/saml.key"
    echo "  - SAML Certificate: app/saml.crt"
    echo "  - JWT Signing Key: app/jwt_key_rsa.pem"
    echo "  - JWT Verification Key: app/jwt_pub.pem"
fi

# Clean up temp file
rm -f /tmp/update_uaa_config.py

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Key Generation Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Review the updated config/uaa.yml"
echo "2. Build UAA: ./gradlew clean :cloudfoundry-identity-uaa:assemble --no-daemon"
echo "3. Start Docker: docker compose up --build"
echo ""
echo "Note: A backup of your original config was saved to:"
echo "  $BACKUP_FILE"
