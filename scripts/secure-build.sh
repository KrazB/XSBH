#!/bin/bash
set -e

# QGEN_IMPFRAG Secure Build & Distribution Script
# ==============================================
# 
# Implements immediate protection strategy:
# 1. Container Distribution with encryption
# 2. Code Obfuscation (JS minification + Python bytecode)  
# 3. Environment Licensing (Hardware fingerprinting + time limits)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DATE=$(date +%Y%m%d_%H%M%S)
VERSION="1.0.0"

echo "🔒 QGEN_IMPFRAG Secure Build Process"
echo "===================================="
echo "Version: $VERSION"
echo "Build Date: $BUILD_DATE"
echo ""

# Phase 1: Code Obfuscation
echo "🎭 Phase 1: Code Obfuscation"
echo "----------------------------"

# Frontend: JavaScript/TypeScript Obfuscation
echo "📦 Building and obfuscating frontend..."
cd "$PROJECT_ROOT/frontend"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    npm ci
fi

# Build with production optimizations
npm run build

# Advanced minification and obfuscation
if command -v terser &> /dev/null; then
    echo "🔧 Applying advanced JavaScript obfuscation..."
    find dist/assets -name "*.js" -type f -exec terser {} --compress --mangle --output {} \;
else
    echo "⚠️  Terser not found. Install with: npm install -g terser"
fi

echo "✅ Frontend obfuscation complete"

# Backend: Python Bytecode Compilation
echo "🐍 Compiling Python to bytecode..."
cd "$PROJECT_ROOT/backend"

# Create bytecode-only distribution
python3 -m compileall -b src/
find src/ -name "*.py" -delete  # Remove source files, keep only .pyc

echo "✅ Backend bytecode compilation complete"
cd "$PROJECT_ROOT"

# Phase 2: Secure Container Build
echo ""
echo "🐳 Phase 2: Secure Container Distribution"
echo "----------------------------------------"

# Build production container
docker build -t qgen-impfrag:secure-${VERSION} .

# Create encrypted distribution
echo "🔐 Creating encrypted container distribution..."
mkdir -p dist/secure

# Export and encrypt container
docker save qgen-impfrag:secure-${VERSION} | \
    gzip | \
    gpg --cipher-algo AES256 \
        --compress-algo 2 \
        --symmetric \
        --output "dist/secure/qgen-impfrag-${VERSION}-${BUILD_DATE}.tar.gz.gpg"

echo "✅ Encrypted container created: dist/secure/qgen-impfrag-${VERSION}-${BUILD_DATE}.tar.gz.gpg"

# Phase 3: Licensing System Setup
echo ""
echo "🔑 Phase 3: Environment Licensing"
echo "---------------------------------"

# Create licensing configuration
cat > dist/secure/license-config.json << EOF
{
  "version": "${VERSION}",
  "build_date": "${BUILD_DATE}",
  "protection_features": [
    "hardware_fingerprinting",
    "time_limited_licenses",
    "container_encryption"
  ],
  "license_server": "https://license.company.com/api/validate",
  "max_offline_days": 7,
  "require_hardware_match": true
}
EOF

# Create deployment script for clients
cat > dist/secure/deploy-secure.sh << 'EOF'
#!/bin/bash
set -e

echo "🔒 QGEN_IMPFRAG Secure Deployment"
echo "================================="

# Check for license file
if [ ! -f "license.key" ]; then
    echo "❌ License file not found!"
    echo "   Please contact your vendor for a license.key file"
    exit 1
fi

# Decrypt and load container
echo "🔓 Decrypting application container..."
read -s -p "Enter deployment password: " PASSWORD
echo

gpg --batch --yes --passphrase="$PASSWORD" \
    --decrypt qgen-impfrag-*.tar.gz.gpg | \
    gunzip | \
    docker load

if [ $? -ne 0 ]; then
    echo "❌ Failed to decrypt container. Check password."
    exit 1
fi

# Set license environment
export QGEN_LICENSE_FILE="$(pwd)/license.key"
export QGEN_HARDWARE_CHECK=true

# Start application with licensing
echo "🚀 Starting QGEN_IMPFRAG with licensing..."
docker run -d \
    --name qgen-impfrag-secure \
    -p 80:80 \
    -p 8000:8000 \
    -v "$(pwd)/license.key:/app/license.key:ro" \
    -v "$(pwd)/data:/app/data" \
    -e QGEN_LICENSE_FILE=/app/license.key \
    -e QGEN_HARDWARE_CHECK=true \
    qgen-impfrag:secure-1.0.0

echo "✅ Application deployed securely!"
echo "   Web Interface: http://localhost:80"
echo "   License expires: $(cat license.key | grep expires | cut -d: -f2)"
EOF

chmod +x dist/secure/deploy-secure.sh

# Create client documentation
cat > dist/secure/README-SECURE.md << EOF
# QGEN_IMPFRAG Secure Deployment Guide

## Security Features Implemented

### 1. Container Distribution ✅
- Encrypted Docker images with GPG/AES256
- Password-protected deployment
- Tamper-evident distribution

