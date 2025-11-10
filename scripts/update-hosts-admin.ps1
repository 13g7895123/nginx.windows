#Requires -RunAsAdministrator

# Update Windows hosts file for all nginx proxy configurations
# This script requires administrator privileges

param(
    [switch]$DryRun
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$confDPath = Join-Path $projectRoot "conf.d"
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Update Windows hosts file" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check if running as administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "`nPlease right-click PowerShell and select 'Run as Administrator', then run this script again." -ForegroundColor Yellow
    exit 1
}

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

Write-Host "Found $($domains.Count) domain(s) to add:" -ForegroundColor Green
foreach ($domain in $domains) {
    Write-Host "  - $domain" -ForegroundColor White
}
Write-Host ""

# Read current hosts file
$hostsContent = Get-Content -Path $hostsPath

# Find existing nginx-manager entries
$existingEntries = $hostsContent | Where-Object { $_ -match '# Added by nginx-manager' }

# Check which domains are already in hosts file
$domainsToAdd = @()
$domainsSkipped = @()

foreach ($domain in $domains) {
    $pattern = "^\s*127\.0\.0\.1\s+$([regex]::Escape($domain))\s*(#.*)?$"
    $exists = $hostsContent | Where-Object { $_ -match $pattern }
    
    if ($exists) {
        $domainsSkipped += $domain
    } else {
        $domainsToAdd += $domain
    }
}

if ($domainsSkipped.Count -gt 0) {
    Write-Host "Domains already in hosts file (skipped):" -ForegroundColor Yellow
    foreach ($domain in $domainsSkipped) {
        Write-Host "  - $domain" -ForegroundColor Gray
    }
    Write-Host ""
}

if ($domainsToAdd.Count -eq 0) {
    Write-Host "All domains are already in hosts file. No changes needed." -ForegroundColor Green
    exit 0
}

Write-Host "Domains to add:" -ForegroundColor Cyan
foreach ($domain in $domainsToAdd) {
    Write-Host "  + 127.0.0.1    $domain" -ForegroundColor Green
}
Write-Host ""

if ($DryRun) {
    Write-Host "[DRY RUN] No changes were made. Remove -DryRun to apply changes." -ForegroundColor Yellow
    exit 0
}

# Backup hosts file
$backupPath = "$hostsPath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
try {
    Copy-Item -Path $hostsPath -Destination $backupPath -Force
    Write-Host "Backup created: $backupPath" -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not create backup: $_" -ForegroundColor Yellow
}

# Add new entries
try {
    $newEntries = @()
    foreach ($domain in $domainsToAdd) {
        $newEntries += "127.0.0.1    $domain    # Added by nginx-manager"
    }
    
    # Append to hosts file
    Add-Content -Path $hostsPath -Value "`n# nginx-manager entries - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Add-Content -Path $hostsPath -Value ($newEntries -join "`n")
    
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  SUCCESS: Hosts File Updated" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    
    # Verify each domain was added
    Write-Host "`nVerifying entries..." -ForegroundColor Cyan
    Start-Sleep -Milliseconds 500
    
    $hostsContentNew = Get-Content -Path $hostsPath
    $verifiedCount = 0
    $failedDomains = @()
    
    foreach ($domain in $domainsToAdd) {
        $pattern = "^\s*127\.0\.0\.1\s+$([regex]::Escape($domain))\s*(#.*)?$"
        $verified = $hostsContentNew | Where-Object { $_ -match $pattern }
        
        if ($verified) {
            Write-Host "  [OK] $domain" -ForegroundColor Green
            $verifiedCount++
        } else {
            Write-Host "  [FAIL] $domain" -ForegroundColor Red
            $failedDomains += $domain
        }
    }
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Added: $verifiedCount / $($domainsToAdd.Count) domain(s)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    if ($failedDomains.Count -gt 0) {
        Write-Host "`nWARNING: Failed to verify these domains:" -ForegroundColor Yellow
        foreach ($domain in $failedDomains) {
            Write-Host "  - $domain" -ForegroundColor Yellow
        }
    }
    
    # Flush DNS cache
    Write-Host "`nFlushing DNS cache..." -ForegroundColor Cyan
    $flushResult = ipconfig /flushdns 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "DNS cache flushed successfully" -ForegroundColor Green
    } else {
        Write-Host "Warning: Failed to flush DNS cache" -ForegroundColor Yellow
    }
    
    Write-Host "`nYou can now access these domains in your browser!" -ForegroundColor Green
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
} catch {
    Write-Host "`n========================================" -ForegroundColor Red
    Write-Host "  ERROR: Failed to Update Hosts File" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "`nError message: $_" -ForegroundColor Red
    
    if (Test-Path $backupPath) {
        Write-Host "`nRestoring from backup..." -ForegroundColor Yellow
        Copy-Item -Path $backupPath -Destination $hostsPath -Force
        Write-Host "Backup restored." -ForegroundColor Green
    }
    
    Write-Host "`nPress any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "`n========================================`n" -ForegroundColor Cyan
