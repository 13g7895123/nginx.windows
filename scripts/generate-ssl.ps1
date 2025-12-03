# Self-Signed SSL Certificate Generation Script
# Purpose: Generate self-signed SSL certificates for local development

param(
    [Parameter(Mandatory=$true)]
    [string]$Domain,
    
    [int]$Days = 365,
    
    [switch]$Force  # Skip confirmation for GUI usage
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$sslPath = Join-Path $projectRoot "ssl"
$logFile = Join-Path $projectRoot "logs\gui.log"

# Logging function
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] [generate-ssl] $Message"
    Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
    
    switch ($Level) {
        "ERROR" { Write-Host $Message -ForegroundColor Red }
        "WARN"  { Write-Host $Message -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        default { Write-Host $Message -ForegroundColor Cyan }
    }
}

# Helper function to convert RSA parameters to PEM format (PKCS#1)
function ConvertTo-RsaPrivateKeyPem {
    param(
        [System.Security.Cryptography.RSAParameters]$RSAParameters
    )
    
    # Helper to encode integer with DER length prefix
    function Get-DerInteger {
        param([byte[]]$bytes)
        
        # Remove leading zeros but keep sign bit
        $start = 0
        while ($start -lt $bytes.Length -1 -and $bytes[$start] -eq 0 -and ($bytes[$start + 1] -band 0x80) -eq 0) {
            $start++
        }
        $bytes = $bytes[$start..($bytes.Length - 1)]
        
        # Add leading zero if high bit is set (to indicate positive number)
        if (($bytes[0] -band 0x80) -ne 0) {
            $bytes = @([byte]0) + $bytes
        }
        
        $result = @([byte]0x02)  # INTEGER tag
        
        # Length encoding
        if ($bytes.Length -lt 128) {
            $result += [byte]$bytes.Length
        } elseif ($bytes.Length -lt 256) {
            $result += @([byte]0x81, [byte]$bytes.Length)
        } else {
            $result += @([byte]0x82, [byte]($bytes.Length -shr 8), [byte]($bytes.Length -band 0xFF))
        }
        
        $result += $bytes
        return $result
    }
    
    # Helper to encode DER length
    function Get-DerLength {
        param([int]$length)
        
        if ($length -lt 128) {
            return @([byte]$length)
        } elseif ($length -lt 256) {
            return @([byte]0x81, [byte]$length)
        } else {
            return @([byte]0x82, [byte]($length -shr 8), [byte]($length -band 0xFF))
        }
    }
    
    # Build the RSA private key structure
    # RSAPrivateKey ::= SEQUENCE {
    #   version           Version,
    #   modulus           INTEGER,  -- n
    #   publicExponent    INTEGER,  -- e
    #   privateExponent   INTEGER,  -- d
    #   prime1            INTEGER,  -- p
    #   prime2            INTEGER,  -- q
    #   exponent1         INTEGER,  -- d mod (p-1)
    #   exponent2         INTEGER,  -- d mod (q-1)
    #   coefficient       INTEGER,  -- (inverse of q) mod p
    # }
    
    $version = @([byte]0x02, [byte]0x01, [byte]0x00)  # INTEGER 0
    $modulus = Get-DerInteger -bytes $RSAParameters.Modulus
    $publicExponent = Get-DerInteger -bytes $RSAParameters.Exponent
    $privateExponent = Get-DerInteger -bytes $RSAParameters.D
    $prime1 = Get-DerInteger -bytes $RSAParameters.P
    $prime2 = Get-DerInteger -bytes $RSAParameters.Q
    $exponent1 = Get-DerInteger -bytes $RSAParameters.DP
    $exponent2 = Get-DerInteger -bytes $RSAParameters.DQ
    $coefficient = Get-DerInteger -bytes $RSAParameters.InverseQ
    
    # Combine all elements
    $content = $version + $modulus + $publicExponent + $privateExponent + 
               $prime1 + $prime2 + $exponent1 + $exponent2 + $coefficient
    
    # Wrap in SEQUENCE
    $sequence = @([byte]0x30) + (Get-DerLength -length $content.Length) + $content
    
    # Convert to Base64 PEM
    $base64 = [System.Convert]::ToBase64String($sequence, [System.Base64FormattingOptions]::InsertLineBreaks)
    
    return "-----BEGIN RSA PRIVATE KEY-----`r`n$base64`r`n-----END RSA PRIVATE KEY-----"
}

