@echo off
setlocal EnableExtensions
cd /d "%~dp0"
where powershell.exe >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Windows PowerShell was not found.
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_path.ps1"
if errorlevel 1 (
  echo PATH setup failed.
  pause
  exit /b 1
)
echo PATH setup completed. Reopen PowerShell before using solvforge.exe.
pause
endlocal
