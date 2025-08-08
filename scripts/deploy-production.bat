@echo off
:: Production Deployment Script for XSBH
:: Handles complete production deployment with health checks and rollback
:: Author: XQG4_AXIS Team
:: Version: 1.0.0

setlocal enabledelayedexpansion

:: Configuration
set "XFRG_ROOT=D:\XFRG"
set "XSBH_ROOT=D:\XSBH"
set "DEPLOY_LOG=%XFRG_ROOT%\logs\deployment.log"
set "DEPLOY_MODE=%1"
set "DOMAIN=%2"

:: Default values
if "%DEPLOY_MODE%"=="" set "DEPLOY_MODE=staging"
if "%DOMAIN%"=="" set "DOMAIN=localhost"

:: Colors
set "COLOR_SUCCESS=0A"
set "COLOR_WARNING=0E"
set "COLOR_ERROR=0C"
set "COLOR_INFO=0B"

echo.
echo ===============================================
echo 🚀 XSBH Production Deployment Pipeline
echo ===============================================
echo Deploy Mode: %DEPLOY_MODE%
echo Domain: %DOMAIN%
echo.

:: Create logs directory
if not exist "%XFRG_ROOT%\logs" mkdir "%XFRG_ROOT%\logs"

:: Log header
echo [%date% %time%] Starting deployment - Mode: %DEPLOY_MODE%, Domain: %DOMAIN% >> "%DEPLOY_LOG%"

:: Validate deployment mode
if /i "%DEPLOY_MODE%"=="staging" goto :deploy_staging
if /i "%DEPLOY_MODE%"=="production" goto :deploy_production
if /i "%DEPLOY_MODE%"=="rollback" goto :rollback
if /i "%DEPLOY_MODE%"=="health" goto :health_check

echo ❌ Invalid deployment mode: %DEPLOY_MODE%
echo Valid modes: staging, production, rollback, health
exit /b 1

:deploy_staging
color %COLOR_INFO%
echo 📋 Deploying to Staging Environment...

:: Pre-deployment checks
call :pre_deployment_checks
if !errorlevel! neq 0 goto :error

:: Build and sync
echo   🔨 Building latest version...
call "%XFRG_ROOT%\scripts\build-automation.bat" all >>"%DEPLOY_LOG%" 2>&1
if !errorlevel! neq 0 (
    echo ❌ Build failed
    goto :error
)

:: Deploy with development compose
cd /d "%XSBH_ROOT%"
echo   🐳 Starting staging containers...
docker-compose down >>"%DEPLOY_LOG%" 2>&1
docker-compose up -d >>"%DEPLOY_LOG%" 2>&1
if !errorlevel! neq 0 (
    echo ❌ Staging deployment failed
    goto :error
)

call :wait_for_services "http://localhost:3111" "http://localhost:8111"
goto :success

:deploy_production
color %COLOR_WARNING%
echo 📋 Deploying to Production Environment...
echo ⚠️  WARNING: This will deploy to production!
echo.
set /p confirm="Are you sure you want to continue? (y/N): "
if /i not "%confirm%"=="y" (
    echo Deployment cancelled
    exit /b 0
)

:: Pre-deployment checks
call :pre_deployment_checks
if !errorlevel! neq 0 goto :error

:: Backup current deployment
echo   💾 Creating backup...
call :backup_deployment
if !errorlevel! neq 0 goto :error

:: Build and sync
echo   🔨 Building production version...
call "%XFRG_ROOT%\scripts\build-automation.bat" all >>"%DEPLOY_LOG%" 2>&1
if !errorlevel! neq 0 (
    echo ❌ Production build failed
    goto :error
)

:: Copy production files
echo   📋 Copying production configuration...
copy "%XFRG_ROOT%\docker-compose.prod.yml" "%XSBH_ROOT%\docker-compose.prod.yml" >>"%DEPLOY_LOG%" 2>&1
copy "%XFRG_ROOT%\Dockerfile.prod" "%XSBH_ROOT%\Dockerfile.prod" >>"%DEPLOY_LOG%" 2>&1
if not exist "%XSBH_ROOT%\docker" mkdir "%XSBH_ROOT%\docker"
copy "%XFRG_ROOT%\docker\nginx.prod.conf" "%XSBH_ROOT%\docker\nginx.prod.conf" >>"%DEPLOY_LOG%" 2>&1

:: Deploy with production compose
cd /d "%XSBH_ROOT%"
echo   🐳 Starting production containers...
docker-compose -f docker-compose.prod.yml down >>"%DEPLOY_LOG%" 2>&1
docker-compose -f docker-compose.prod.yml up -d >>"%DEPLOY_LOG%" 2>&1
if !errorlevel! neq 0 (
    echo ❌ Production deployment failed
    call :rollback
    goto :error
)

