@echo off
setlocal
set "SCRIPT=%~dp0check-unknown-installs.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
echo.
pause
endlocal
