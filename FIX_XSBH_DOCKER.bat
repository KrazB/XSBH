@echo off
:: Quick Fix for XSBH Docker Configuration
:: Run this in your XSBH repository to fix the Dockerfile.prod error

echo.
echo ===============================================
echo 🔧 XSBH Docker Configuration Fix
echo ===============================================
echo.

echo 📋 Fixing Docker configuration...

:: Rename Dockerfile.prod to Dockerfile if it exists
if exist "Dockerfile.prod" (
    echo   📄 Renaming Dockerfile.prod to Dockerfile...
    copy "Dockerfile.prod" "Dockerfile" /Y
)

:: Create simple docker-compose.yml for XSBH
echo   📄 Creating XSBH-compatible docker-compose.yml...
echo # XSBH - Simple BIM Fragment Viewer > docker-compose.yml
echo version: '3.8' >> docker-compose.yml
echo. >> docker-compose.yml
echo services: >> docker-compose.yml
echo   xsbh-viewer: >> docker-compose.yml
echo     build: . >> docker-compose.yml
echo     container_name: xsbh-bim-viewer >> docker-compose.yml
echo     ports: >> docker-compose.yml
echo       - "8080:80" >> docker-compose.yml
echo     volumes: >> docker-compose.yml
echo       - ./data:/app/data >> docker-compose.yml
echo       - ./user-fragments:/app/data/fragments >> docker-compose.yml
echo     environment: >> docker-compose.yml
echo       - NODE_ENV=production >> docker-compose.yml
echo       - FRAGMENTS_DATA_DIR=/app/data >> docker-compose.yml
echo     restart: unless-stopped >> docker-compose.yml
echo     healthcheck: >> docker-compose.yml
echo       test: ["CMD", "curl", "-f", "http://localhost:80/health"] >> docker-compose.yml
echo       interval: 30s >> docker-compose.yml
echo       timeout: 10s >> docker-compose.yml
echo       retries: 3 >> docker-compose.yml
echo       start_period: 60s >> docker-compose.yml
echo. >> docker-compose.yml
echo volumes: >> docker-compose.yml
echo   user-fragments: >> docker-compose.yml
echo     driver: local >> docker-compose.yml

echo.
echo ✅ Docker configuration fixed!
echo.
echo 🚀 Now try running: start-xsbh.bat
echo.
pause
