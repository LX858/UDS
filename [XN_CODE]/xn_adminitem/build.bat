@echo off
echo ================================
echo Building XN Admin Item UI
echo ================================
echo.

cd /d "%~dp0web"

echo Installing dependencies...
call npm install

echo.
echo Building production bundle...
call npm run build

echo.
echo ================================
echo Build completed successfully!
echo Output: web/build/
echo ================================
pause
