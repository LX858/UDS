@echo off
REM LB Phone UI - Quick Start Setup Script for Windows
REM This script sets up the development environment

echo.
echo 🚀 Setting up LB Phone UI...
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed. Please install Node.js v16 or higher.
    echo    Download from: https://nodejs.org/
    pause
    exit /b 1
)

echo ✅ Node.js version:
node --version

echo ✅ npm version:
npm --version

echo.
echo 📦 Installing dependencies...
npm install

if %errorlevel% equ 0 (
    echo.
    echo ✅ Dependencies installed successfully!
) else (
    echo.
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo ========================================================
echo ✨ Setup complete!
echo ========================================================
echo.
echo Next steps:
echo   1. Development:  npm run dev
echo   2. Build:        npm run build
echo   3. Preview:      npm run preview
echo.
echo For more info, see RECOVERY_GUIDE.md
echo.
pause
