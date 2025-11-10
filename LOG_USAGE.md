# GUI Logging Feature Guide

## Overview
The nginx GUI Management Console includes comprehensive logging functionality that automatically tracks all user operations and errors.

## Log Files

### 1. GUI Log (`logs/gui.log`)
- **Purpose**: Records all GUI operations, button clicks, and errors
- **Location**: `logs/gui.log`
- **Auto-created**: Yes, directory and file are created automatically on first run
- **Format**: `[YYYY-MM-DD HH:mm:ss] [LEVEL] Message`

### 2. nginx Access Log (`logs/access.log`)
- **Purpose**: Records all HTTP requests processed by nginx
- **Location**: `logs/access.log`
- **Managed by**: nginx

### 3. nginx Error Log (`logs/error.log`)
- **Purpose**: Records nginx errors and warnings
- **Location**: `logs/error.log`
- **Managed by**: nginx

## Log Levels

The GUI log uses the following log levels:

- **INFO**: Normal operations (button clicks, successful actions)
- **SUCCESS**: Successful completion of operations
- **WARN**: Warnings (missing files, non-critical issues)
- **ERROR**: Errors that occurred during operations

## What Gets Logged

### GUI Operations
Every button click and operation is logged with timestamp:

```
[2025-11-04 14:32:19] [INFO] === Start Button Clicked ===
[2025-11-04 14:32:19] [INFO] Executing: nginx-manager.ps1 -Action start
[2025-11-04 14:32:20] [SUCCESS] nginx started successfully
```

### Error Tracking
When errors occur, detailed error messages are logged:

```
[2025-11-04 14:35:10] [ERROR] Failed to start nginx: The nginx process is already running
[2025-11-04 14:36:22] [ERROR] Config file not found: C:\Jarvis\22_nginx\conf.d\test.conf
```

### Proxy Management
All proxy additions, edits, and deletions are tracked:

```
[2025-11-04 14:40:15] [INFO] === Add Proxy Button Clicked ===
[2025-11-04 14:40:25] [INFO] Adding proxy: Domain=myapp.local, Target=http://localhost:3000, Type=http, AddHosts=True
[2025-11-04 14:40:26] [INFO] Executing: add-proxy.ps1 -Domain myapp.local -TargetUrl http://localhost:3000 -Type http -AddToHosts
[2025-11-04 14:40:27] [SUCCESS] Proxy added successfully: myapp.local -> http://localhost:3000
```

### SSL Certificate Generation
Certificate operations are fully logged:

```
[2025-11-04 14:45:30] [INFO] === Generate Cert Button Clicked ===
[2025-11-04 14:45:40] [INFO] Generating SSL certificate: Domain=myapp.local, Days=365
[2025-11-04 14:45:41] [INFO] Executing: generate-ssl.ps1 -Domain myapp.local -Days 365
[2025-11-04 14:45:42] [SUCCESS] SSL certificate generated successfully: myapp.local
```

## Viewing Logs in GUI

1. Open the GUI
2. Click on the **"Logs"** tab
3. Select log type from dropdown:
   - `gui.log` - GUI operations and errors
   - `access.log` - nginx access logs
   - `error.log` - nginx error logs
4. Click **"Load Log"** to view
5. Click **"Clear Log"** to delete log content (after confirmation)

## Manual Log Access

### View Latest GUI Log Entries
```powershell
Get-Content .\logs\gui.log -Tail 50
```

### View All GUI Logs
```powershell
Get-Content .\logs\gui.log
```

### Search for Errors
```powershell
Select-String -Path .\logs\gui.log -Pattern "\[ERROR\]"
```

### Filter by Date
```powershell
Select-String -Path .\logs\gui.log -Pattern "2025-11-04"
```

## Troubleshooting with Logs

### Problem: GUI doesn't start
**Solution**: Check the last entries in `gui.log`:
```powershell
Get-Content .\logs\gui.log -Tail 20
```

### Problem: Proxy not working
**Solution**: 
1. Check `gui.log` for proxy addition errors
2. Check `error.log` for nginx configuration errors
3. Run Test Config button and check output

### Problem: nginx won't start
**Solution**:
1. Click "Test Config" button in GUI
2. Check `error.log`:
```powershell
Get-Content .\logs\error.log -Tail 30
```

### Problem: Hosts file not updated
**Solution**: Look for permission errors in `gui.log`:
```powershell
Select-String -Path .\logs\gui.log -Pattern "hosts|admin|permission" -Context 2,2
```

## Log File Management

### Rotate Logs Manually
```powershell
# Backup current log
Copy-Item .\logs\gui.log .\logs\gui.log.backup

# Clear log
Clear-Content .\logs\gui.log
```

### Archive Old Logs
```powershell
# Create archive with date
$date = Get-Date -Format "yyyyMMdd"
Compress-Archive -Path .\logs\*.log -DestinationPath ".\logs\archive-$date.zip"
```

### Clear All Logs
```powershell
Remove-Item .\logs\*.log
```

## Best Practices

1. **Check logs after errors**: Always review `gui.log` when operations fail
2. **Monitor disk space**: Log files can grow large; rotate or archive periodically
3. **Use log search**: Utilize PowerShell's `Select-String` for efficient log analysis
4. **Keep recent logs**: Maintain at least the last 7 days for troubleshooting
5. **Archive before major changes**: Backup logs before significant configuration changes

## Log Retention Recommendations

- **gui.log**: Keep 30 days (or rotate weekly)
- **access.log**: Keep 14 days (can grow large with high traffic)
- **error.log**: Keep 30 days (typically smaller)

## Automatic Error Handling

The GUI is designed to:
1. **Auto-create** log directory if missing
2. **Auto-create** gui.log file on first write
3. **Continue operation** even if log write fails
4. **Display error messages** in GUI for immediate feedback
5. **Log all errors** to file for later analysis

## Example Log Output

### Successful Proxy Addition
```
[2025-11-04 15:10:00] [INFO] === Add Proxy Button Clicked ===
[2025-11-04 15:10:10] [INFO] Adding proxy: Domain=api.local, Target=http://localhost:8080, Type=http, AddHosts=True
[2025-11-04 15:10:11] [INFO] Executing: add-proxy.ps1 -Domain api.local -TargetUrl http://localhost:8080 -Type http -AddToHosts
[2025-11-04 15:10:12] [SUCCESS] Proxy added successfully: api.local -> http://localhost:8080
[2025-11-04 15:10:12] [INFO] Loading proxy list
[2025-11-04 15:10:12] [INFO] Found 1 proxy configurations
[2025-11-04 15:10:12] [INFO] Loaded proxy: api.local.conf - api.local -> http://localhost:8080
```

### Error Example
```
[2025-11-04 15:15:00] [INFO] === Start Button Clicked ===
[2025-11-04 15:15:01] [INFO] Executing: nginx-manager.ps1 -Action start
[2025-11-04 15:15:02] [ERROR] Failed to start nginx: Configuration test failed
[2025-11-04 15:15:02] [INFO] === Test Config Button Clicked ===
[2025-11-04 15:15:03] [ERROR] Configuration test failed: [error] invalid number of arguments in "server_name" directive
```

## Support

If you encounter issues not covered in the logs:
1. Enable verbose logging (if available)
2. Reproduce the issue
3. Export the log file
4. Review error messages in context

For more information, see:
- README.md - General project documentation
- QUICKSTART.md - Quick reference guide
- conf/*.conf.template - Configuration templates
