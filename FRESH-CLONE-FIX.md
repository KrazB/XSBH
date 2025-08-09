# XSBH Fresh Clone Setup Instructions

## Problem Solved
Your colleague was experiencing Docker build failures because the Dockerfile was trying to copy directories that don't exist in a fresh git clone.

## Solution for Fresh Clones

### Option 1: Use the Setup Script (Recommended)
```
# After cloning XSBH repository:
cd XSBH
setup-fresh-clone.bat
```

### Option 2: Manual Steps
```
# 1. Create missing directories
mkdir data\fragments
mkdir data\ifc
mkdir user-fragments

# 2. Build and run
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## What Was Fixed
1. **Dockerfile.simple**: Removed dependency on optional data directories
2. **setup-fresh-clone.bat**: Automated script to create directories and deploy
3. **Directory structure**: Ensures all required directories exist

## Access Points
- Frontend: http://localhost:8080
- Backend API: http://localhost:8111

## Verified Working
? Fresh git clone compatibility
? Docker build success
? Frontend + Backend deployment
? IFC conversion functionality
