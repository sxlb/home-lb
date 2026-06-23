@echo off
title Home-SXLB Builder
echo ========================================
echo   Home-SXLB Build Script
echo ========================================
echo.

set "ROOT=%~dp0"

echo [1/6] Building frontend...
cd /d "%ROOT%frontend"
call npm install
if %errorlevel% neq 0 (
    echo Frontend install failed!
    pause
    exit /b 1
)
call npm run build
if %errorlevel% neq 0 (
    echo Frontend build failed!
    pause
    exit /b 1
)
echo Frontend build OK.

echo [2/6] Building admin...
cd /d "%ROOT%admin"
call npm install
if %errorlevel% neq 0 (
    echo Admin install failed!
    pause
    exit /b 1
)
call npm run build
if %errorlevel% neq 0 (
    echo Admin build failed!
    pause
    exit /b 1
)
echo Admin build OK.

echo [3/6] Building backend...
cd /d "%ROOT%backend"
call npm install
if %errorlevel% neq 0 (
    echo Backend install failed!
    pause
    exit /b 1
)
call npm run build
if %errorlevel% neq 0 (
    echo Backend build failed!
    pause
    exit /b 1
)
echo Backend build OK.

echo [4/6] Init database...
call npm run init-db
if %errorlevel% neq 0 (
    echo Database init skipped or failed.
)

echo [5/6] Starting server...
echo Server running at http://localhost:3001
echo Press Ctrl+C to stop.
echo.
cd /d "%ROOT%backend"
call npm start

pause
