@echo off
chcp 65001 >nul
echo ========================================
echo   Home-SXLB 一键构建脚本
echo ========================================
echo.

echo [1/5] 构建前端...
cd /d "%~dp0frontend"
call npm install
call npm run build
if %errorlevel% neq 0 (
    echo 前端构建失败！
    pause
    exit /b 1
)

echo [2/5] 构建管理后台...
cd /d "%~dp0admin"
call npm install
call npm run build
if %errorlevel% neq 0 (
    echo 管理后台构建失败！
    pause
    exit /b 1
)

echo [3/5] 构建后端...
cd /d "%~dp0backend"
call npm install
call npm run build
if %errorlevel% neq 0 (
    echo 后端构建失败！
    pause
    exit /b 1
)

echo [4/5] 初始化数据库...
call npm run init-db

echo [5/5] 启动服务...
echo.
echo ========================================
echo   构建完成！
echo ========================================
echo.
echo 启动方式（选择一个）：
echo.
echo   开发模式：  cd backend ^&^& npm run dev
echo   生产模式：  cd backend ^&^& npm start
echo.
echo 访问地址：
echo   前台: http://localhost:3001
echo   后台: http://localhost:3001/admin
echo   账号: admin / admin123
echo.
pause
