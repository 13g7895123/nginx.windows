# Add Reverse Proxy Configuration Script
# Purpose: Quickly create new reverse proxy configuration and automatically modify hosts file

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Domain,
    
    [Parameter(Mandatory=$true, Position=1)]
    [string]$TargetUrl,
    
    [Parameter(Mandatory=$false, Position=2)]
    [ValidateSet("http", "https", "websocket")]
    [string]$Type = "http",
    
    [Parameter(Mandatory=$false)]
    [switch]$AddToHosts,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableSSL
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$confDPath = Join-Path $projectRoot "conf.d"
$sslPath = Join-Path $projectRoot "ssl"
$hostsFile = "C:\Windows\System32\drivers\etc\hosts"

# Validate target URL
if ($TargetUrl -notmatch "^https?://") {
    Write-Host "Error: Target URL must start with http:// or https://" -ForegroundColor Red
    exit 1
}

# Check if configuration file already exists
$confFile = Join-Path $confDPath "$Domain.conf"
if (Test-Path $confFile) {
    Write-Host "Warning: Configuration file already exists: $confFile" -ForegroundColor Yellow
    Write-Host "Overwriting existing configuration..." -ForegroundColor Yellow
}

# Generate configuration content
$configContent = ""

switch ($Type) {
    "http" {
        $configContent = @"
# HTTP Reverse Proxy Configuration
# Domain: $Domain
# Target: $TargetUrl
# Created: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

server {
    listen       80;
    server_name  $Domain;

    access_log  ../logs/$Domain.access.log  main;
    error_log   ../logs/$Domain.error.log;

    location / {
        proxy_pass $TargetUrl;
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;
    }
}
"@
    }
    
    "https" {
        $certFile = Join-Path $sslPath "$Domain.crt"
        $keyFile = Join-Path $sslPath "$Domain.key"
        
        # Check SSL certificate
        if (-not (Test-Path $certFile) -or -not (Test-Path $keyFile)) {
            Write-Host "Warning: SSL certificate not found, generating self-signed certificate..." -ForegroundColor Yellow
            $generateScript = Join-Path $scriptPath "generate-ssl.ps1"
            if (Test-Path $generateScript) {
                & $generateScript -Domain $Domain
            } else {
                Write-Host "Error: Certificate generation script not found" -ForegroundColor Red
                exit 1
            }
        }
        
        $configContent = @"
# HTTPS Reverse Proxy Configuration
# Domain: $Domain
# Target: $TargetUrl
# Created: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

server {
    listen       443 ssl;
    server_name  $Domain;

    ssl_certificate      ../ssl/$Domain.crt;
    ssl_certificate_key  ../ssl/$Domain.key;

    ssl_session_cache    shared:SSL:1m;
    ssl_session_timeout  5m;
    ssl_protocols        TLSv1.2 TLSv1.3;
    ssl_ciphers          HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers  on;

    access_log  ../logs/$Domain.ssl.access.log  main;
    error_log   ../logs/$Domain.ssl.error.log;

    location / {
        proxy_pass $TargetUrl;
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}

# HTTP redirect to HTTPS
server {
    listen       80;
    server_name  $Domain;
    return 301 https://`$server_name`$request_uri;
}
"@
    }
    
    "websocket" {
        $configContent = @"
# WebSocket Reverse Proxy Configuration
# Domain: $Domain
# Target: $TargetUrl
# Created: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

server {
    listen       80;
    server_name  $Domain;

    access_log  ../logs/$Domain.access.log  main;
    error_log   ../logs/$Domain.error.log;

    location / {
        proxy_pass $TargetUrl;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade `$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        
        # Increase timeout
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }
}
"@
    }
}

# Write configuration file (without BOM to avoid nginx parsing errors)
try {
    [System.IO.File]::WriteAllText($confFile, $configContent, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "Configuration file created: $confFile" -ForegroundColor Green
} catch {
    Write-Host "Error: Cannot create configuration file: $_" -ForegroundColor Red
    exit 1
}

# Add to hosts file
if ($AddToHosts) {
    Write-Host "`nModifying hosts file..." -ForegroundColor Yellow
    
    # Check administrator privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "  ADMINISTRATOR PRIVILEGES REQUIRED" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "" -ForegroundColor Red
        Write-Host "Cannot modify hosts file without admin privileges!" -ForegroundColor Yellow
        Write-Host "" -ForegroundColor Yellow
        Write-Host "Please run this command as Administrator:" -ForegroundColor Cyan
        Write-Host "  .\scripts\update-hosts.ps1" -ForegroundColor White
        Write-Host "" -ForegroundColor Yellow
        Write-Host "Or manually add this line to:" -ForegroundColor Cyan
        Write-Host "  $hostsFile" -ForegroundColor Gray
        Write-Host "  127.0.0.1    $Domain" -ForegroundColor White
        Write-Host "" -ForegroundColor Red
    } else {
        # Read existing hosts content
        $hostsContent = Get-Content $hostsFile
        
        # Check if entry already exists
        $existingEntry = $hostsContent | Where-Object { $_ -match "^\s*127\.0\.0\.1\s+$Domain\s*" }
        
        if ($existingEntry) {
            Write-Host "Domain already exists in hosts file" -ForegroundColor Yellow
        } else {
            # Add new entry
            $newEntry = "127.0.0.1    $Domain    # Added by nginx-manager"
            Add-Content -Path $hostsFile -Value $newEntry
            
            # Verify it was added
            Start-Sleep -Milliseconds 300
            $hostsContentNew = Get-Content $hostsFile
            $verified = $hostsContentNew | Where-Object { $_ -match "^\s*127\.0\.0\.1\s+$Domain\s*" }
            
            if ($verified) {
                Write-Host "SUCCESS: Added to hosts file: 127.0.0.1 -> $Domain" -ForegroundColor Green
                Write-Host "Flushing DNS cache..." -ForegroundColor Cyan
                ipconfig /flushdns | Out-Null
                Write-Host "DNS cache flushed" -ForegroundColor Green
            } else {
                Write-Host "WARNING: Failed to verify hosts file entry!" -ForegroundColor Red
                Write-Host "Please manually verify: $hostsFile" -ForegroundColor Yellow
            }
        }
    }
}

# Test configuration
Write-Host "`nTesting nginx configuration..." -ForegroundColor Yellow
$managerScript = Join-Path $scriptPath "nginx-manager.ps1"
& $managerScript -Action test

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nConfiguration added successfully!" -ForegroundColor Green
    Write-Host "Please reload nginx to apply changes:" -ForegroundColor Cyan
    Write-Host "  .\scripts\nginx-manager.ps1 -Action reload" -ForegroundColor White
    
    if (-not $AddToHosts) {
        Write-Host "" -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host "  HOSTS FILE NOT UPDATED" -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host "" -ForegroundColor Yellow
        Write-Host "To access this domain, run as Administrator:" -ForegroundColor Cyan
        Write-Host "  .\scripts\update-hosts.ps1" -ForegroundColor White
        Write-Host "" -ForegroundColor Yellow
        Write-Host "Or manually add to: $hostsFile" -ForegroundColor Cyan
        Write-Host "  127.0.0.1    $Domain" -ForegroundColor White
        Write-Host "" -ForegroundColor Yellow
    }
} else {
    Write-Host "Configuration test failed, please check the configuration file" -ForegroundColor Red
    exit 1
}
