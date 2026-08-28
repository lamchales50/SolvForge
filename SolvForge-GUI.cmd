@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if not exist "%~dp0solvforge.exe" (
  echo [ERROR] Missing solvforge.exe. Extract the complete ZIP first.
  pause
  exit /b 1
)
if not exist "%~dp0SolvForge-GUI.ps1" (
  echo [ERROR] Missing SolvForge-GUI.ps1. Extract the complete ZIP first.
  pause
  exit /b 1
)
where powershell.exe >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Windows PowerShell was not found.
  pause
  exit /b 1
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0SolvForge-GUI.ps1"
set "exitCode=%errorlevel%"
if not "%exitCode%"=="0" (
  echo [ERROR] SolvForge GUI exited with code %exitCode%.
  pause
)
endlocal & exit /b %exitCode%
