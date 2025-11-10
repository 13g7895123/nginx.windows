# This script will launch update-hosts-admin.ps1 with administrator privileges

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$adminScript = Join-Path $scriptPath "update-hosts-admin.ps1"

Write-Host "`nLaunching hosts file updater with administrator privileges..." -ForegroundColor Cyan

# Check if the admin script exists
if (-not (Test-Path $adminScript)) {
    Write-Host "Error: Admin script not found: $adminScript" -ForegroundColor Red
    exit 1
}

# Launch PowerShell as administrator
Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy Bypass", "-File `"$adminScript`"" -Verb RunAs
