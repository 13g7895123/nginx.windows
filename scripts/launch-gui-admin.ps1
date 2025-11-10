# Launch nginx GUI as Administrator
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$guiScript = Join-Path $scriptPath "nginx-gui.ps1"

Write-Host "Launching nginx GUI with Administrator privileges..." -ForegroundColor Cyan
Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$guiScript`"" -Verb RunAs
