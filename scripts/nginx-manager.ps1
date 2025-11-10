param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "restart", "reload", "status", "test")]
    [string]$Action
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$nginxPath = Join-Path $projectRoot "nginx"
$nginxExe = Join-Path $nginxPath "nginx.exe"
$nginxConf = Join-Path $projectRoot "conf\nginx.conf"

function Test-NginxRunning {
    $processes = Get-Process -Name "nginx" -ErrorAction SilentlyContinue
    return ($processes.Count -gt 0)
}

function Test-NginxConfig {
    Push-Location $nginxPath
    try {
        $result = & $nginxExe -t -c $nginxConf 2>&1
        $output = $result | Out-String
        Write-Host $output
        return ($LASTEXITCODE -eq 0)
    } finally {
        Pop-Location
    }
}

function Start-Nginx {
    if (Test-NginxRunning) {
        Write-Host "nginx is already running" -ForegroundColor Yellow
        return
    }
    
    Push-Location $nginxPath
    try {
        Start-Process -FilePath $nginxExe -ArgumentList "-c", $nginxConf -WindowStyle Hidden
        Start-Sleep -Seconds 2
        
        if (Test-NginxRunning) {
            Write-Host "nginx started successfully" -ForegroundColor Green
        } else {
            Write-Host "Failed to start nginx" -ForegroundColor Red
            exit 1
        }
    } finally {
        Pop-Location
    }
}

function Stop-Nginx {
    if (-not (Test-NginxRunning)) {
        Write-Host "nginx is not running" -ForegroundColor Yellow
        return
    }
    
    Push-Location $nginxPath
    try {
        & $nginxExe -s stop
        Start-Sleep -Seconds 2
        
        if (-not (Test-NginxRunning)) {
            Write-Host "nginx stopped successfully" -ForegroundColor Green
        } else {
            Write-Host "Failed to stop nginx gracefully, forcing shutdown..." -ForegroundColor Yellow
            Get-Process -Name "nginx" -ErrorAction SilentlyContinue | Stop-Process -Force
            Write-Host "nginx stopped forcefully" -ForegroundColor Green
        }
    } finally {
        Pop-Location
    }
}

function Restart-Nginx {
    Write-Host "Restarting nginx..." -ForegroundColor Cyan
    Stop-Nginx
    Start-Sleep -Seconds 1
    Start-Nginx
}

function Reload-Nginx {
    if (-not (Test-NginxRunning)) {
        Write-Host "nginx is not running, starting instead..." -ForegroundColor Yellow
        Start-Nginx
        return
    }
    
    Push-Location $nginxPath
    try {
        & $nginxExe -s reload
        Write-Host "nginx configuration reloaded successfully" -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

function Get-NginxStatus {
    if (Test-NginxRunning) {
        $processes = Get-Process -Name "nginx" -ErrorAction SilentlyContinue
        Write-Host "nginx is running" -ForegroundColor Green
        Write-Host "Process count: $($processes.Count)" -ForegroundColor Cyan
        $processes | Format-Table Id, ProcessName, CPU, WorkingSet -AutoSize
    } else {
        Write-Host "nginx is not running" -ForegroundColor Yellow
    }
}

switch ($Action) {
    "start" {
        Start-Nginx
    }
    
    "stop" {
        Stop-Nginx
    }
    
    "restart" {
        Restart-Nginx
    }
    
    "reload" {
        Reload-Nginx
    }
    
    "status" {
        Get-NginxStatus
    }
    
    "test" {
        if (Test-NginxConfig) {
            Write-Host "Configuration test passed" -ForegroundColor Green
        } else {
            Write-Host "Configuration test failed" -ForegroundColor Red
            exit 1
        }
    }
}
