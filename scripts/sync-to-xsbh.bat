@echo off
:: XFRG → XSBH Sync Automation Script
:: Synchronizes development changes from XFRG to XSBH distribution repository
:: Author: XQG4_AXIS Team
:: Version: 1.0.0

setlocal enabledelayedexpansion

:: Configuration
set "XFRG_ROOT=D:\XFRG"
set "XSBH_ROOT=D:\XSBH"
set "LOG_FILE=%XFRG_ROOT%\logs\sync-to-xsbh.log"

:: Colors for output
set "COLOR_SUCCESS=0A"
set "COLOR_WARNING=0E"
set "COLOR_ERROR=0C"
set "COLOR_INFO=0B"

echo.
echo ===============================================
echo 🔄 XFRG → XSBH Sync Pipeline
echo ===============================================
echo.

:: Create logs directory if it doesn't exist
if not exist "%XFRG_ROOT%\logs" mkdir "%XFRG_ROOT%\logs"

:: Log header
echo [%date% %time%] Starting XFRG → XSBH sync pipeline >> "%LOG_FILE%"

:: Check if XSBH directory exists
if not exist "%XSBH_ROOT%" (
    color %COLOR_ERROR%
    echo ❌ ERROR: XSBH directory not found at %XSBH_ROOT%
    echo [%date% %time%] ERROR: XSBH directory not found >> "%LOG_FILE%"
    pause
    exit /b 1
)

color %COLOR_INFO%
echo 📋 Step 1: Syncing core application files...
echo [%date% %time%] Syncing core application files >> "%LOG_FILE%"

:: Sync frontend source code (main application)
echo   📁 Syncing frontend source code...
robocopy "%XFRG_ROOT%\frontend\src" "%XSBH_ROOT%\frontend\src" /E /XO /R:3 /W:1 /NP /LOG+:"%LOG_FILE%" >nul
if !errorlevel! geq 8 (
    color %COLOR_ERROR%
    echo ❌ Failed to sync frontend source code
    goto :error
)

:: Sync frontend package.json (dependencies)
echo   📦 Syncing frontend package.json...
copy "%XFRG_ROOT%\frontend\package.json" "%XSBH_ROOT%\frontend\package.json" /Y >nul 2>nul
if !errorlevel! neq 0 (
    color %COLOR_WARNING%
    echo ⚠️  Warning: Could not update frontend package.json
)

:: Sync frontend public assets
echo   🎨 Syncing frontend public assets...
robocopy "%XFRG_ROOT%\frontend\public" "%XSBH_ROOT%\frontend\public" /E /XO /R:3 /W:1 /NP /LOG+:"%LOG_FILE%" >nul

:: Sync backend source code
echo   ⚙️  Syncing backend source code...
robocopy "%XFRG_ROOT%\backend" "%XSBH_ROOT%\backend" /E /XO /R:3 /W:1 /NP /LOG+:"%LOG_FILE%" >nul
if !errorlevel! geq 8 (
    color %COLOR_ERROR%
    echo ❌ Failed to sync backend source code
    goto :error
)

:: Sync Docker configuration
echo   🐳 Syncing Docker configuration...
copy "%XFRG_ROOT%\Dockerfile" "%XSBH_ROOT%\Dockerfile" /Y >nul 2>nul
copy "%XFRG_ROOT%\docker-compose.yml" "%XSBH_ROOT%\docker-compose.yml" /Y >nul 2>nul
copy "%XFRG_ROOT%\.dockerignore" "%XSBH_ROOT%\.dockerignore" /Y >nul 2>nul

:: Sync Docker support files
echo   🛠️  Syncing Docker support files...
robocopy "%XFRG_ROOT%\docker" "%XSBH_ROOT%\docker" /E /XO /R:3 /W:1 /NP /LOG+:"%LOG_FILE%" >nul
robocopy "%XFRG_ROOT%\scripts" "%XSBH_ROOT%\scripts" /E /XO /R:3 /W:1 /NP /LOG+:"%LOG_FILE%" >nul

color %COLOR_INFO%
echo.
echo 📋 Step 2: Cleaning up development-only files...
echo [%date% %time%] Cleaning development files from XSBH >> "%LOG_FILE%"

:: Remove development-only files from XSBH
del "%XSBH_ROOT%\frontend\debug_api.js" >nul 2>nul
del "%XSBH_ROOT%\frontend\test_itemsfinder.ts" >nul 2>nul
del "%XSBH_ROOT%\frontend\check_exports.js" >nul 2>nul
del "%XSBH_ROOT%\frontend\corrected_function.ts" >nul 2>nul
del "%XSBH_ROOT%\frontend\fixed_function.ts" >nul 2>nul

:: Remove development logs and temp files
if exist "%XSBH_ROOT%\logs" rmdir /s /q "%XSBH_ROOT%\logs" >nul 2>nul
if exist "%XSBH_ROOT%\temp" rmdir /s /q "%XSBH_ROOT%\temp" >nul 2>nul

color %COLOR_INFO%
echo.
echo 📋 Step 3: Verifying XSBH build compatibility...
echo [%date% %time%] Testing XSBH build >> "%LOG_FILE%"

:: Test frontend build
echo   🔨 Testing frontend build...
cd /d "%XSBH_ROOT%\frontend"
call npm install --silent >nul 2>nul
call npm run build >nul 2>>"%LOG_FILE%"
if !errorlevel! neq 0 (
    color %COLOR_ERROR%
    echo ❌ Frontend build failed - check log for details
    goto :error
)

color %COLOR_SUCCESS%
echo.
echo ===============================================
echo ✅ XFRG → XSBH Sync Completed Successfully!
echo ===============================================
echo.
echo 📊 Summary:
echo   • Frontend source code synced
echo   • Backend source code synced  
echo   • Docker configuration updated
echo   • Development files cleaned
echo   • Build compatibility verified
echo.
echo 🎯 XSBH is ready for deployment!
echo.
echo [%date% %time%] Sync completed successfully >> "%LOG_FILE%"

goto :end

:error
color %COLOR_ERROR%
echo.
echo ===============================================
echo ❌ SYNC FAILED
echo ===============================================
echo.
echo Check the log file for details: %LOG_FILE%
echo [%date% %time%] Sync failed with errors >> "%LOG_FILE%"
pause
exit /b 1

:end
color
echo Press any key to continue...
pause >nul
exit /b 0
