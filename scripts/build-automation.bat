@echo off
:: Build Automation Script for XFRG/XSBH Projects
:: Handles building, testing, and packaging for both development and distribution
:: Author: XQG4_AXIS Team
:: Version: 1.0.0

setlocal enabledelayedexpansion

:: Configuration
set "XFRG_ROOT=D:\XFRG"
set "XSBH_ROOT=D:\XSBH"
set "BUILD_LOG=%XFRG_ROOT%\logs\build-automation.log"
set "BUILD_MODE=%1"

:: Default to 'all' if no parameter provided
if "%BUILD_MODE%"=="" set "BUILD_MODE=all"

:: Colors
set "COLOR_SUCCESS=0A"
set "COLOR_WARNING=0E"
set "COLOR_ERROR=0C"
set "COLOR_INFO=0B"

echo.
echo ===============================================
echo 🔨 XFRG/XSBH Build Automation Pipeline
echo ===============================================
echo Build Mode: %BUILD_MODE%
echo.

:: Create logs directory
if not exist "%XFRG_ROOT%\logs" mkdir "%XFRG_ROOT%\logs"

:: Log header
echo [%date% %time%] Starting build automation - Mode: %BUILD_MODE% >> "%BUILD_LOG%"

:: Parse build mode
if /i "%BUILD_MODE%"=="xfrg" goto :build_xfrg
if /i "%BUILD_MODE%"=="xsbh" goto :build_xsbh
if /i "%BUILD_MODE%"=="docker" goto :build_docker
if /i "%BUILD_MODE%"=="all" goto :build_all
if /i "%BUILD_MODE%"=="test" goto :test_only

echo ❌ Invalid build mode: %BUILD_MODE%
echo Valid modes: xfrg, xsbh, docker, all, test
exit /b 1

:build_all
color %COLOR_INFO%
echo 📋 Building all components...
call :build_xfrg
if !errorlevel! neq 0 goto :error
call :sync_to_xsbh
if !errorlevel! neq 0 goto :error
call :build_xsbh
if !errorlevel! neq 0 goto :error
call :build_docker
if !errorlevel! neq 0 goto :error
goto :success

:build_xfrg
color %COLOR_INFO%
echo.
echo 📋 Step 1: Building XFRG (Development)
echo [%date% %time%] Building XFRG >> "%BUILD_LOG%"

echo   📦 Installing XFRG frontend dependencies...
cd /d "%XFRG_ROOT%\frontend"
call npm install >>"%BUILD_LOG%" 2>&1
if !errorlevel! neq 0 (
    echo ❌ Failed to install XFRG frontend dependencies
    goto :error
)

echo   🔨 Building XFRG frontend...
call npm run build >>"%BUILD_LOG%" 2>&1
if !errorlevel! neq 0 (
    echo ❌ XFRG frontend build failed
    goto :error
)

echo   ⚙️  Testing XFRG backend...
cd /d "%XFRG_ROOT%\backend"
python -c "import app; print('✅ Backend import successful')" >>"%BUILD_LOG%" 2>&1
if !errorlevel! neq 0 (
    echo ❌ XFRG backend test failed
    goto :error
)

echo   ✅ XFRG build completed
exit /b 0

:sync_to_xsbh
echo.
echo 🔄 Syncing XFRG → XSBH...
echo [%date% %time%] Syncing to XSBH >> "%BUILD_LOG%"
call "%XFRG_ROOT%\scripts\sync-to-xsbh.bat" >>"%BUILD_LOG%" 2>&1
if !errorlevel! neq 0 (
    echo ❌ Sync to XSBH failed
    goto :error
)
echo   ✅ Sync completed
exit /b 0

:build_xsbh
color %COLOR_INFO%
echo.
echo 📋 Step 2: Building XSBH (Distribution)
echo [%date% %time%] Building XSBH >> "%BUILD_LOG%"

if not exist "%XSBH_ROOT%" (
    echo ❌ XSBH directory not found: %XSBH_ROOT%
    goto :error
)

echo   📦 Installing XSBH frontend dependencies...
cd /d "%XSBH_ROOT%\frontend"
call npm install >>"%BUILD_LOG%" 2>&1
if !errorlevel! neq 0 (
    echo ❌ Failed to install XSBH frontend dependencies
    goto :error
)

echo   🔨 Building XSBH frontend...
call npm run build >>"%BUILD_LOG%" 2>&1
if !errorlevel! neq 0 (
    echo ❌ XSBH frontend build failed
    goto :error
)

echo   ⚙️  Testing XSBH backend...
cd /d "%XSBH_ROOT%\backend"
python -c "import app; print('✅ XSBH Backend import successful')" >>"%BUILD_LOG%" 2>&1
if !errorlevel! neq 0 (
    echo ❌ XSBH backend test failed
    goto :error
)

echo   ✅ XSBH build completed
exit /b 0

:build_docker
color %COLOR_INFO%
echo.
echo 📋 Step 3: Building Docker Image
echo [%date% %time%] Building Docker >> "%BUILD_LOG%"

cd /d "%XSBH_ROOT%"
echo   🐳 Building Docker image...
docker-compose build >>"%BUILD_LOG%" 2>&1
if !errorlevel! neq 0 (
    echo ❌ Docker build failed
    goto :error
)

echo   ✅ Docker build completed
exit /b 0

:test_only
color %COLOR_INFO%
echo.
echo 📋 Running Tests Only
echo [%date% %time%] Running tests >> "%BUILD_LOG%"

echo   🧪 Testing XFRG frontend...
cd /d "%XFRG_ROOT%\frontend"
call npm run build >>"%BUILD_LOG%" 2>&1
if !errorlevel! neq 0 (
    echo ❌ XFRG frontend test failed
    goto :error
)

echo   🧪 Testing XSBH frontend...
cd /d "%XSBH_ROOT%\frontend"
call npm run build >>"%BUILD_LOG%" 2>&1
if !errorlevel! neq 0 (
    echo ❌ XSBH frontend test failed
    goto :error
)

echo   ✅ All tests passed
goto :success

:success
color %COLOR_SUCCESS%
echo.
echo ===============================================
echo ✅ BUILD AUTOMATION COMPLETED SUCCESSFULLY!
echo ===============================================
echo.
echo 📊 Build Summary:
if /i "%BUILD_MODE%"=="all" (
    echo   • XFRG Development Build: ✅ Success
    echo   • XFRG → XSBH Sync: ✅ Success
    echo   • XSBH Distribution Build: ✅ Success
    echo   • Docker Image Build: ✅ Success
) else (
    echo   • Build Mode '%BUILD_MODE%': ✅ Success
)
echo.
echo 🎯 Ready for deployment!
echo [%date% %time%] Build automation completed successfully >> "%BUILD_LOG%"
goto :end

:error
color %COLOR_ERROR%
echo.
echo ===============================================
echo ❌ BUILD FAILED
echo ===============================================
echo.
echo 📋 Check the build log for details: %BUILD_LOG%
echo [%date% %time%] Build failed with errors >> "%BUILD_LOG%"
exit /b 1

:end
color
echo.
echo Press any key to continue...
pause >nul
exit /b 0
