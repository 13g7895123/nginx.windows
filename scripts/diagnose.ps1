# nginx Diagnosis Script
# Helps identify why nginx proxy is not working

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  nginx Proxy Diagnosis" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$nginxPath = Join-Path $projectRoot "nginx"
$nginxExe = Join-Path $nginxPath "nginx.exe"

# 1. Check nginx process
Write-Host "[1] Checking nginx processes..." -ForegroundColor Yellow
$nginxProcs = Get-Process -Name "nginx" -ErrorAction SilentlyContinue
if ($nginxProcs) {
    Write-Host "  nginx is running: $($nginxProcs.Count) process(es)" -ForegroundColor Green
    $nginxProcs | Format-Table Id, ProcessName, StartTime, Path -AutoSize
} else {
    Write-Host "  nginx is NOT running!" -ForegroundColor Red
}

# 2. Check port 80 listening
Write-Host "`n[2] Checking port 80..." -ForegroundColor Yellow
$port80 = netstat -ano | Select-String "LISTENING" | Select-String ":80 "
if ($port80) {
    Write-Host "  Port 80 is LISTENING:" -ForegroundColor Green
    $port80 | ForEach-Object { Write-Host "    $_" -ForegroundColor White }
} else {
    Write-Host "  Port 80 is NOT listening!" -ForegroundColor Red
    Write-Host "  This is why the proxy is not working!" -ForegroundColor Yellow
}

# 3. Check configuration
Write-Host "`n[3] Testing nginx configuration..." -ForegroundColor Yellow
Push-Location $nginxPath
try {
    $testResult = & $nginxExe -t -c (Join-Path $projectRoot "conf\nginx.conf") 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Configuration test: PASSED" -ForegroundColor Green
    } else {
        Write-Host "  Configuration test: FAILED" -ForegroundColor Red
        Write-Host "  Output: $testResult" -ForegroundColor Yellow
    }
} finally {
    Pop-Location
}

# 4. Check hosts file
Write-Host "`n[4] Checking hosts file entries..." -ForegroundColor Yellow
$confDPath = Join-Path $projectRoot "conf.d"
if (Test-Path $confDPath) {
    $configs = Get-ChildItem -Path $confDPath -Filter "*.conf"
    $domains = @()
    foreach ($config in $configs) {
        $content = Get-Content -Path $config.FullName -Raw
        if ($content -match 'server_name\s+([^;]+);') {
            $configDomains = $matches[1] -split '\s+' | Where-Object { $_ -ne '' -and $_ -ne '_' }
            $domains += $configDomains
        }
    }
    
    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    $hostsContent = Get-Content -Path $hostsPath
    
    foreach ($domain in $domains) {
        $pattern = "^\s*127\.0\.0\.1\s+$([regex]::Escape($domain))\s*(#.*)?$"
        $exists = $hostsContent | Where-Object { $_ -match $pattern }
        if ($exists) {
            Write-Host "  [OK] $domain -> 127.0.0.1" -ForegroundColor Green
        } else {
            Write-Host "  [MISSING] $domain" -ForegroundColor Red
        }
    }
}

# 5. Check target availability
Write-Host "`n[5] Checking proxy targets..." -ForegroundColor Yellow
if (Test-Path $confDPath) {
    $configs = Get-ChildItem -Path $confDPath -Filter "*.conf"
    foreach ($config in $configs) {
        $content = Get-Content -Path $config.FullName -Raw
        if ($content -match 'proxy_pass\s+http://localhost:(\d+)') {
            $port = $matches[1]
            $testConn = Test-NetConnection -ComputerName localhost -Port $port -WarningAction SilentlyContinue
            if ($testConn.TcpTestSucceeded) {
                Write-Host "  [OK] localhost:$port is reachable" -ForegroundColor Green
            } else {
                Write-Host "  [FAIL] localhost:$port is NOT reachable!" -ForegroundColor Red
            }
        }
    }
}

# 6. Check error log
Write-Host "`n[6] Recent error log entries..." -ForegroundColor Yellow
$errorLog = Join-Path $projectRoot "logs\error.log"
if (Test-Path $errorLog) {
    $errors = Get-Content $errorLog -Tail 10 | Select-String -Pattern "error|emerg|alert|crit" -CaseSensitive:$false
    if ($errors) {
        Write-Host "  Found errors:" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
    } else {
        Write-Host "  No recent errors found" -ForegroundColor Green
    }
} else {
    Write-Host "  Error log not found" -ForegroundColor Yellow
}

# 7. Recommendations
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Diagnosis Summary & Recommendations" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if (-not $nginxProcs) {
    Write-Host "[ACTION REQUIRED] nginx is not running!" -ForegroundColor Red
    Write-Host "  Run: .\scripts\nginx-manager.ps1 -Action start" -ForegroundColor White
} elseif (-not $port80) {
    Write-Host "[CRITICAL] nginx is running but NOT listening on port 80!" -ForegroundColor Red
    Write-Host "" -ForegroundColor Yellow
    Write-Host "This is the main problem! Possible causes:" -ForegroundColor Yellow
    Write-Host "  1. nginx.conf is not loading conf.d/*.conf files correctly" -ForegroundColor White
    Write-Host "  2. Port 80 is blocked by firewall or Windows HTTP.sys" -ForegroundColor White
    Write-Host "  3. nginx was started from wrong directory" -ForegroundColor White
    Write-Host "" -ForegroundColor Yellow
    Write-Host "SOLUTION: Restart nginx properly:" -ForegroundColor Cyan
    Write-Host "  1. Stop nginx as Administrator:" -ForegroundColor White
    Write-Host "     .\scripts\nginx-manager.ps1 -Action stop" -ForegroundColor Gray
    Write-Host "  2. Start nginx:" -ForegroundColor White
    Write-Host "     .\scripts\nginx-manager.ps1 -Action start" -ForegroundColor Gray
    Write-Host "" -ForegroundColor Yellow
    Write-Host "If port 80 still doesn't work, try using a different port (e.g., 8080):" -ForegroundColor Yellow
    Write-Host "  Edit conf.d/*.conf and change 'listen 80;' to 'listen 8080;'" -ForegroundColor White
} else {
    Write-Host "[OK] nginx appears to be configured correctly!" -ForegroundColor Green
    Write-Host "" -ForegroundColor Green
    Write-Host "Test your proxy with:" -ForegroundColor Cyan
    foreach ($domain in $domains) {
        Write-Host "  curl http://$domain" -ForegroundColor White
    }
}

Write-Host ""
