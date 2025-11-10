# Self-Signed SSL Certificate Generation Script
# Purpose: Generate self-signed SSL certificates for local development

param(
    [Parameter(Mandatory=$true)]
    [string]$Domain,
    
    [int]$Days = 365
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$sslPath = Join-Path $projectRoot "ssl"

# Create SSL directory if not exists
if (-not (Test-Path $sslPath)) {
    New-Item -ItemType Directory -Path $sslPath -Force | Out-Null
    Write-Host "Created SSL directory: $sslPath" -ForegroundColor Green
}

$certFile = Join-Path $sslPath "$Domain.crt"
$keyFile = Join-Path $sslPath "$Domain.key"

# Check if certificate already exists
if ((Test-Path $certFile) -or (Test-Path $keyFile)) {
    Write-Host "Warning: Certificate files already exist" -ForegroundColor Yellow
    Write-Host "  Certificate: $certFile" -ForegroundColor Yellow
    Write-Host "  Private Key: $keyFile" -ForegroundColor Yellow
    $confirm = Read-Host "Overwrite? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Operation cancelled" -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "Generating self-signed SSL certificate for $Domain..." -ForegroundColor Cyan

try {
    # Use PowerShell cmdlet to generate certificate
    $cert = New-SelfSignedCertificate `
        -DnsName $Domain `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -KeyExportPolicy Exportable `
        -KeySpec Signature `
        -KeyLength 2048 `
        -KeyAlgorithm RSA `
        -HashAlgorithm SHA256 `
        -NotAfter (Get-Date).AddDays($Days)
    
    # Export certificate
    $certPassword = ConvertTo-SecureString -String "temp" -Force -AsPlainText
    $certPath = Join-Path $env:TEMP "$Domain.pfx"
    Export-PfxCertificate -Cert $cert -FilePath $certPath -Password $certPassword | Out-Null
    
    # Convert PFX to PEM format using OpenSSL if available, otherwise use certutil
    $opensslPath = Get-Command openssl -ErrorAction SilentlyContinue
    
    if ($opensslPath) {
        # Use OpenSSL
        & openssl pkcs12 -in $certPath -out $certFile -nokeys -passin pass:temp -passout pass:temp 2>$null
        & openssl pkcs12 -in $certPath -out $keyFile -nocerts -nodes -passin pass:temp 2>$null
    } else {
        # Fallback: Export using .NET
        $certBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
        [System.IO.File]::WriteAllBytes($certFile, $certBytes)
        
        # Note: Private key export without OpenSSL is limited
        Write-Host "Note: OpenSSL not found. Certificate exported, but private key format may need manual conversion." -ForegroundColor Yellow
        Write-Host "For production use, install OpenSSL or use proper certificate authority." -ForegroundColor Yellow
    }
    
    # Clean up
    Remove-Item $certPath -Force -ErrorAction SilentlyContinue
    Get-ChildItem "Cert:\CurrentUser\My" | Where-Object { $_.Thumbprint -eq $cert.Thumbprint } | Remove-Item
    
    Write-Host "`nSSL certificate generated successfully!" -ForegroundColor Green
    Write-Host "  Certificate: $certFile" -ForegroundColor Cyan
    Write-Host "  Private Key: $keyFile" -ForegroundColor Cyan
    Write-Host "  Valid for: $Days days" -ForegroundColor Cyan
    Write-Host "`nNote: This is a self-signed certificate for development only." -ForegroundColor Yellow
    Write-Host "Browsers will show security warnings (this is normal)." -ForegroundColor Yellow
    
} catch {
    Write-Host "Error generating certificate: $_" -ForegroundColor Red
    Write-Host "`nTrying alternative method..." -ForegroundColor Yellow
    
    # Alternative: Use makecert if available (older Windows)
    $makecert = Get-Command makecert -ErrorAction SilentlyContinue
    if ($makecert) {
        & makecert -r -pe -n "CN=$Domain" -sky exchange -sv "$keyFile" "$certFile" -b 01/01/2020 -e 12/31/2030
        Write-Host "Certificate generated using makecert" -ForegroundColor Green
    } else {
        Write-Host "Error: Unable to generate certificate. Please install OpenSSL." -ForegroundColor Red
        Write-Host "Download from: https://slproweb.com/products/Win32OpenSSL.html" -ForegroundColor Cyan
        exit 1
    }
}
