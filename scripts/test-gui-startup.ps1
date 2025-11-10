# Test GUI Startup Logic
# This script tests the startup checks without launching the full GUI

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Testing GUI Startup Logic" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# 1. Check Administrator privileges
Write-Host "[1] Checking Administrator privileges..." -ForegroundColor Yellow
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Host "  [OK] Running with Administrator privileges" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] NOT running with Administrator privileges" -ForegroundColor Red
    Write-Host "  GUI would prompt to restart as Administrator" -ForegroundColor Yellow
}

# 2. Check existing nginx processes
Write-Host "`n[2] Checking existing nginx processes..." -ForegroundColor Yellow
$existingNginx = Get-Process -Name "nginx" -ErrorAction SilentlyContinue
if ($existingNginx) {
    Write-Host "  Found $($existingNginx.Count) nginx process(es)" -ForegroundColor Cyan
    $existingNginx | Format-Table Id, StartTime -AutoSize
} else {
    Write-Host "  No nginx processes found" -ForegroundColor Yellow
}

# 3. Check if port 80 is listening
Write-Host "`n[3] Checking if port 80 is listening..." -ForegroundColor Yellow
$port80 = netstat -ano | Select-String "LISTENING" | Select-String ":80 "
if ($port80) {
    Write-Host "  [OK] Port 80 is listening:" -ForegroundColor Green
    $port80 | ForEach-Object { Write-Host "    $_" -ForegroundColor White }
} else {
    Write-Host "  [FAIL] Port 80 is NOT listening" -ForegroundColor Red
    
    if ($existingNginx) {
        Write-Host "`n  GUI would perform cleanup:" -ForegroundColor Yellow
        Write-Host "    1. Force kill existing nginx processes" -ForegroundColor White
        Write-Host "    2. Start nginx with correct configuration" -ForegroundColor White
        Write-Host "    3. Verify port 80 is listening" -ForegroundColor White
    } else {
        Write-Host "`n  GUI would start nginx automatically" -ForegroundColor Yellow
    }
}

# 4. Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($isAdmin) {
    Write-Host "[OK] Administrator privileges: YES" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Administrator privileges: NO" -ForegroundColor Red
}

if ($existingNginx) {
    Write-Host "[INFO] nginx processes: $($existingNginx.Count) found" -ForegroundColor Cyan
} else {
    Write-Host "[WARN] nginx processes: None" -ForegroundColor Yellow
}

if ($port80) {
    Write-Host "[OK] Port 80 listening: YES" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Port 80 listening: NO" -ForegroundColor Red
}

Write-Host "`nGUI Startup Behavior:" -ForegroundColor Cyan
if (-not $isAdmin) {
    Write-Host "  -> Would prompt to restart as Administrator" -ForegroundColor Yellow
} elseif ($existingNginx -and -not $port80) {
    Write-Host "  -> Would cleanup and restart nginx" -ForegroundColor Yellow
} elseif (-not $existingNginx) {
    Write-Host "  -> Would start nginx automatically" -ForegroundColor Yellow
} else {
    Write-Host "  -> Would launch normally" -ForegroundColor Green
}

Write-Host ""
