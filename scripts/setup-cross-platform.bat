@echo off
REM QGEN_IMPFRAG Windows Setup Script
REM ==================================
REM Automatically configures the application for Windows environment

setlocal

echo [INFO] QGEN_IMPFRAG Windows Setup
echo ==============================

REM Check Python availability
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python not found! Please install Python 3.7 or higher
    exit /b 1
)

echo [SUCCESS] Python found

REM Run environment manager
echo [INFO] Configuring environment...
python scripts\environment-manager.py --config

REM Generate environment file
echo [INFO] Generating environment configuration...
python scripts\environment-manager.py --env

REM Check for Docker
echo [INFO] Checking Docker availability...
docker --version >nul 2>&1
if %errorlevel% eq 0 (
    echo [SUCCESS] Docker is available
    docker-compose --version >nul 2>&1
    if %errorlevel% eq 0 (
        echo [SUCCESS] Docker Compose is available
    ) else (
        echo [WARNING] Docker Compose not found - Docker stack may not work
    )
) else (
    echo [WARNING] Docker not found - containerized deployment unavailable
)

REM Check Node.js for frontend
echo [INFO] Checking Node.js for frontend...
npm --version >nul 2>&1
if %errorlevel% eq 0 (
    echo [SUCCESS] Node.js/NPM found
    REM Install frontend dependencies
    echo [INFO] Installing frontend dependencies...
    cd frontend
    npm install
    cd ..
    echo [SUCCESS] Frontend dependencies installed
) else (
    echo [WARNING] Node.js/NPM not found - frontend may not build
)

REM Setup Python environment
echo [INFO] Setting up Python environment...
cd backend

REM Create virtual environment if it doesn't exist
if not exist "venv" (
    echo [INFO] Creating Python virtual environment...
    python -m venv venv
)

REM Activate virtual environment
call venv\Scripts\activate.bat

REM Install Python dependencies
echo [INFO] Installing Python dependencies...
pip install -r requirements.txt

cd ..
echo [SUCCESS] Python environment configured

REM Create necessary directories
echo [INFO] Creating data directories...
if not exist "data\ifc" mkdir data\ifc
if not exist "data\fragments" mkdir data\fragments
if not exist "data\reports" mkdir data\reports
if not exist "backend\logs" mkdir backend\logs
echo [SUCCESS] Data directories created

REM Final status
echo.
echo [SUCCESS] QGEN_IMPFRAG setup complete!
echo.
echo Next steps:
echo 1. Review the generated .env.auto file
echo 2. Start the backend: cd backend ^&^& python app.py
echo 3. Start the frontend: cd frontend ^&^& npm run dev
echo 4. Or use Docker: docker-compose up
echo.
echo For more information, see README.md

pause
