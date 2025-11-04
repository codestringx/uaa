#!/bin/bash

# UAA Project Cleanup Script
# Removes temporary files, old certificates, and generated keys
#
# Usage: Run from UAA root directory
#   ./uaa-setup/scripts/cleanup.sh

echo "========================================="
echo "UAA Project Cleanup"
echo "========================================="
echo ""

# Color codes
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

# Files to remove
FILES_TO_REMOVE=(
    # Old/duplicate SAML certificates and keys (root directory)
    "saml-key.key"
    "saml-cert.crt"
    
    # Duplicate uaa.yml in root (config/uaa.yml is the correct one)
    "uaa.yml"
    
    # Old SAML files in app/ directory
    "app/saml.key"
    "app/saml.crt"
    "app/saml-metadata.xml"
    "app/minimal-saml-metadata.xml"
    
    # Build/runtime logs
    "boot.log"
    "boot.pid"
    "build.log"
    
    # Minimal build file (not needed)
    "minimal-build.gradle"
)

# Directories to clean (preserve directory structure)
DIRS_TO_CLEAN=(
    "logs"
)

echo -e "${YELLOW}Files to be removed:${NC}"
for file in "${FILES_TO_REMOVE[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✗ $file"
    fi
done
echo ""

echo -e "${YELLOW}Directories to be cleaned:${NC}"
for dir in "${DIRS_TO_CLEAN[@]}"; do
    if [ -d "$dir" ] && [ "$(ls -A $dir 2>/dev/null)" ]; then
        echo "  ✗ $dir/* (contents will be removed)"
    fi
done
echo ""

# Generated keys to KEEP (used by Docker setup)
echo -e "${GREEN}Files to KEEP (in use by Docker setup):${NC}"
echo "  ✓ app/saml.key (current SAML private key)"
echo "  ✓ app/saml.crt (current SAML certificate)"
echo "  ✓ app/jwt_key.pem (JWT private key - PKCS#8)"
echo "  ✓ app/jwt_key_rsa.pem (JWT private key - RSA format)"
echo "  ✓ app/jwt_pub.pem (JWT public key)"
echo "  ✓ config/uaa.yml (main configuration)"
echo ""

read -p "Proceed with cleanup? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${YELLOW}Cleaning up...${NC}"
    
    REMOVED_COUNT=0
    
    # Remove files
    for file in "${FILES_TO_REMOVE[@]}"; do
        if [ -f "$file" ]; then
            rm -f "$file"
            echo -e "${GREEN}✓${NC} Removed: $file"
            ((REMOVED_COUNT++))
        fi
    done
    
    # Clean directories
    for dir in "${DIRS_TO_CLEAN[@]}"; do
        if [ -d "$dir" ] && [ "$(ls -A $dir 2>/dev/null)" ]; then
            rm -rf "$dir"/*
            echo -e "${GREEN}✓${NC} Cleaned: $dir/"
            ((REMOVED_COUNT++))
        fi
    done
    
    echo ""
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}Cleanup Complete!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo "Removed $REMOVED_COUNT items"
    echo ""
    echo "Your project is now clean and ready for use."
    echo "Run './generate-uaa-keys.sh' to regenerate keys if needed."
else
    echo ""
    echo "Cleanup cancelled."
fi