### 2. Code Obfuscation ✅  
- JavaScript minification and mangling
- Python bytecode-only distribution
- Source code removed from containers

### 3. Environment Licensing ✅
- Hardware fingerprinting validation
- Time-limited licenses
- Offline grace period (7 days)

## Deployment Instructions

1. **Prerequisites**
   - Docker installed and running
   - GPG tools available
   - Valid license.key file

2. **Deployment**
   \`\`\`bash
   # Place license.key in same directory as encrypted container
   ./deploy-secure.sh
   \`\`\`

3. **Access Application**
   - Web Interface: http://localhost:80
   - Backend API: http://localhost:8000

## License Management

- **Hardware Binding**: Each license is tied to specific hardware
- **Time Limits**: Licenses expire and require renewal
- **Offline Mode**: 7-day grace period without internet
- **Validation**: Regular check-ins with license server

## Support

For licensing issues or deployment problems:
- Email: support@company.com
- Phone: +1-XXX-XXX-XXXX
- Documentation: https://docs.company.com/qgen-impfrag

---
**CONFIDENTIAL**: This software contains proprietary technology.
Unauthorized distribution or reverse engineering is prohibited.
EOF

# Create license generation template
cat > dist/secure/generate-license-template.py << 'EOF'
#!/usr/bin/env python3
"""
License Generation Template for QGEN_IMPFRAG
===========================================

Use this template to generate client licenses with hardware fingerprinting
"""

import json
import hashlib
import uuid
import hmac
from datetime import datetime, timedelta
import base64

def generate_hardware_fingerprint():
    """Generate unique hardware fingerprint"""
    # In production, collect real hardware info
    mac = uuid.getnode()
    # Add CPU info, motherboard serial, etc.
    fingerprint = f"hw-{mac}-example"
    return hashlib.sha256(fingerprint.encode()).hexdigest()

def generate_license(client_id, hardware_id, days_valid=30, secret_key="change-this-secret"):
    """Generate time-limited, hardware-locked license"""
    
    issued_at = datetime.utcnow()
    expires_at = issued_at + timedelta(days=days_valid)
    
    license_data = {
        "client_id": client_id,
        "hardware_id": hardware_id,
        "issued_at": issued_at.isoformat(),
        "expires_at": expires_at.isoformat(),
        "features": ["ifc_processing", "3d_viewer", "api_access"],
        "version": "1.0.0"
    }
    
    # Create HMAC signature
    license_json = json.dumps(license_data, sort_keys=True)
    signature = hmac.new(
        secret_key.encode(),
        license_json.encode(),
        hashlib.sha256
    ).hexdigest()
    
    license_data["signature"] = signature
    
    # Encode as base64 for easy distribution
    license_b64 = base64.b64encode(json.dumps(license_data).encode()).decode()
    
    return license_data, license_b64

# Example usage
if __name__ == "__main__":
    client_id = input("Enter client ID: ")
    hardware_id = generate_hardware_fingerprint()
    days_valid = int(input("Enter license validity (days): "))
    
    license_data, license_key = generate_license(client_id, hardware_id, days_valid)
    
    # Save license file
    with open("license.key", "w") as f:
        f.write(license_key)
    
    print(f"✅ License generated for client: {client_id}")
    print(f"   Hardware ID: {hardware_id}")
    print(f"   Expires: {license_data['expires_at']}")
    print(f"   License file: license.key")
EOF

chmod +x dist/secure/generate-license-template.py

# Create distribution package
echo ""
echo "📦 Creating secure distribution package..."
cd dist/secure
tar -czf "../qgen-impfrag-secure-${VERSION}-${BUILD_DATE}.tar.gz" ./*
cd "$PROJECT_ROOT"

echo ""
echo "🎉 Secure Build Complete!"
echo "========================"
echo ""
echo "📋 Security Features Implemented:"
echo "   ✅ Container encryption (GPG/AES256)"
echo "   ✅ JavaScript obfuscation and minification"
echo "   ✅ Python bytecode compilation"
echo "   ✅ Hardware fingerprinting system"
echo "   ✅ Time-limited licensing"
echo ""
echo "📦 Distribution Files:"
echo "   🔐 Encrypted Container: dist/secure/qgen-impfrag-${VERSION}-${BUILD_DATE}.tar.gz.gpg"
echo "   📄 Client Package: dist/qgen-impfrag-secure-${VERSION}-${BUILD_DATE}.tar.gz"
echo "   🔧 Deployment Script: dist/secure/deploy-secure.sh"
echo "   📖 Documentation: dist/secure/README-SECURE.md"
echo ""
echo "🔑 Next Steps:"
echo "   1. Test deployment with: cd dist/secure && ./deploy-secure.sh"
echo "   2. Generate client licenses with: python3 generate-license-template.py"
echo "   3. Distribute client package to authorized users"
echo ""
echo "⚠️  Important:"
echo "   - Keep the deployment password secure"
echo "   - Generate unique licenses for each client"
echo "   - Implement proper license server for production"
