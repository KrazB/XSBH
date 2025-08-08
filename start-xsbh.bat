@echo off
echo =================================
echo  XSBH - BIM Fragment Viewer
echo  Quick Start for Windows
echo =================================
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker is not installed or not running.
    echo Please install Docker Desktop from: https://www.docker.com/products/docker-desktop/
    echo.
    pause
    exit /b 1
)

echo ✅ Docker is available
echo.

REM Check if Docker Desktop is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker Desktop is not running.
    echo Please start Docker Desktop and try again.
    echo.
    pause
    exit /b 1
)

echo ✅ Docker Desktop is running
echo.

REM Stop any existing containers
echo 🛑 Stopping any existing XSBH containers...
docker-compose down >nul 2>&1

REM Start the application
echo 🚀 Starting XSBH BIM Fragment Viewer...
docker-compose up -d

if %errorlevel% equ 0 (
    echo.
    echo ✅ XSBH is starting up!
    echo.
    echo 📖 Access the viewer at: http://localhost:8080
    echo.
    echo 🔧 Useful commands:
    echo    docker-compose logs xsbh-viewer    # View application logs
    echo    docker-compose restart             # Restart the application
    echo    docker-compose down                # Stop the application
    echo.
    echo ⏳ Please wait 30-60 seconds for the application to fully start...
    echo.
    
    REM Wait a moment then try to open browser
    timeout /t 5 /nobreak >nul
    echo 🌐 Opening browser...
    start http://localhost:8080
    
) else (
    echo.
    echo ❌ Failed to start XSBH. Check the error messages above.
    echo.
    echo 🔍 Troubleshooting:
    echo    1. Ensure port 8080 is not in use
    echo    2. Check Docker Desktop is running properly
    echo    3. Try: docker-compose logs xsbh-viewer
    echo.
)

echo.
echo Press any key to exit...
pause >nul
