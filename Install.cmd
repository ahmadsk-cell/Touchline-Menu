@echo off
cd /d "%~dp0"
echo Touchline Menu installer
echo Close Football Life and Sider before continuing.
set /p "SIDER_PATH=Enter the full path to your SiderAddons folder: "
if not defined SIDER_PATH exit /b 1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1" -SiderDir "%SIDER_PATH%"
pause
