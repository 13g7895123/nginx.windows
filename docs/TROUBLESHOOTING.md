# 🚨 如何修復 nginx 無法代理的問題

## 問題診斷結果

已發現兩個關鍵問題並修復：

### 1. ✅ nginx.conf Include 路徑錯誤（已修復）
- **問題**：`include ../../conf.d/*.conf;` 路徑錯誤
- **修復**：已改為 `include ../conf.d/*.conf;`
- **影響**：nginx 無法加載反向代理配置，導致不監聽 port 80

### 2. ✅ 配置文件編碼問題（已修復）
- **問題**：生成的 `.conf` 文件包含 UTF-8 BOM
- **修復**：已修復 `add-proxy.ps1` 和 `cm.re.conf`
- **影響**：nginx 無法解析配置文件

## 🔧 立即修復步驟

### 方法 1：使用自動腳本（推薦）

1. 運行重啟腳本（會自動請求管理員權限）：
   ```powershell
   .\scripts\restart-admin.ps1
   ```

2. 在彈出的管理員視窗中，等待重啟完成

3. 查看視窗顯示 "SUCCESS: nginx is now listening on port 80!"

### 方法 2：手動重啟（如果自動腳本失敗）

1. 以**管理員身份**打開 PowerShell：
   - 右鍵點擊開始按鈕
   - 選擇 "Windows PowerShell (管理員)" 或 "終端機 (管理員)"

2. 切換到項目目錄：
   ```powershell
   cd C:\Jarvis\22_nginx
   ```

3. 強制停止所有 nginx 進程：
   ```powershell
   taskkill /F /IM nginx.exe
   ```

4. 等待 2 秒：
   ```powershell
   Start-Sleep -Seconds 2
   ```

5. 啟動 nginx：
   ```powershell
   .\scripts\nginx-manager.ps1 -Action start
   ```

6. 等待 2 秒後驗證：
   ```powershell
   Start-Sleep -Seconds 2
   netstat -ano | Select-String "LISTENING" | Select-String ":80 "
   ```

   **應該看到類似這樣的輸出**：
   ```
   TCP    0.0.0.0:80             0.0.0.0:0              LISTENING       12345
   TCP    [::]:80                [::]:0                 LISTENING       12345
   ```

## ✅ 驗證修復

### 1. 檢查 nginx 是否監聽 port 80
```powershell
.\scripts\diagnose.ps1
```

應該看到：
```
[2] Checking port 80...
  Port 80 is LISTENING:
    TCP    0.0.0.0:80   ...
```

### 2. 測試訪問代理
```powershell
curl.exe http://cm.re -I
```

**成功的輸出應該是**：
```
HTTP/1.1 200 OK
Server: nginx/1.29.3
...
```

**如果失敗會看到**：
```
curl: (7) Failed to connect to cm.re port 80...
```

### 3. 在瀏覽器測試
打開瀏覽器訪問：
```
http://cm.re
```

應該能看到 `localhost:9101` 的網站內容。

## 🔍 如果還是不行

### 檢查 1：確認配置文件路徑
```powershell
Get-Content .\conf\nginx.conf | Select-String "include.*conf.d"
```

**應該顯示**：
```
    include ../conf.d/*.conf;
```

**如果顯示** `../../conf.d/*.conf` 則需要手動修復：
```powershell
(Get-Content .\conf\nginx.conf) -replace '../../conf.d/\*\.conf', '../conf.d/*.conf' | Set-Content .\conf\nginx.conf
```

### 檢查 2：確認 hosts 文件
```powershell
.\scripts\verify-hosts.ps1
```

應該看到：
```
[OK] cm.re
```

如果顯示 `[MISSING]`，運行：
```powershell
.\scripts\update-hosts.ps1
```

### 檢查 3：Port 80 是否被占用

查看是否有其他程序占用 port 80：
```powershell
netstat -ano | Select-String ":80 " | Select-String "LISTENING"
```

如果看到 port 80 被其他程序占用（比如 IIS、Apache），需要：
- 停止那個程序，或
- 修改 `conf.d\cm.re.conf`，將 `listen 80;` 改為 `listen 8080;`

### 檢查 4：查看錯誤日誌
```powershell
Get-Content .\logs\error.log -Tail 20
```

## 📝 完整的命令序列（管理員 PowerShell）

如果你想一次性執行所有步驟：

```powershell
# 切換到項目目錄
cd C:\Jarvis\22_nginx

# 停止 nginx
taskkill /F /IM nginx.exe 2>$null
Start-Sleep -Seconds 2

# 啟動 nginx
.\scripts\nginx-manager.ps1 -Action start
Start-Sleep -Seconds 2

# 檢查狀態
Write-Host "`n=== nginx Status ===" -ForegroundColor Cyan
.\scripts\nginx-manager.ps1 -Action status

Write-Host "`n=== Port 80 Listening ===" -ForegroundColor Cyan
netstat -ano | Select-String "LISTENING" | Select-String ":80 "

Write-Host "`n=== Test Access ===" -ForegroundColor Cyan
curl.exe http://cm.re -I

Write-Host "`n=== Full Diagnosis ===" -ForegroundColor Cyan
.\scripts\diagnose.ps1
```

## ✨ 成功標誌

當看到以下內容時，代表一切正常：

1. ✅ nginx 進程正在運行
2. ✅ Port 80 顯示 LISTENING
3. ✅ curl 返回 HTTP/1.1 200 或其他非連接錯誤的狀態碼
4. ✅ 瀏覽器能訪問 http://cm.re

## 📞 如果問題持續存在

請提供以下信息：

1. `.\scripts\diagnose.ps1` 的完整輸出
2. `Get-Content .\logs\error.log -Tail 30` 的內容
3. `netstat -ano | Select-String ":80"` 的輸出
4. 是否能直接訪問 `http://localhost:9101`（應該可以）