Write-Log "=== SSL Certificate Generation Started ==="
Write-Log "Domain: $Domain, Days: $Days, Force: $Force"
Write-Log "Project Root: $projectRoot"
Write-Log "SSL Path: $sslPath"

# Create SSL directory if not exists
if (-not (Test-Path $sslPath)) {
    New-Item -ItemType Directory -Path $sslPath -Force | Out-Null
    Write-Log "Created SSL directory: $sslPath"
}

$certFile = Join-Path $sslPath "$Domain.crt"
$keyFile = Join-Path $sslPath "$Domain.key"

Write-Log "Certificate file: $certFile"
Write-Log "Key file: $keyFile"

# Check if certificate already exists
if ((Test-Path $certFile) -or (Test-Path $keyFile)) {
    Write-Log "Warning: Certificate files already exist" "WARN"
    if (-not $Force) {
        $confirm = Read-Host "Overwrite? (y/N)"
        if ($confirm -ne "y" -and $confirm -ne "Y") {
            Write-Log "Operation cancelled by user"
            Write-Host "Operation cancelled" -ForegroundColor Yellow
            exit 0
        }
    } else {
        Write-Log "Force mode: Overwriting existing files"
        # Remove existing files
        Remove-Item $certFile -Force -ErrorAction SilentlyContinue
        Remove-Item $keyFile -Force -ErrorAction SilentlyContinue
    }
}

Write-Log "Generating self-signed SSL certificate for $Domain..."
Write-Host "Generating self-signed SSL certificate for $Domain..." -ForegroundColor Cyan

$cert = $null
$certPath = $null

