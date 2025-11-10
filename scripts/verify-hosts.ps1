# Verify Hosts File Entries for nginx Proxy Configurations
# This script checks if all proxy domains are correctly added to Windows hosts file

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$confDPath = Join-Path $projectRoot "conf.d"
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Verify Hosts File Entries" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Get all proxy configurations
if (-not (Test-Path $confDPath)) {
    Write-Host "Error: Configuration directory not found: $confDPath" -ForegroundColor Red
    exit 1
}

$configs = Get-ChildItem -Path $confDPath -Filter "*.conf" -ErrorAction SilentlyContinue

if ($configs.Count -eq 0) {
    Write-Host "No proxy configurations found." -ForegroundColor Yellow
    exit 0
}

# Extract domains from all configurations
$domains = @()
foreach ($config in $configs) {
    $content = Get-Content -Path $config.FullName -Raw
    if ($content -match 'server_name\s+([^;]+);') {
        $configDomains = $matches[1] -split '\s+' | Where-Object { $_ -ne '' -and $_ -ne '_' }
        foreach ($domain in $configDomains) {
            $domains += $domain
        }
    }
}

if ($domains.Count -eq 0) {
    Write-Host "No domains found in configurations." -ForegroundColor Yellow
    exit 0
}

Write-Host "Checking $($domains.Count) domain(s):`n" -ForegroundColor Cyan

# Read hosts file
$hostsContent = Get-Content -Path $hostsPath

# Check each domain
$foundCount = 0
$missingDomains = @()

foreach ($domain in $domains) {
    $pattern = "^\s*127\.0\.0\.1\s+$([regex]::Escape($domain))\s*(#.*)?$"
    $exists = $hostsContent | Where-Object { $_ -match $pattern }
    
    if ($exists) {
        Write-Host "  [OK] $domain" -ForegroundColor Green
        $foundCount++
    } else {
        Write-Host "  [MISSING] $domain" -ForegroundColor Red
        $missingDomains += $domain
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Results: $foundCount / $($domains.Count) domains in hosts file" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($missingDomains.Count -gt 0) {
    Write-Host "`nMissing domains:" -ForegroundColor Yellow
    foreach ($domain in $missingDomains) {
        Write-Host "  - $domain" -ForegroundColor Yellow
    }
    
    Write-Host "`nTo add missing domains, run as Administrator:" -ForegroundColor Cyan
    Write-Host "  .\scripts\update-hosts.ps1" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "`nAll domains are correctly configured in hosts file!" -ForegroundColor Green
    Write-Host ""
}
