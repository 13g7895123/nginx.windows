# GUI Helper Functions Module with Logging

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$guiLogFile = Join-Path $projectRoot "logs\gui.log"

# Initialize log directory
$logDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Logging function
function Write-GuiLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] [$Level] $Message"
        Add-Content -Path $guiLogFile -Value $logMessage -ErrorAction SilentlyContinue
        
        if ($Level -eq "ERROR") {
            Write-Host $logMessage -ForegroundColor Red
        } else {
            Write-Host $logMessage
        }
    } catch {
        Write-Host "Failed to write log: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Write a text file using UTF-8 without BOM (nginx fails to parse BOM-prefixed configs)
function Set-FileUtf8NoBom {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Content
    )

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

Write-GuiLog "=== GUI Helper Module Loaded ==="
Write-GuiLog "Log file: $guiLogFile"

function Start-NginxService {
    Write-GuiLog "User clicked Start button"
    try {
        $managerScript = Join-Path $scriptPath "nginx-manager.ps1"
        Write-GuiLog "Executing: $managerScript -Action start"
        
        $result = & $managerScript -Action start 2>&1
        
        Write-GuiLog "nginx started successfully" "SUCCESS"
        [System.Windows.Forms.MessageBox]::Show("nginx started successfully!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Failed to start nginx: $errorMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Failed to start nginx:`n$errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Stop-NginxService {
    Write-GuiLog "User clicked Stop button"
    try {
        $managerScript = Join-Path $scriptPath "nginx-manager.ps1"
        Write-GuiLog "Executing: $managerScript -Action stop"
        
        $result = & $managerScript -Action stop 2>&1
        
        Write-GuiLog "nginx stopped successfully" "SUCCESS"
        [System.Windows.Forms.MessageBox]::Show("nginx stopped", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Failed to stop nginx: $errorMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Failed to stop nginx:`n$errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Reload-NginxService {
    Write-GuiLog "User clicked Reload button"
    try {
        $managerScript = Join-Path $scriptPath "nginx-manager.ps1"
        Write-GuiLog "Executing: $managerScript -Action reload"
        
        $result = & $managerScript -Action reload 2>&1
        
        Write-GuiLog "Configuration reloaded successfully" "SUCCESS"
        [System.Windows.Forms.MessageBox]::Show("Configuration reloaded!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Failed to reload configuration: $errorMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Failed to reload:`n$errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Restart-NginxService {
    Write-GuiLog "User clicked Restart button"
    try {
        $managerScript = Join-Path $scriptPath "nginx-manager.ps1"
        Write-GuiLog "Executing: $managerScript -Action restart"
        
        $result = & $managerScript -Action restart 2>&1
        
        Write-GuiLog "nginx restarted successfully" "SUCCESS"
        [System.Windows.Forms.MessageBox]::Show("nginx restarted!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Failed to restart nginx: $errorMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Failed to restart:`n$errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Test-NginxConfig {
    Write-GuiLog "User clicked Test Config button"
    try {
        $managerScript = Join-Path $scriptPath "nginx-manager.ps1"
        Write-GuiLog "Executing: $managerScript -Action test"
        
        $result = & $managerScript -Action test 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-GuiLog "Configuration test passed" "SUCCESS"
            [System.Windows.Forms.MessageBox]::Show("Configuration test passed!`n`n$result", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } else {
            Write-GuiLog "Configuration test failed: $result" "ERROR"
            [System.Windows.Forms.MessageBox]::Show("Configuration test failed!`n`n$result", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Test failed with exception: $errorMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Test failed:`n$errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Show-AddProxyDialog {
    Write-GuiLog "User clicked Add Proxy button"
    
    $addForm = New-Object System.Windows.Forms.Form
    $addForm.Text = "Add Reverse Proxy"
    $addForm.Size = New-Object System.Drawing.Size(500, 380)
    $addForm.StartPosition = "CenterParent"
    $addForm.FormBorderStyle = "FixedDialog"
    $addForm.MaximizeBox = $false
    
    $domainLabel = New-Object System.Windows.Forms.Label
    $domainLabel.Location = New-Object System.Drawing.Point(20, 20)
    $domainLabel.Size = New-Object System.Drawing.Size(100, 20)
    $domainLabel.Text = "Domain:"
    $addForm.Controls.Add($domainLabel)
    
    $domainText = New-Object System.Windows.Forms.TextBox
    $domainText.Location = New-Object System.Drawing.Point(130, 18)
    $domainText.Size = New-Object System.Drawing.Size(320, 25)
    $domainText.Text = "example.local"
    $addForm.Controls.Add($domainText)
    
    $targetLabel = New-Object System.Windows.Forms.Label
    $targetLabel.Location = New-Object System.Drawing.Point(20, 60)
    $targetLabel.Size = New-Object System.Drawing.Size(100, 20)
    $targetLabel.Text = "Target URL:"
    $addForm.Controls.Add($targetLabel)
    
    $targetText = New-Object System.Windows.Forms.TextBox
    $targetText.Location = New-Object System.Drawing.Point(130, 58)
    $targetText.Size = New-Object System.Drawing.Size(320, 25)
    $targetText.Text = "http://localhost:3000"
    $addForm.Controls.Add($targetText)
    
    $typeLabel = New-Object System.Windows.Forms.Label
    $typeLabel.Location = New-Object System.Drawing.Point(20, 100)
    $typeLabel.Size = New-Object System.Drawing.Size(100, 20)
    $typeLabel.Text = "Proxy Type:"
    $addForm.Controls.Add($typeLabel)
    
    $typeCombo = New-Object System.Windows.Forms.ComboBox
    $typeCombo.Location = New-Object System.Drawing.Point(130, 98)
    $typeCombo.Size = New-Object System.Drawing.Size(320, 25)
    $typeCombo.DropDownStyle = "DropDownList"
    $typeCombo.Items.AddRange(@("http", "https", "websocket"))
    $typeCombo.SelectedIndex = 0
    $addForm.Controls.Add($typeCombo)
    
    $hostsCheck = New-Object System.Windows.Forms.CheckBox
    $hostsCheck.Location = New-Object System.Drawing.Point(130, 140)
    $hostsCheck.Size = New-Object System.Drawing.Size(320, 25)
    $hostsCheck.Text = "Auto add to Windows hosts file (requires admin)"
    $hostsCheck.Checked = $true
    $addForm.Controls.Add($hostsCheck)
    
    $infoLabel = New-Object System.Windows.Forms.Label
    $infoLabel.Location = New-Object System.Drawing.Point(20, 180)
    $infoLabel.Size = New-Object System.Drawing.Size(450, 100)
    $infoLabel.Text = @"
Example:
- Domain: myapp.local
- Target URL: http://localhost:3000
- Type: http (general), https (with cert), websocket

If you select https, a self-signed certificate will be generated automatically.
Remember to reload nginx configuration after adding.
"@
    $addForm.Controls.Add($infoLabel)
    
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(250, 300)
    $okButton.Size = New-Object System.Drawing.Size(100, 35)
    $okButton.Text = "OK"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $addForm.Controls.Add($okButton)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(360, 300)
    $cancelButton.Size = New-Object System.Drawing.Size(100, 35)
    $cancelButton.Text = "Cancel"
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $addForm.Controls.Add($cancelButton)
    
    $addForm.AcceptButton = $okButton
    $addForm.CancelButton = $cancelButton
    
    $result = $addForm.ShowDialog()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $domain = $domainText.Text.Trim()
        $target = $targetText.Text.Trim()
        $type = $typeCombo.SelectedItem
        $addHosts = $hostsCheck.Checked
        
        Write-GuiLog "Adding proxy: Domain=$domain, Target=$target, Type=$type, AddHosts=$addHosts"
        
        if ([string]::IsNullOrWhiteSpace($domain) -or [string]::IsNullOrWhiteSpace($target)) {
            Write-GuiLog "Validation failed: Domain or Target URL is empty" "ERROR"
            [System.Windows.Forms.MessageBox]::Show("Domain and Target URL cannot be empty!", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }
        
        try {
            $addProxyScript = Join-Path $scriptPath "add-proxy.ps1"
            
            # Build parameter hashtable for proper splatting
            $scriptParams = @{
                Domain = $domain
                TargetUrl = $target
                Type = $type
            }
            if ($addHosts) {
                $scriptParams.Add("AddToHosts", $true)
            }
            
            Write-GuiLog "Executing: $addProxyScript -Domain $domain -TargetUrl $target -Type $type $(if($addHosts){'-AddToHosts'})"
            $output = & $addProxyScript @scriptParams 2>&1
            
            Write-GuiLog "Script output: $output"
            
            if ($LASTEXITCODE -eq 0) {
                Write-GuiLog "Proxy added successfully: $domain -> $target" "SUCCESS"
                [System.Windows.Forms.MessageBox]::Show("Proxy added successfully!`n`nRemember to reload nginx configuration.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                Load-ProxyList
            } else {
                Write-GuiLog "Failed to add proxy (exit code: $LASTEXITCODE): $output" "ERROR"
                [System.Windows.Forms.MessageBox]::Show("Failed to add proxy:`n`n$output", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        } catch {
            $errorMsg = $_.Exception.Message
            Write-GuiLog "Error adding proxy: $errorMsg" "ERROR"
            [System.Windows.Forms.MessageBox]::Show("Error adding proxy:`n$errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    } else {
        Write-GuiLog "User cancelled Add Proxy dialog"
    }
}

function Edit-SelectedProxy {
    Write-GuiLog "User clicked Edit Config button"
    
    if ($proxyGrid.SelectedRows.Count -eq 0) {
        Write-GuiLog "No proxy selected for editing" "WARN"
        [System.Windows.Forms.MessageBox]::Show("Please select a proxy configuration first!", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    $selectedRow = $proxyGrid.SelectedRows[0]
    $configFile = $selectedRow.Cells[0].Value
    $confPath = Join-Path $projectRoot "conf.d\$configFile"
    
    Write-GuiLog "Opening config file for editing: $confPath"
    
    if (Test-Path $confPath) {
        Start-Process notepad.exe -ArgumentList $confPath
        Write-GuiLog "Config file opened in notepad: $configFile" "SUCCESS"
    } else {
        Write-GuiLog "Config file not found: $confPath" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Config file not found: $confPath", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Remove-SelectedProxy {
    Write-GuiLog "User clicked Delete Proxy button"
    
    if ($proxyGrid.SelectedRows.Count -eq 0) {
        Write-GuiLog "No proxy selected for deletion" "WARN"
        [System.Windows.Forms.MessageBox]::Show("Please select a proxy configuration first!", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    $selectedRow = $proxyGrid.SelectedRows[0]
    $configFile = $selectedRow.Cells[0].Value
    $domain = $selectedRow.Cells[1].Value.Split(',')[0].Trim()
    
    Write-GuiLog "Delete proxy requested: $domain (config: $configFile)"
    
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Delete this proxy configuration?`n`nConfig: $configFile`nDomain: $domain`n`nAlso remove from hosts file?",
        "Confirm Delete",
        [System.Windows.Forms.MessageBoxButtons]::YesNoCancel,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes -or $result -eq [System.Windows.Forms.DialogResult]::No) {
        try {
            $removeProxyScript = Join-Path $scriptPath "remove-proxy.ps1"
            
            # Build parameter hashtable for proper splatting
            $scriptParams = @{
                Domain = $domain
                Force = $true
            }
            
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                $scriptParams.Add("RemoveFromHosts", $true)
                Write-GuiLog "Deleting proxy with hosts removal: $domain"
            } else {
                Write-GuiLog "Deleting proxy without hosts removal: $domain"
            }
            
            Write-GuiLog "Executing: $removeProxyScript -Domain $domain -Force $(if($result -eq [System.Windows.Forms.DialogResult]::Yes){'-RemoveFromHosts'})"
            $output = & $removeProxyScript @scriptParams 2>&1
            
            Write-GuiLog "Script output: $output"
            
            if ($LASTEXITCODE -eq 0) {
                Write-GuiLog "Proxy deleted successfully: $domain" "SUCCESS"
                [System.Windows.Forms.MessageBox]::Show("Proxy deleted successfully!`n`nRemember to reload nginx configuration.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                Load-ProxyList
            } else {
                Write-GuiLog "Failed to delete proxy: $output" "ERROR"
                [System.Windows.Forms.MessageBox]::Show("Failed to delete proxy:`n`n$output", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        } catch {
            $errorMsg = $_.Exception.Message
            Write-GuiLog "Error deleting proxy: $errorMsg" "ERROR"
            [System.Windows.Forms.MessageBox]::Show("Error deleting proxy:`n$errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    } else {
        Write-GuiLog "User cancelled proxy deletion"
    }
}

function Show-GenerateSslDialog {
    Write-GuiLog "User clicked Generate Certificate button"
    
    # Get list of domains from existing proxy configurations
    $proxyDomains = @()
    $confDir = Join-Path $projectRoot "conf.d"
    if (Test-Path $confDir) {
        $configs = Get-ChildItem -Path $confDir -Filter "*.conf" -ErrorAction SilentlyContinue
        foreach ($config in $configs) {
            try {
                $content = Get-Content -Path $config.FullName -Raw -ErrorAction SilentlyContinue
                if ($content -match 'server_name\s+([^;]+);') {
                    $domains = $matches[1] -split '\s+' | Where-Object { $_ -ne '' }
                    foreach ($d in $domains) {
                        if ($d -and $d -ne 'localhost' -and $proxyDomains -notcontains $d) {
                            $proxyDomains += $d
                        }
                    }
                }
            } catch {
                Write-GuiLog "Error reading config $($config.Name): $_" "WARN"
            }
        }
    }
    Write-GuiLog "Found proxy domains: $($proxyDomains -join ', ')"
    
    $sslForm = New-Object System.Windows.Forms.Form
    $sslForm.Text = "Generate SSL Certificate"
    $sslForm.Size = New-Object System.Drawing.Size(500, 400)
    $sslForm.StartPosition = "CenterParent"
    $sslForm.FormBorderStyle = "FixedDialog"
    $sslForm.MaximizeBox = $false
    
    $domainLabel = New-Object System.Windows.Forms.Label
    $domainLabel.Location = New-Object System.Drawing.Point(20, 20)
    $domainLabel.Size = New-Object System.Drawing.Size(100, 20)
    $domainLabel.Text = "Domain:"
    $sslForm.Controls.Add($domainLabel)
    
    # Domain dropdown (ComboBox)
    $domainCombo = New-Object System.Windows.Forms.ComboBox
    $domainCombo.Location = New-Object System.Drawing.Point(130, 18)
    $domainCombo.Size = New-Object System.Drawing.Size(320, 25)
    $domainCombo.DropDownStyle = "DropDown"  # Allow custom input too
    
    if ($proxyDomains.Count -gt 0) {
        $domainCombo.Items.AddRange($proxyDomains)
        $domainCombo.SelectedIndex = 0
    } else {
        $domainCombo.Text = "example.local"
    }
    $sslForm.Controls.Add($domainCombo)
    
    $daysLabel = New-Object System.Windows.Forms.Label
    $daysLabel.Location = New-Object System.Drawing.Point(20, 60)
    $daysLabel.Size = New-Object System.Drawing.Size(100, 20)
    $daysLabel.Text = "Valid Days:"
    $sslForm.Controls.Add($daysLabel)
    
    $daysText = New-Object System.Windows.Forms.NumericUpDown
    $daysText.Location = New-Object System.Drawing.Point(130, 58)
    $daysText.Size = New-Object System.Drawing.Size(320, 25)
    $daysText.Minimum = 1
    $daysText.Maximum = 3650
    $daysText.Value = 365
    $sslForm.Controls.Add($daysText)
    
    # Auto-update config checkbox
    $autoUpdateCheck = New-Object System.Windows.Forms.CheckBox
    $autoUpdateCheck.Location = New-Object System.Drawing.Point(130, 98)
    $autoUpdateCheck.Size = New-Object System.Drawing.Size(320, 25)
    $autoUpdateCheck.Text = "Auto-update nginx config to HTTPS"
    $autoUpdateCheck.Checked = $true
    $sslForm.Controls.Add($autoUpdateCheck)
    
    $infoLabel = New-Object System.Windows.Forms.Label
    $infoLabel.Location = New-Object System.Drawing.Point(20, 135)
    $infoLabel.Size = New-Object System.Drawing.Size(450, 140)
    $infoLabel.Text = @"
This will generate a self-signed SSL certificate for the selected domain.

Generated files:
- Certificate: ssl\<domain>.crt
- Private Key: ssl\<domain>.key

If 'Auto-update nginx config' is checked:
- Add HTTPS (port 443) server block with SSL settings
- Add HTTP to HTTPS redirect (port 80)
- Automatically reload nginx configuration

Note: Self-signed certificates are for development only.
"@
    $sslForm.Controls.Add($infoLabel)
    
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(250, 310)
    $okButton.Size = New-Object System.Drawing.Size(100, 35)
    $okButton.Text = "Generate"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $sslForm.Controls.Add($okButton)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(360, 310)
    $cancelButton.Size = New-Object System.Drawing.Size(100, 35)
    $cancelButton.Text = "Cancel"
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $sslForm.Controls.Add($cancelButton)
    
    $sslForm.AcceptButton = $okButton
    $sslForm.CancelButton = $cancelButton
    
    $result = $sslForm.ShowDialog()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $domain = $domainCombo.Text.Trim()
        $days = $daysText.Value
        $autoUpdate = $autoUpdateCheck.Checked
        
        Write-GuiLog "Generating SSL certificate: Domain=$domain, Days=$days, AutoUpdate=$autoUpdate"
        
        if ([string]::IsNullOrWhiteSpace($domain)) {
            Write-GuiLog "Validation failed: Domain is empty" "ERROR"
            [System.Windows.Forms.MessageBox]::Show("Domain cannot be empty!", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }
        
        try {
            # Step 1: Generate SSL certificate
            $generateSslScript = Join-Path $scriptPath "generate-ssl.ps1"
            Write-GuiLog "Executing: $generateSslScript -Domain $domain -Days $days -Force"
            
            $output = & $generateSslScript -Domain $domain -Days $days -Force 2>&1
            
            Write-GuiLog "Script output: $output"
            Write-GuiLog "Exit code: $LASTEXITCODE"
            
            if ($LASTEXITCODE -ne 0) {
                Write-GuiLog "Failed to generate SSL certificate: $output" "ERROR"
                [System.Windows.Forms.MessageBox]::Show("Failed to generate SSL certificate:`n`n$output", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                return
            }
            
            Write-GuiLog "SSL certificate generated successfully: $domain" "SUCCESS"
            
            # Step 2: Auto-update nginx config if checked
            if ($autoUpdate) {
                Write-GuiLog "Auto-updating nginx config for $domain..."
                $updateResult = Update-ProxyToHttps -Domain $domain
                
                if ($updateResult) {
                    Write-GuiLog "nginx config updated successfully" "SUCCESS"
                    
                    # Reload nginx
                    Write-GuiLog "Reloading nginx configuration..."
                    $managerScript = Join-Path $scriptPath "nginx-manager.ps1"
                    & $managerScript -Action reload 2>&1 | Out-Null
                    
                    [System.Windows.Forms.MessageBox]::Show(
                        "SSL certificate generated and nginx config updated!`n`nDomain: $domain`n`nChanges:`n- HTTPS server on port 443 with SSL`n- HTTP (port 80) redirects to HTTPS`n- Certificate: ssl\$domain.crt`n- Private Key: ssl\$domain.key`n`nConfiguration reloaded successfully.",
                        "Success",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Information
                    )
                } else {
                    [System.Windows.Forms.MessageBox]::Show(
                        "SSL certificate generated but failed to update nginx config.`n`nPlease manually update the configuration.",
                        "Partial Success",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Warning
                    )
                }
            } else {
                [System.Windows.Forms.MessageBox]::Show(
                    "SSL certificate generated successfully!`n`nDomain: $domain`nCertificate: ssl\$domain.crt`nPrivate Key: ssl\$domain.key`n`nRemember to manually update nginx config to use HTTPS.",
                    "Success",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            }
            
            Load-SslList
            Load-ProxyList
            
        } catch {
            $errorMsg = $_.Exception.Message
            Write-GuiLog "Error generating certificate: $errorMsg" "ERROR"
            [System.Windows.Forms.MessageBox]::Show("Error generating certificate:`n$errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    } else {
        Write-GuiLog "User cancelled SSL certificate generation"
    }
}

# Function to update proxy configuration to HTTPS
function Update-ProxyToHttps {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Domain
    )
    
    Write-GuiLog "Updating proxy config to HTTPS for: $Domain"
    
    try {
        $confDir = Join-Path $projectRoot "conf.d"
        $sslDir = Join-Path $projectRoot "ssl"
        
        # Find config file for this domain
        $configFile = $null
        $configs = Get-ChildItem -Path $confDir -Filter "*.conf" -ErrorAction SilentlyContinue
        
        foreach ($config in $configs) {
            $content = Get-Content -Path $config.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -match "server_name\s+[^;]*\b$([regex]::Escape($Domain))\b") {
                $configFile = $config.FullName
                Write-GuiLog "Found config file: $($config.Name)"
                break
            }
        }
        
        if (-not $configFile) {
            Write-GuiLog "No config file found for domain: $Domain" "ERROR"
            return $false
        }
        
        # Read existing config
        $originalContent = Get-Content -Path $configFile -Raw
        
        # Extract proxy_pass URL from existing config
        $proxyPass = "http://localhost:3000"
        if ($originalContent -match 'proxy_pass\s+([^;]+);') {
            $proxyPass = $matches[1].Trim()
        }
        Write-GuiLog "Extracted proxy_pass: $proxyPass"
        
        # Extract all location blocks (handle nested braces)
        $locationBlocks = ""
        
        # Use a more robust regex to extract location blocks
        $locationPattern = '(?s)location\s+[^\{]+\{(?:[^\{\}]|\{[^\}]*\})*\}'
        $locationMatches = [regex]::Matches($originalContent, $locationPattern)
        
        if ($locationMatches.Count -gt 0) {
            foreach ($match in $locationMatches) {
                $locationBlock = $match.Value.Trim()
                $locationBlocks += "    $locationBlock`n`n"
            }
            Write-GuiLog "Extracted $($locationMatches.Count) location block(s)"
        }
        
        # If no location blocks found, create a default one
        if ([string]::IsNullOrWhiteSpace($locationBlocks)) {
            Write-GuiLog "No location blocks found, creating default"
            $locationBlocks = @"
    location / {
        proxy_pass $proxyPass;
        proxy_http_version 1.1;
        
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;
        
        # WebSocket support
        proxy_set_header Upgrade `$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
"@
        }
        
        # Create new HTTPS config with both server blocks
        $httpsConfig = @"
# HTTPS Reverse Proxy Configuration
# Domain: $Domain
# Target: $proxyPass
# SSL Updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

# HTTPS Server (Port 443)
server {
    listen       443 ssl;
    server_name  $Domain;

    # SSL Certificate
    ssl_certificate      ../ssl/$Domain.crt;
    ssl_certificate_key  ../ssl/$Domain.key;

    # SSL Security Settings
    ssl_session_cache    shared:SSL:1m;
    ssl_session_timeout  5m;
    ssl_protocols        TLSv1.2 TLSv1.3;
    ssl_ciphers          HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers  on;

    # Logs
    access_log  ../logs/$Domain.access.log  main;
    error_log   ../logs/$Domain.error.log;

$locationBlocks
}

# HTTP to HTTPS Redirect (Port 80)
server {
    listen       80;
    server_name  $Domain;
    return 301 https://`$server_name`$request_uri;
}
"@
        
        # Backup original config
        $backupFile = "$configFile.bak"
        Copy-Item -Path $configFile -Destination $backupFile -Force
        Write-GuiLog "Backed up original config to: $backupFile"
        
    # Write new config without UTF-8 BOM to keep nginx happy
    Set-FileUtf8NoBom -Path $configFile -Content $httpsConfig
        Write-GuiLog "Wrote new HTTPS config to: $configFile"
        
        # Test configuration
        $managerScript = Join-Path $scriptPath "nginx-manager.ps1"
        $testOutput = & $managerScript -Action test 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-GuiLog "Config test failed, restoring backup: $testOutput" "ERROR"
            Copy-Item -Path $backupFile -Destination $configFile -Force
            [System.Windows.Forms.MessageBox]::Show(
                "nginx configuration test failed!`n`n$testOutput`n`nOriginal configuration has been restored.",
                "Configuration Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            return $false
        }
        
        Write-GuiLog "Config test passed"
        return $true
        
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Error updating config to HTTPS: $errorMsg" "ERROR"
        return $false
    }
}

function Clear-LogContent {
    Write-GuiLog "User clicked Clear Log button"
    
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Clear the current log file?`n`nThis action cannot be undone!",
        "Confirm Clear",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        $logType = $logTypeCombo.SelectedItem
        $logFile = Join-Path $projectRoot "logs\$logType"
        
        Write-GuiLog "Clearing log file: $logFile"
        
        try {
            Clear-Content -Path $logFile -ErrorAction Stop
            $logTextBox.Text = ""
            Write-GuiLog "Log cleared successfully: $logType" "SUCCESS"
            [System.Windows.Forms.MessageBox]::Show("Log cleared", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            $errorMsg = $_.Exception.Message
            Write-GuiLog "Failed to clear log: $errorMsg" "ERROR"
            [System.Windows.Forms.MessageBox]::Show("Failed to clear log:`n$errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    } else {
        Write-GuiLog "User cancelled log clear operation"
    }
}
