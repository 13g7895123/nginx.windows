# Remove Reverse Proxy Configuration Script
# Purpose: Delete reverse proxy configuration for specified domain, optionally remove from hosts file

param(
    [Parameter(Mandatory=$true)]
    [string]$Domain,
    
    [switch]$RemoveFromHosts,
    
    [switch]$Force
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$confDPath = Join-Path $projectRoot "conf.d"
$hostsFile = "C:\Windows\System32\drivers\etc\hosts"

# Find configuration file
$confFile = Join-Path $confDPath "$Domain.conf"

if (-not (Test-Path $confFile)) {
    Write-Host "Error: Configuration file not found: $confFile" -ForegroundColor Red
    exit 1
}

# Confirm deletion if not forced
if (-not $Force) {
    Write-Host "Configuration file to be deleted: $confFile" -ForegroundColor Yellow
    $confirm = Read-Host "Confirm deletion? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Operation cancelled" -ForegroundColor Yellow
        exit 0
    }
}

# Delete configuration file
try {
    Remove-Item $confFile -Force
    Write-Host "Configuration file deleted: $confFile" -ForegroundColor Green
} catch {
    Write-Host "Error: Cannot delete configuration file: $_" -ForegroundColor Red
    exit 1
}

# Remove from hosts file
if ($RemoveFromHosts) {
    Write-Host "`nRemoving from hosts file..." -ForegroundColor Yellow
    
    # Check administrator privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "Warning: Administrator privileges required to modify hosts file" -ForegroundColor Yellow
        Write-Host "Please manually remove the following entry from hosts file:" -ForegroundColor Yellow
        Write-Host "127.0.0.1    $Domain" -ForegroundColor Cyan
    } else {
        # Read existing hosts content
        $hostsContent = Get-Content $hostsFile
        
        # Filter out the entry
        $newHostsContent = $hostsContent | Where-Object { $_ -notmatch "^\s*127\.0\.0\.1\s+$Domain\s*" }
        
        if ($hostsContent.Count -ne $newHostsContent.Count) {
            $newHostsContent | Out-File $hostsFile -Encoding ASCII
            Write-Host "Removed from hosts file: $Domain" -ForegroundColor Green
        } else {
            Write-Host "Domain not found in hosts file" -ForegroundColor Yellow
        }
    }
}

Write-Host "`nProxy configuration removed successfully!" -ForegroundColor Green
Write-Host "Please reload nginx to apply changes:" -ForegroundColor Cyan
Write-Host "  .\scripts\nginx-manager.ps1 -Action reload" -ForegroundColor White
