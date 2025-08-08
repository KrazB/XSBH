@echo off
:: XSBH Update Script - Run this in your XSBH repository folder
:: Syncs all changes from XFRG automation pipeline
:: Generated: August 8, 2025

echo.
echo ===============================================
echo 🔄 XSBH Repository Update from XFRG Pipeline
echo ===============================================
echo.

:: Step 1: Sync Frontend
echo 📁 Syncing frontend source code...
robocopy "D:\XFRG\frontend\src" "frontend\src" /E /XO
copy "D:\XFRG\frontend\package.json" "frontend\package.json" /Y
robocopy "D:\XFRG\frontend\public" "frontend\public" /E /XO

:: Step 2: Sync Backend  
echo ⚙️  Syncing backend source code...
robocopy "D:\XFRG\backend" "backend" /E /XO

:: Step 3: Update Docker
echo 🐳 Updating Docker configuration...
copy "D:\XFRG\docker-compose.prod.yml" "docker-compose.yml" /Y
copy "D:\XFRG\Dockerfile.prod" "Dockerfile" /Y
robocopy "D:\XFRG\docker" "docker" /E /XO

:: Step 4: Sync Scripts
echo 🛠️  Syncing automation scripts...
robocopy "D:\XFRG\scripts" "scripts" /E /XO

:: Step 5: Clean Development Files
echo 🧹 Cleaning development-only files...
del "frontend\debug_api.js" >nul 2>nul
del "frontend\test_itemsfinder.ts" >nul 2>nul
del "frontend\check_exports.js" >nul 2>nul
del "frontend\corrected_function.ts" >nul 2>nul
del "frontend\fixed_function.ts" >nul 2>nul
if exist "logs" rmdir /s /q "logs" >nul 2>nul
if exist "temp" rmdir /s /q "temp" >nul 2>nul

:: Step 6: Test Build
echo 🔨 Testing frontend build...
cd frontend
call npm install
call npm run build
cd ..

echo.
echo ✅ Sync completed! Ready for git commit.
echo.
echo 📝 Suggested commit message:
echo "🚀 Complete Automation Pipeline + Production Infrastructure"
echo.
echo Run: git add . && git commit -m "..." && git push
pause
