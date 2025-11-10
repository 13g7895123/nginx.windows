# nginx GUI Management Tool
# Run with: powershell.exe -ExecutionPolicy Bypass -File nginx-gui.ps1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath

# Check if running as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    $result = [System.Windows.Forms.MessageBox]::Show(
        "nginx GUI requires Administrator privileges to manage nginx service and modify hosts file.`n`nWould you like to restart as Administrator?",
        "Administrator Privileges Required",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        $scriptFile = $MyInvocation.MyCommand.Path
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptFile`"" -Verb RunAs
    }
    exit
}

# Load helper functions
. (Join-Path $scriptPath "gui-helpers.ps1")

# Global UI elements (script scope for access from helper functions)
$script:proxyGrid = $null
$script:sslListBox = $null
$script:logTextBox = $null
$script:logTypeCombo = $null
$script:statusLabel = $null

# Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "nginx Management Console"
$form.Size = New-Object System.Drawing.Size(900, 650)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Status Bar
$script:statusLabel = New-Object System.Windows.Forms.Label
$script:statusLabel.Location = New-Object System.Drawing.Point(10, 590)
$script:statusLabel.Size = New-Object System.Drawing.Size(860, 20)
$script:statusLabel.Text = "Ready"
$script:statusLabel.BorderStyle = "Fixed3D"
$form.Controls.Add($script:statusLabel)

# Tab Control
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(10, 10)
$tabControl.Size = New-Object System.Drawing.Size(860, 570)
$form.Controls.Add($tabControl)

# ==================== TAB 1: Proxy Management ====================
$proxyTab = New-Object System.Windows.Forms.TabPage
$proxyTab.Text = "Proxy Management"
$tabControl.Controls.Add($proxyTab)

# Service Control Panel
$servicePanel = New-Object System.Windows.Forms.GroupBox
$servicePanel.Location = New-Object System.Drawing.Point(10, 10)
$servicePanel.Size = New-Object System.Drawing.Size(830, 80)
$servicePanel.Text = "nginx Service Control"
$proxyTab.Controls.Add($servicePanel)

$startBtn = New-Object System.Windows.Forms.Button
$startBtn.Location = New-Object System.Drawing.Point(20, 30)
$startBtn.Size = New-Object System.Drawing.Size(100, 35)
$startBtn.Text = "Start"
$startBtn.Add_Click({
    try {
        Write-GuiLog "=== Start Button Clicked ==="
        Start-NginxService
        $script:statusLabel.Text = "nginx service started"
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Start button error: $errorMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Error: $errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$servicePanel.Controls.Add($startBtn)

$stopBtn = New-Object System.Windows.Forms.Button
$stopBtn.Location = New-Object System.Drawing.Point(140, 30)
$stopBtn.Size = New-Object System.Drawing.Size(100, 35)
$stopBtn.Text = "Stop"
$stopBtn.Add_Click({
    try {
        Write-GuiLog "=== Stop Button Clicked ==="
        Stop-NginxService
        $script:statusLabel.Text = "nginx service stopped"
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Stop button error: $errorMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Error: $errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$servicePanel.Controls.Add($stopBtn)

$reloadBtn = New-Object System.Windows.Forms.Button
$reloadBtn.Location = New-Object System.Drawing.Point(260, 30)
$reloadBtn.Size = New-Object System.Drawing.Size(100, 35)
$reloadBtn.Text = "Reload Config"
$reloadBtn.Add_Click({
    try {
        Write-GuiLog "=== Reload Button Clicked ==="
        Reload-NginxService
        $script:statusLabel.Text = "Configuration reloaded"
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Reload button error: $errorMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Error: $errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$servicePanel.Controls.Add($reloadBtn)

$restartBtn = New-Object System.Windows.Forms.Button
$restartBtn.Location = New-Object System.Drawing.Point(380, 30)
$restartBtn.Size = New-Object System.Drawing.Size(100, 35)
$restartBtn.Text = "Restart"
$restartBtn.Add_Click({
    try {
        Write-GuiLog "=== Restart Button Clicked ==="
        Restart-NginxService
        $script:statusLabel.Text = "nginx service restarted"
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Restart button error: $errorMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Error: $errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$servicePanel.Controls.Add($restartBtn)

$testBtn = New-Object System.Windows.Forms.Button
$testBtn.Location = New-Object System.Drawing.Point(500, 30)
$testBtn.Size = New-Object System.Drawing.Size(100, 35)
$testBtn.Text = "Test Config"
$testBtn.Add_Click({
    try {
        Write-GuiLog "=== Test Config Button Clicked ==="
        Test-NginxConfig
        $script:statusLabel.Text = "Configuration tested"
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Test button error: $errorMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Error: $errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$servicePanel.Controls.Add($testBtn)

$refreshBtn = New-Object System.Windows.Forms.Button
$refreshBtn.Location = New-Object System.Drawing.Point(710, 30)
$refreshBtn.Size = New-Object System.Drawing.Size(100, 35)
$refreshBtn.Text = "Refresh List"
$refreshBtn.Add_Click({
    try {
        Write-GuiLog "=== Refresh Button Clicked ==="
        Load-ProxyList
        $script:statusLabel.Text = "Proxy list refreshed"
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Refresh button error: $errorMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Error: $errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$servicePanel.Controls.Add($refreshBtn)

# Proxy List Panel
$listPanel = New-Object System.Windows.Forms.GroupBox
$listPanel.Location = New-Object System.Drawing.Point(10, 100)
$listPanel.Size = New-Object System.Drawing.Size(830, 350)
$listPanel.Text = "Reverse Proxy Configurations"
$proxyTab.Controls.Add($listPanel)

# DataGridView for proxy list
$script:proxyGrid = New-Object System.Windows.Forms.DataGridView
$script:proxyGrid.Location = New-Object System.Drawing.Point(10, 25)
$script:proxyGrid.Size = New-Object System.Drawing.Size(810, 280)
$script:proxyGrid.AllowUserToAddRows = $false
$script:proxyGrid.AllowUserToDeleteRows = $false
$script:proxyGrid.ReadOnly = $true
$script:proxyGrid.SelectionMode = "FullRowSelect"
$script:proxyGrid.MultiSelect = $false
$script:proxyGrid.AutoSizeColumnsMode = "Fill"
$script:proxyGrid.ColumnHeadersHeightSizeMode = "AutoSize"
$listPanel.Controls.Add($script:proxyGrid)

# Initialize columns
$script:proxyGrid.ColumnCount = 3
$script:proxyGrid.Columns[0].Name = "Config File"
$script:proxyGrid.Columns[1].Name = "Domains"
$script:proxyGrid.Columns[2].Name = "Target URL"

# Proxy operation buttons
$addProxyBtn = New-Object System.Windows.Forms.Button
$addProxyBtn.Location = New-Object System.Drawing.Point(20, 310)
$addProxyBtn.Size = New-Object System.Drawing.Size(150, 30)
$addProxyBtn.Text = "Add Proxy"
$addProxyBtn.Add_Click({
    try {
        Write-GuiLog "=== Add Proxy Button Clicked ==="
        Show-AddProxyDialog
        $script:statusLabel.Text = "Add proxy dialog opened"
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Add Proxy button error: $errorMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Error: $errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$listPanel.Controls.Add($addProxyBtn)

$editProxyBtn = New-Object System.Windows.Forms.Button
$editProxyBtn.Location = New-Object System.Drawing.Point(190, 310)
$editProxyBtn.Size = New-Object System.Drawing.Size(150, 30)
$editProxyBtn.Text = "Edit Config"
$editProxyBtn.Add_Click({
    try {
        Write-GuiLog "=== Edit Config Button Clicked ==="
        Edit-SelectedProxy
        $script:statusLabel.Text = "Editing proxy configuration"
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Edit button error: $errorMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Error: $errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$listPanel.Controls.Add($editProxyBtn)

$deleteProxyBtn = New-Object System.Windows.Forms.Button
$deleteProxyBtn.Location = New-Object System.Drawing.Point(360, 310)
$deleteProxyBtn.Size = New-Object System.Drawing.Size(150, 30)
$deleteProxyBtn.Text = "Delete Proxy"
$deleteProxyBtn.Add_Click({
    try {
        Write-GuiLog "=== Delete Proxy Button Clicked ==="
        Remove-SelectedProxy
        $script:statusLabel.Text = "Proxy deletion processed"
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Delete button error: $errorMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Error: $errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$listPanel.Controls.Add($deleteProxyBtn)

# Info Label
$infoLabel = New-Object System.Windows.Forms.Label
$infoLabel.Location = New-Object System.Drawing.Point(20, 460)
$infoLabel.Size = New-Object System.Drawing.Size(810, 80)
$infoLabel.Text = @"
Quick Guide:
1. Click ''Add Proxy'' to create a new reverse proxy configuration
2. Select a proxy and click ''Edit Config'' to manually modify the nginx configuration
3. Click ''Delete Proxy'' to remove a proxy (optionally remove from hosts file too)
4. After adding/editing/deleting, click ''Reload Config'' or ''Restart'' to apply changes
5. Use ''Test Config'' before reloading to ensure configuration is valid
"@
$proxyTab.Controls.Add($infoLabel)

# ==================== TAB 2: SSL Certificates ====================
$sslTab = New-Object System.Windows.Forms.TabPage
$sslTab.Text = "SSL Certificates"
$tabControl.Controls.Add($sslTab)

$sslPanel = New-Object System.Windows.Forms.GroupBox
$sslPanel.Location = New-Object System.Drawing.Point(10, 10)
$sslPanel.Size = New-Object System.Drawing.Size(830, 450)
$sslPanel.Text = "SSL Certificate Management"
$sslTab.Controls.Add($sslPanel)

$script:sslListBox = New-Object System.Windows.Forms.ListBox
$script:sslListBox.Location = New-Object System.Drawing.Point(15, 30)
$script:sslListBox.Size = New-Object System.Drawing.Size(800, 350)
$sslPanel.Controls.Add($script:sslListBox)

$generateSslBtn = New-Object System.Windows.Forms.Button
$generateSslBtn.Location = New-Object System.Drawing.Point(20, 395)
$generateSslBtn.Size = New-Object System.Drawing.Size(180, 35)
$generateSslBtn.Text = "Generate Certificate"
$generateSslBtn.Add_Click({
    try {
        Write-GuiLog "=== Generate Cert Button Clicked ==="
        Show-GenerateSslDialog
        $script:statusLabel.Text = "SSL certificate generation dialog opened"
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Generate Cert button error: $errorMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Error: $errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$sslPanel.Controls.Add($generateSslBtn)

$refreshSslBtn = New-Object System.Windows.Forms.Button
$refreshSslBtn.Location = New-Object System.Drawing.Point(220, 395)
$refreshSslBtn.Size = New-Object System.Drawing.Size(180, 35)
$refreshSslBtn.Text = "Refresh List"
$refreshSslBtn.Add_Click({
    try {
        Write-GuiLog "=== Refresh SSL List Button Clicked ==="
        Load-SslList
        $script:statusLabel.Text = "SSL certificate list refreshed"
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Refresh SSL button error: $errorMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Error: $errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$sslPanel.Controls.Add($refreshSslBtn)

$sslInfoLabel = New-Object System.Windows.Forms.Label
$sslInfoLabel.Location = New-Object System.Drawing.Point(20, 470)
$sslInfoLabel.Size = New-Object System.Drawing.Size(810, 60)
$sslInfoLabel.Text = @"
SSL Certificate Information:
- Self-signed certificates are suitable for development and testing environments
- Browsers will display security warnings when accessing HTTPS sites with self-signed certificates (this is normal behavior)
- For production environments, consider using Let''s Encrypt or commercial CA certificates
"@
$sslTab.Controls.Add($sslInfoLabel)

# ==================== TAB 3: Logs ====================
$logTab = New-Object System.Windows.Forms.TabPage
$logTab.Text = "Logs"
$tabControl.Controls.Add($logTab)

$logControlPanel = New-Object System.Windows.Forms.Panel
$logControlPanel.Location = New-Object System.Drawing.Point(10, 10)
$logControlPanel.Size = New-Object System.Drawing.Size(830, 50)
$logTab.Controls.Add($logControlPanel)

$logTypeLabel = New-Object System.Windows.Forms.Label
$logTypeLabel.Location = New-Object System.Drawing.Point(10, 15)
$logTypeLabel.Size = New-Object System.Drawing.Size(80, 20)
$logTypeLabel.Text = "Log Type:"
$logControlPanel.Controls.Add($logTypeLabel)

$script:logTypeCombo = New-Object System.Windows.Forms.ComboBox
$script:logTypeCombo.Location = New-Object System.Drawing.Point(100, 12)
$script:logTypeCombo.Size = New-Object System.Drawing.Size(200, 25)
$script:logTypeCombo.DropDownStyle = "DropDownList"
$script:logTypeCombo.Items.AddRange(@("gui.log", "access.log", "error.log"))
$script:logTypeCombo.SelectedIndex = 0
$logControlPanel.Controls.Add($script:logTypeCombo)

$loadLogBtn = New-Object System.Windows.Forms.Button
$loadLogBtn.Location = New-Object System.Drawing.Point(320, 10)
$loadLogBtn.Size = New-Object System.Drawing.Size(120, 30)
$loadLogBtn.Text = "Load Log"
$loadLogBtn.Add_Click({
    try {
        Write-GuiLog "=== Load Log Button Clicked ==="
        Load-LogContent
        $script:statusLabel.Text = "Log loaded: $($script:logTypeCombo.SelectedItem)"
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Load Log button error: $errorMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Error: $errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$logControlPanel.Controls.Add($loadLogBtn)

$clearLogBtn = New-Object System.Windows.Forms.Button
$clearLogBtn.Location = New-Object System.Drawing.Point(460, 10)
$clearLogBtn.Size = New-Object System.Drawing.Size(120, 30)
$clearLogBtn.Text = "Clear Log"
$clearLogBtn.Add_Click({
    try {
        Write-GuiLog "=== Clear Log Button Clicked ==="
        Clear-LogContent
        $script:statusLabel.Text = "Log cleared"
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Clear Log button error: $errorMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Error: $errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$logControlPanel.Controls.Add($clearLogBtn)

$script:logTextBox = New-Object System.Windows.Forms.TextBox
$script:logTextBox.Location = New-Object System.Drawing.Point(10, 70)
$script:logTextBox.Size = New-Object System.Drawing.Size(830, 470)
$script:logTextBox.Multiline = $true
$script:logTextBox.ScrollBars = "Both"
$script:logTextBox.ReadOnly = $true
$script:logTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$logTab.Controls.Add($script:logTextBox)

# ==================== TAB 4: About ====================
$aboutTab = New-Object System.Windows.Forms.TabPage
$aboutTab.Text = "About"
$tabControl.Controls.Add($aboutTab)

$aboutLabel = New-Object System.Windows.Forms.Label
$aboutLabel.Location = New-Object System.Drawing.Point(30, 30)
$aboutLabel.Size = New-Object System.Drawing.Size(790, 500)
$aboutLabel.Text = @"
nginx Management Console for Windows
Version: 1.0.0

Features:
- Start, stop, restart, and reload nginx service
- Test nginx configuration before applying
- Add and manage reverse proxy configurations
- Automatic Windows hosts file management (with administrator permission)
- Generate self-signed SSL certificates for HTTPS proxies
- Support for HTTP, HTTPS, and WebSocket proxies
- View and manage nginx logs (access.log, error.log)
- View GUI operation logs (gui.log)

Project Structure:
- nginx/          Main nginx executable and files
- conf/           Main nginx.conf configuration
- conf.d/         Individual proxy configuration files
- ssl/            SSL certificates and private keys
- logs/           nginx logs and GUI logs
- scripts/        PowerShell management scripts and GUI

Requirements:
- Windows 10/11 or Windows Server
- PowerShell 5.1 or later
- Administrator privileges (for hosts file modification and SSL certificate generation)

Usage Tips:
1. Always test configuration before reloading
2. Use ''Reload Config'' instead of ''Restart'' to avoid downtime
3. Self-signed certificates are for development only
4. Check logs if nginx fails to start
5. Remember to run as Administrator when modifying hosts file

Configuration Files:
- Templates are available in conf.d/*.conf.template
- Each proxy gets its own .conf file in conf.d/
- Manual configuration edits require configuration reload

For more information, see README.md in the project root directory.

Log Files:
- logs/gui.log      GUI operation and error logs
- logs/access.log   nginx access logs
- logs/error.log    nginx error logs
"@
$aboutTab.Controls.Add($aboutLabel)

# Helper functions for UI operations

function Load-ProxyList {
    Write-GuiLog "Loading proxy list"
    try {
        $script:proxyGrid.Rows.Clear()
        
        $confDir = Join-Path $projectRoot "conf.d"
        if (Test-Path $confDir) {
            $configs = Get-ChildItem -Path $confDir -Filter "*.conf" -ErrorAction SilentlyContinue
            
            Write-GuiLog "Found $($configs.Count) proxy configurations"
            
            foreach ($config in $configs) {
                try {
                    $content = Get-Content -Path $config.FullName -Raw -ErrorAction SilentlyContinue
                    
                    $domains = @()
                    if ($content -match 'server_name\s+([^;]+);') {
                        $domains = $matches[1] -split '\s+' | Where-Object { $_ -ne '' }
                    }
                    
                    $target = "N/A"
                    if ($content -match 'proxy_pass\s+([^;]+);') {
                        $target = $matches[1]
                    }
                    
                    $domainsStr = $domains -join ', '
                    $script:proxyGrid.Rows.Add($config.Name, $domainsStr, $target) | Out-Null
                    
                    Write-GuiLog "Loaded proxy: $($config.Name) - $domainsStr -> $target"
                } catch {
                    Write-GuiLog "Error parsing config $($config.Name): $($_.Exception.Message)" "ERROR"
                }
            }
        } else {
            Write-GuiLog "conf.d directory not found" "WARN"
        }
        
        $script:statusLabel.Text = "Loaded $($script:proxyGrid.Rows.Count) proxy configurations"
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Error loading proxy list: $errorMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Error loading proxy list:`n$errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Load-SslList {
    Write-GuiLog "Loading SSL certificate list"
    try {
        $script:sslListBox.Items.Clear()
        
        $sslDir = Join-Path $projectRoot "ssl"
        if (Test-Path $sslDir) {
            $certs = Get-ChildItem -Path $sslDir -Filter "*.crt" -ErrorAction SilentlyContinue
            
            Write-GuiLog "Found $($certs.Count) SSL certificates"
            
            foreach ($cert in $certs) {
                $keyFile = Join-Path $sslDir ($cert.BaseName + ".key")
                $status = if (Test-Path $keyFile) { "OK" } else { "Missing Key" }
                $script:sslListBox.Items.Add("$($cert.Name) [$status] - Modified: $($cert.LastWriteTime)") | Out-Null
                Write-GuiLog "Loaded cert: $($cert.Name) - $status"
            }
        } else {
            Write-GuiLog "SSL directory not found, creating..." "WARN"
            New-Item -ItemType Directory -Path $sslDir -Force | Out-Null
        }
        
        $script:statusLabel.Text = "Loaded $($script:sslListBox.Items.Count) SSL certificates"
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Error loading SSL list: $errorMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Error loading SSL list:`n$errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Load-LogContent {
    Write-GuiLog "Loading log content"
    try {
        $logType = $script:logTypeCombo.SelectedItem
        $logFile = Join-Path $projectRoot "logs\$logType"
        
        Write-GuiLog "Reading log file: $logFile"
        
        if (Test-Path $logFile) {
            $content = Get-Content -Path $logFile -Tail 1000 -ErrorAction SilentlyContinue
            $script:logTextBox.Text = $content -join "`r`n"
            Write-GuiLog "Loaded $($content.Count) lines from $logType"
        } else {
            $script:logTextBox.Text = "Log file not found: $logFile"
            Write-GuiLog "Log file not found: $logFile" "WARN"
        }
        
        $script:statusLabel.Text = "Loaded log: $logType"
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GuiLog "Error loading log: $errorMsg" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Error loading log:`n$errorMsg", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# Initialize
Write-GuiLog "=== nginx GUI Started ==="
Write-GuiLog "Project root: $projectRoot"
Write-GuiLog "Running with Administrator privileges: $isAdmin"

# Check and cleanup existing nginx processes
Write-GuiLog "Checking for existing nginx processes..."
$existingNginx = Get-Process -Name "nginx" -ErrorAction SilentlyContinue
if ($existingNginx) {
    Write-GuiLog "Found $($existingNginx.Count) existing nginx process(es)"
    
    # Check if port 80 is listening
    $port80 = netstat -ano | Select-String "LISTENING" | Select-String ":80 "
    
    if (-not $port80) {
        Write-GuiLog "nginx is running but NOT listening on port 80 - cleaning up..." "WARN"
        
        try {
            # Force kill all nginx processes
            taskkill /F /IM nginx.exe 2>&1 | Out-Null
            Start-Sleep -Seconds 2
            Write-GuiLog "Old nginx processes terminated" "SUCCESS"
            
            # Start nginx properly
            Write-GuiLog "Starting nginx with correct configuration..."
            $managerScript = Join-Path $scriptPath "nginx-manager.ps1"
            & $managerScript -Action start 2>&1 | Out-Null
            Start-Sleep -Seconds 3
            
            # Verify port 80 is now listening
            $port80Check = netstat -ano | Select-String "LISTENING" | Select-String ":80 "
            if ($port80Check) {
                Write-GuiLog "nginx successfully started and listening on port 80" "SUCCESS"
                [System.Windows.Forms.MessageBox]::Show(
                    "nginx has been restarted successfully!`n`nPort 80 is now listening.",
                    "nginx Restarted",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            } else {
                Write-GuiLog "WARNING: nginx started but not listening on port 80" "ERROR"
                [System.Windows.Forms.MessageBox]::Show(
                    "WARNING: nginx started but is not listening on port 80!`n`nPlease check the configuration.`n`nRun diagnosis: .\scripts\diagnose.ps1",
                    "nginx Warning",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                )
            }
        } catch {
            Write-GuiLog "Error restarting nginx: $($_.Exception.Message)" "ERROR"
            [System.Windows.Forms.MessageBox]::Show(
                "Failed to restart nginx:`n`n$($_.Exception.Message)`n`nPlease manually restart using: .\scripts\restart-admin.ps1",
                "Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    } else {
        Write-GuiLog "nginx is running and listening on port 80 - OK" "SUCCESS"
    }
} else {
    Write-GuiLog "No nginx processes found - starting nginx..." "WARN"
    
    try {
        $managerScript = Join-Path $scriptPath "nginx-manager.ps1"
        & $managerScript -Action start 2>&1 | Out-Null
        Start-Sleep -Seconds 3
        
        # Verify it started and is listening
        $port80Check = netstat -ano | Select-String "LISTENING" | Select-String ":80 "
        if ($port80Check) {
            Write-GuiLog "nginx started successfully and listening on port 80" "SUCCESS"
        } else {
            Write-GuiLog "WARNING: nginx started but not listening on port 80" "ERROR"
            [System.Windows.Forms.MessageBox]::Show(
                "nginx started but is not listening on port 80!`n`nPlease check the configuration.`n`nRun diagnosis: .\scripts\diagnose.ps1",
                "nginx Warning",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
        }
    } catch {
        Write-GuiLog "Error starting nginx: $($_.Exception.Message)" "ERROR"
    }
}

try {
    Load-ProxyList
    Load-SslList
} catch {
    Write-GuiLog "Error during initialization: $($_.Exception.Message)" "ERROR"
}

# Show form
Write-GuiLog "Displaying main form"
$form.ShowDialog() | Out-Null
Write-GuiLog "=== GUI Closed ==="
