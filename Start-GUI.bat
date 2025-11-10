@echo off
REM nginx GUI Launcher
REM Double-click this file to launch the GUI

cd /d "%~dp0"
powershell.exe -ExecutionPolicy Bypass -File ".\scripts\nginx-gui.ps1"

if errorlevel 1 (
    echo.
    echo Failed to start! Please ensure PowerShell is installed.
    pause
)
