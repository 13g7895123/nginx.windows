# Restart nginx as Administrator
# This script will elevate to admin and restart nginx properly

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath

Write-Host "`nRestarting nginx as Administrator..." -ForegroundColor Cyan

# Check if already running as admin
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    
    # Create a temporary script to run as admin
    $tempScript = Join-Path $env:TEMP "nginx-restart-admin.ps1"
    @"
Set-Location '$projectRoot'
Write-Host 'Stopping nginx...' -ForegroundColor Yellow
taskkill /F /IM nginx.exe 2>$null
Start-Sleep -Seconds 2
Write-Host 'Starting nginx...' -ForegroundColor Yellow
& '.\scripts\nginx-manager.ps1' -Action start
Start-Sleep -Seconds 2
Write-Host ''
Write-Host 'Checking if nginx is listening on port 80...' -ForegroundColor Cyan
$port80 = netstat -ano | Select-String 'LISTENING' | Select-String ':80 '
if ($port80) {
    Write-Host 'SUCCESS: nginx is now listening on port 80!' -ForegroundColor Green
    $port80
} else {
    Write-Host 'WARNING: nginx is not listening on port 80' -ForegroundColor Yellow
}
Write-Host ''
Write-Host 'Press any key to exit...' -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
"@ | Out-File -FilePath $tempScript -Encoding UTF8
    
    # Launch PowerShell as admin
    Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy Bypass", "-File `"$tempScript`"" -Verb RunAs
    
} else {
    # Already running as admin, execute directly
    Write-Host "Stopping nginx..." -ForegroundColor Yellow
    taskkill /F /IM nginx.exe 2>$null
    Start-Sleep -Seconds 2
    
    Write-Host "Starting nginx..." -ForegroundColor Yellow
    & (Join-Path $scriptPath "nginx-manager.ps1") -Action start
    Start-Sleep -Seconds 2
    
    Write-Host ""
    Write-Host "Checking if nginx is listening on port 80..." -ForegroundColor Cyan
    $port80 = netstat -ano | Select-String "LISTENING" | Select-String ":80 "
    if ($port80) {
        Write-Host "SUCCESS: nginx is now listening on port 80!" -ForegroundColor Green
        $port80
    } else {
        Write-Host "WARNING: nginx is not listening on port 80" -ForegroundColor Yellow
    }
}
