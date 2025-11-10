# List Reverse Proxy Configurations Script
# Purpose: Display all configured reverse proxy entries

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$confDPath = Join-Path $projectRoot "conf.d"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  nginx Reverse Proxy Configurations" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if (-not (Test-Path $confDPath)) {
    Write-Host "Error: Configuration directory not found: $confDPath" -ForegroundColor Red
    exit 1
}

$configs = Get-ChildItem -Path $confDPath -Filter "*.conf" -ErrorAction SilentlyContinue

if ($configs.Count -eq 0) {
    Write-Host "No proxy configurations found." -ForegroundColor Yellow
    Write-Host "`nTo add a new proxy, run:" -ForegroundColor Cyan
    Write-Host "  .\scripts\add-proxy.ps1 -Domain <domain> -TargetUrl <url>" -ForegroundColor White
    exit 0
}

Write-Host "Found $($configs.Count) configuration(s):`n" -ForegroundColor Green

foreach ($config in $configs) {
    Write-Host "Configuration: " -NoNewline -ForegroundColor Cyan
    Write-Host $config.Name -ForegroundColor White
    Write-Host "  Path: " -NoNewline -ForegroundColor Gray
    Write-Host $config.FullName -ForegroundColor Gray
    
    # Parse configuration file
    $content = Get-Content -Path $config.FullName -Raw
    
    # Extract server names
    if ($content -match 'server_name\s+([^;]+);') {
        $domains = $matches[1] -split '\s+' | Where-Object { $_ -ne '' }
        Write-Host "  Domains: " -NoNewline -ForegroundColor Yellow
        Write-Host ($domains -join ', ') -ForegroundColor White
    }
    
    # Extract proxy target
    if ($content -match 'proxy_pass\s+([^;]+);') {
        Write-Host "  Target: " -NoNewline -ForegroundColor Yellow
        Write-Host $matches[1] -ForegroundColor White
    }
    
    # Check SSL
    if ($content -match 'listen\s+443\s+ssl') {
        Write-Host "  Type: " -NoNewline -ForegroundColor Yellow
        Write-Host "HTTPS (SSL Enabled)" -ForegroundColor Green
    } elseif ($content -match 'proxy_set_header Upgrade') {
        Write-Host "  Type: " -NoNewline -ForegroundColor Yellow
        Write-Host "WebSocket" -ForegroundColor Green
    } else {
        Write-Host "  Type: " -NoNewline -ForegroundColor Yellow
        Write-Host "HTTP" -ForegroundColor Green
    }
    
    Write-Host "  Modified: " -NoNewline -ForegroundColor Gray
    Write-Host $config.LastWriteTime -ForegroundColor Gray
    Write-Host ""
}

Write-Host "========================================`n" -ForegroundColor Cyan