try {
    # Use PowerShell cmdlet to generate certificate
    Write-Log "Step 1: Creating self-signed certificate in certificate store..."
    
    $cert = New-SelfSignedCertificate `
        -DnsName $Domain, "localhost" `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -KeyExportPolicy Exportable `
        -KeyUsage DigitalSignature, KeyEncipherment `
        -KeyLength 2048 `
        -KeyAlgorithm RSA `
        -HashAlgorithm SHA256 `
        -NotAfter (Get-Date).AddDays($Days) `
        -FriendlyName "nginx SSL Certificate for $Domain"
    
    if (-not $cert) {
        throw "Failed to create certificate - New-SelfSignedCertificate returned null"
    }
    
    Write-Log "Certificate created successfully. Thumbprint: $($cert.Thumbprint)"
    
    # Export certificate to PFX
    Write-Log "Step 2: Exporting certificate to PFX format..."
    $certPassword = ConvertTo-SecureString -String "temppass123" -Force -AsPlainText
    $certPath = Join-Path $env:TEMP "$Domain.pfx"
    
    $exportResult = Export-PfxCertificate -Cert $cert -FilePath $certPath -Password $certPassword
    
    if (-not (Test-Path $certPath)) {
        throw "Failed to export PFX file to $certPath"
    }
    
    Write-Log "PFX exported successfully: $certPath"
    
    # Convert PFX to PEM format
    Write-Log "Step 3: Converting PFX to PEM format..."
    
    # Check for OpenSSL
    $opensslPath = Get-Command openssl -ErrorAction SilentlyContinue
    
    if ($opensslPath) {
        Write-Log "OpenSSL found: $($opensslPath.Source)"
        
        # Extract certificate
        Write-Log "Extracting certificate..."
        $certResult = & openssl pkcs12 -in $certPath -out $certFile -nokeys -passin pass:temppass123 2>&1
        Write-Log "Certificate extraction result: $certResult"
        
        # Extract private key
        Write-Log "Extracting private key..."
        $keyResult = & openssl pkcs12 -in $certPath -out $keyFile -nocerts -nodes -passin pass:temppass123 2>&1
        Write-Log "Private key extraction result: $keyResult"
        
        # Verify files were created
        if (-not (Test-Path $certFile)) {
            throw "Certificate file was not created: $certFile"
        }
        if (-not (Test-Path $keyFile)) {
            throw "Key file was not created: $keyFile"
        }
        
        Write-Log "OpenSSL conversion completed successfully"
        
    } else {
        Write-Log "OpenSSL not found, using .NET fallback method" "WARN"
        
        # Fallback: Export certificate using .NET (Base64 PEM format)
        Write-Log "Exporting certificate in PEM format using .NET..."
        
        # Export certificate
        $certBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
        $certBase64 = [System.Convert]::ToBase64String($certBytes, [System.Base64FormattingOptions]::InsertLineBreaks)
        $certPem = "-----BEGIN CERTIFICATE-----`r`n$certBase64`r`n-----END CERTIFICATE-----"
        [System.IO.File]::WriteAllText($certFile, $certPem)
        Write-Log "Certificate exported: $certFile"
        
        # Export private key - use multiple fallback methods for .NET Framework compatibility
        Write-Log "Exporting private key..."
        $keyExported = $false
        
        # Method 1: Try using certutil to convert PFX to PEM
        try {
            Write-Log "Attempting Method 1: Using certutil for conversion..."
            
            # First export to a separate RSA key using certutil
            $tempKeyPfx = Join-Path $env:TEMP "$Domain-key.pfx"
            
            # Use .NET to get private key parameters directly
            if ($cert.HasPrivateKey) {
                Write-Log "Certificate has private key, attempting extraction..."
                
                # Try to get the RSA private key using different methods
                $rsaKey = $null
                
                # Method 1a: Try GetRSAPrivateKey (requires .NET 4.6+)
                try {
                    $rsaKey = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
                    Write-Log "Got RSA key via RSACertificateExtensions"
                } catch {
                    Write-Log "RSACertificateExtensions failed: $_" "WARN"
                }
                
                # Method 1b: Try PrivateKey property (older .NET)
                if (-not $rsaKey) {
                    try {
                        $rsaKey = $cert.PrivateKey
                        Write-Log "Got RSA key via PrivateKey property"
                    } catch {
                        Write-Log "PrivateKey property failed: $_" "WARN"
                    }
                }
                
                if ($rsaKey) {
                    # Try to export using ToXmlString or ExportParameters
                    try {
                        # Export RSA parameters
                        $rsaParams = $rsaKey.ExportParameters($true)
                        Write-Log "RSA parameters exported successfully"
                        
                        # Build RSA private key manually in PEM format
                        # This creates a PKCS#1 RSA private key
                        $keyPem = ConvertTo-RsaPrivateKeyPem -RSAParameters $rsaParams
                        [System.IO.File]::WriteAllText($keyFile, $keyPem)
                        Write-Log "Private key exported using RSA parameters"
                        $keyExported = $true
                    } catch {
                        Write-Log "Failed to export RSA parameters: $_" "WARN"
                    }
                }
            }
        } catch {
            Write-Log "Method 1 failed: $_" "WARN"
        }
        
        # Method 2: If still not exported, try using the PFX file with pure .NET
        if (-not $keyExported) {
            try {
                Write-Log "Attempting Method 2: Using X509Certificate2 collection..."
                
                # Load the PFX file
                $pfxCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(
                    $certPath, 
                    "temppass123", 
                    [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
                )
                
                if ($pfxCert.HasPrivateKey) {
                    $privKey = $pfxCert.PrivateKey
                    if ($privKey) {
                        $rsaParams = $privKey.ExportParameters($true)
                        $keyPem = ConvertTo-RsaPrivateKeyPem -RSAParameters $rsaParams
                        [System.IO.File]::WriteAllText($keyFile, $keyPem)
                        Write-Log "Private key exported from PFX"
                        $keyExported = $true
                    }
                }
                $pfxCert.Dispose()
            } catch {
                Write-Log "Method 2 failed: $_" "WARN"
            }
        }
        
        if (-not $keyExported) {
            Write-Log "All private key export methods failed" "ERROR"
            Write-Host "Warning: Private key could not be exported without OpenSSL." -ForegroundColor Yellow
            Write-Host "Please install OpenSSL for full functionality:" -ForegroundColor Yellow
            Write-Host "  Download from: https://slproweb.com/products/Win32OpenSSL.html" -ForegroundColor Cyan
        }
    }
    
    # Clean up temporary files
    Write-Log "Step 4: Cleaning up temporary files..."
    if ($certPath -and (Test-Path $certPath)) {
        Remove-Item $certPath -Force -ErrorAction SilentlyContinue
        Write-Log "Removed temporary PFX file"
    }
    
    # Remove certificate from store
    if ($cert -and $cert.Thumbprint) {
        $storeCert = Get-ChildItem "Cert:\CurrentUser\My" | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
        if ($storeCert) {
            $storeCert | Remove-Item -Force
            Write-Log "Removed certificate from store"
        }
    }
    
    # Verify final output
    Write-Log "Step 5: Verifying generated files..."
    $certExists = Test-Path $certFile
    $keyExists = Test-Path $keyFile
    
    Write-Log "Certificate file exists: $certExists"
    Write-Log "Key file exists: $keyExists"
    
    if ($certExists) {
        $certSize = (Get-Item $certFile).Length
        Write-Log "Certificate file size: $certSize bytes"
    }
    if ($keyExists) {
        $keySize = (Get-Item $keyFile).Length
        Write-Log "Key file size: $keySize bytes"
    }
    
    if ($certExists -and $keyExists) {
        Write-Log "=== SSL Certificate Generation Completed Successfully ===" "SUCCESS"
        Write-Host "`nSSL certificate generated successfully!" -ForegroundColor Green
        Write-Host "  Certificate: $certFile" -ForegroundColor Cyan
        Write-Host "  Private Key: $keyFile" -ForegroundColor Cyan
        Write-Host "  Valid for: $Days days" -ForegroundColor Cyan
        Write-Host "`nNote: This is a self-signed certificate for development only." -ForegroundColor Yellow
        Write-Host "Browsers will show security warnings (this is normal)." -ForegroundColor Yellow
        exit 0
    } elseif ($certExists -and -not $keyExists) {
        Write-Log "Certificate generated but private key export failed" "WARN"
        Write-Host "`nCertificate generated but private key could not be exported." -ForegroundColor Yellow
        Write-Host "Install OpenSSL and try again for full functionality." -ForegroundColor Yellow
        exit 1
    } else {
        throw "Failed to generate certificate files"
    }
    
} catch {
    $errorMessage = $_.Exception.Message
    $errorLine = $_.InvocationInfo.ScriptLineNumber
    Write-Log "Error at line $errorLine : $errorMessage" "ERROR"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    
    Write-Host "Error generating certificate: $errorMessage" -ForegroundColor Red
    
    # Clean up on failure
    if ($certPath -and (Test-Path $certPath)) {
        Remove-Item $certPath -Force -ErrorAction SilentlyContinue
    }
    if ($cert -and $cert.Thumbprint) {
        Get-ChildItem "Cert:\CurrentUser\My" | Where-Object { $_.Thumbprint -eq $cert.Thumbprint } | Remove-Item -Force -ErrorAction SilentlyContinue
    }
    
    Write-Log "=== SSL Certificate Generation Failed ===" "ERROR"
    exit 1
}