call :wait_for_services "http://%DOMAIN%" "http://%DOMAIN%/api"
goto :success

:rollback
color %COLOR_WARNING%
echo 📋 Rolling back deployment...
echo [%date% %time%] Starting rollback >> "%DEPLOY_LOG%"

cd /d "%XSBH_ROOT%"
echo   🔄 Stopping current containers...
docker-compose -f docker-compose.prod.yml down >>"%DEPLOY_LOG%" 2>&1

echo   📦 Restoring from backup...
if exist "backup\docker-compose.yml" (
    copy "backup\docker-compose.yml" "docker-compose.yml" >>"%DEPLOY_LOG%" 2>&1
    docker-compose up -d >>"%DEPLOY_LOG%" 2>&1
    echo   ✅ Rollback completed
) else (
    echo   ❌ No backup found - manual intervention required
    goto :error
)
exit /b 0

:health_check
color %COLOR_INFO%
echo 📋 Performing Health Check...

:: Check if containers are running
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | findstr xsbh >>"%DEPLOY_LOG%" 2>&1

:: Check endpoints
call :check_endpoint "http://localhost:3111" "Frontend"
call :check_endpoint "http://localhost:8111/health" "Backend"

goto :success

:pre_deployment_checks
echo   🔍 Running pre-deployment checks...

:: Check Docker
docker --version >nul 2>&1
if !errorlevel! neq 0 (
    echo ❌ Docker not found
    exit /b 1
)

:: Check disk space (simplified)
echo   📊 Checking system resources...
dir "%XSBH_ROOT%" >nul 2>&1
if !errorlevel! neq 0 (
    echo ❌ XSBH directory not accessible
    exit /b 1
)

echo   ✅ Pre-deployment checks passed
exit /b 0

:backup_deployment
echo   💾 Creating deployment backup...
if not exist "%XSBH_ROOT%\backup" mkdir "%XSBH_ROOT%\backup"

cd /d "%XSBH_ROOT%"
if exist "docker-compose.yml" copy "docker-compose.yml" "backup\docker-compose.yml" >>"%DEPLOY_LOG%" 2>&1

echo   ✅ Backup created
exit /b 0

:wait_for_services
set "frontend_url=%~1"
set "backend_url=%~2"
echo   ⏱️  Waiting for services to start...

:: Wait up to 120 seconds for services
set /a attempts=0
:wait_loop
set /a attempts+=1
if %attempts% gtr 24 (
    echo ❌ Services failed to start within 120 seconds
    exit /b 1
)

:: Simple check using curl if available, otherwise just wait
timeout /t 5 /nobreak >nul 2>&1
curl -s "%frontend_url%" >nul 2>&1
if !errorlevel! equ 0 (
    echo   ✅ Services are responding
    exit /b 0
)

echo   ⏳ Attempt %attempts%/24 - waiting...
goto :wait_loop

:check_endpoint
set "url=%~1"
set "name=%~2"
echo   🔍 Checking %name%: %url%

curl -s "%url%" >nul 2>&1
if !errorlevel! equ 0 (
    echo     ✅ %name% is healthy
) else (
    echo     ❌ %name% is not responding
)
exit /b 0

:success
color %COLOR_SUCCESS%
echo.
echo ===============================================
echo ✅ DEPLOYMENT COMPLETED SUCCESSFULLY!
echo ===============================================
echo.
echo 📊 Deployment Summary:
echo   • Mode: %DEPLOY_MODE%
echo   • Domain: %DOMAIN%
echo   • Status: ✅ Success
echo.
if /i "%DEPLOY_MODE%"=="staging" (
    echo 🌐 Access your application:
    echo   • Frontend: http://localhost:3111
    echo   • Backend API: http://localhost:8111
) else if /i "%DEPLOY_MODE%"=="production" (
    echo 🌐 Access your application:
    echo   • Frontend: http://%DOMAIN%
    echo   • Backend API: http://%DOMAIN%/api
)
echo.
echo [%date% %time%] Deployment completed successfully >> "%DEPLOY_LOG%"
goto :end

:error
color %COLOR_ERROR%
echo.
echo ===============================================
echo ❌ DEPLOYMENT FAILED
echo ===============================================
echo.
echo 📋 Check the deployment log for details: %DEPLOY_LOG%
echo [%date% %time%] Deployment failed with errors >> "%DEPLOY_LOG%"
exit /b 1

:end
color
echo.
echo Press any key to continue...
pause >nul
exit /b 0
