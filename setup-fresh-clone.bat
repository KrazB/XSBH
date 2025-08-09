@echo off
echo ================================================
echo     XSBH Setup Script - Fix Missing Directories
echo ================================================
echo.
echo Creating necessary directories...
if not exist "data" mkdir data
if not exist "data\fragments" mkdir data\fragments  
if not exist "data\ifc" mkdir data\ifc
if not exist "user-fragments" mkdir user-fragments
echo.
echo ? Directory structure verified
echo.
echo Starting Docker build...
docker-compose down
docker-compose build --no-cache
echo.
echo Starting containers...
docker-compose up -d
echo.
echo ? XSBH deployment complete!
echo    Frontend: http://localhost:8080
echo    Backend:  http://localhost:8111  
echo.
pause
