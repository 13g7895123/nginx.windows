# nginx GUI 使用指南

## 🚀 快速啟動

### 方式 1：雙擊啟動（推薦）
直接執行 `scripts\nginx-gui.ps1`，如果沒有管理員權限，GUI 會自動提示你是否要以管理員身份重新啟動。

### 方式 2：以管理員身份啟動
```powershell
.\scripts\launch-gui-admin.ps1
```

### 方式 3：命令行啟動
```powershell
# 普通啟動（會提示需要管理員）
.\scripts\nginx-gui.ps1

# 或從任何位置以管理員身份啟動
Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File 'C:\Jarvis\22_nginx\scripts\nginx-gui.ps1'" -Verb RunAs
```

## ✨ 啟動時自動檢查

GUI 啟動時會自動執行以下檢查：

### 1. 管理員權限檢查
- ❌ **如果沒有管理員權限**：彈出對話框詢問是否要以管理員身份重新啟動
- ✅ **如果有管理員權限**：繼續執行 nginx 狀態檢查

### 2. nginx 進程檢查
GUI 會檢查現有的 nginx 進程：

#### 情況 A：nginx 正在運行但未監聽 port 80
```
發現問題 → 強制終止所有 nginx 進程 → 重新啟動 → 驗證 port 80 監聽
```
✅ 成功：顯示「nginx has been restarted successfully」
❌ 失敗：顯示警告並建議運行診斷腳本

#### 情況 B：nginx 正在運行且正常監聽 port 80
```
✅ 跳過清理，直接進入 GUI
```

#### 情況 C：沒有 nginx 進程
```
自動啟動 nginx → 驗證 port 80 監聽
```
✅ 成功：正常進入 GUI
❌ 失敗：顯示警告並建議檢查配置

### 3. Port 80 監聽驗證
啟動後會確認：
```
netstat -ano | Select-String "LISTENING" | Select-String ":80 "
```

## 📊 啟動流程圖

```
啟動 nginx-gui.ps1
    ↓
檢查管理員權限
    ├─ NO → 提示重新啟動
    │        ├─ 用戶選擇 YES → 以管理員身份重啟
    │        └─ 用戶選擇 NO → 退出
    └─ YES ↓
    
檢查 nginx 進程
    ├─ 有進程 + 監聽 80 → 正常啟動 GUI ✅
    ├─ 有進程 + 未監聽 80 → 清理並重啟
    │                           ↓
    │                      驗證 port 80
    │                           ├─ OK → 顯示成功消息
    │                           └─ FAIL → 顯示警告
    └─ 無進程 → 啟動 nginx
                    ↓
               驗證 port 80
                    ├─ OK → 正常啟動
                    └─ FAIL → 顯示警告
                    
最後：載入代理列表和 SSL 列表
```

## 🔧 日誌記錄

所有啟動檢查都會記錄到 `logs\gui.log`：

```powershell
# 查看最近的日誌
Get-Content .\logs\gui.log -Tail 50

# 查看特定級別的日誌
Get-Content .\logs\gui.log | Select-String "ERROR|WARN"
```

日誌範例：
```
[2025-11-04 16:03:15] [INFO] === nginx GUI Started ===
[2025-11-04 16:03:15] [INFO] Running with Administrator privileges: True
[2025-11-04 16:03:15] [INFO] Checking for existing nginx processes...
[2025-11-04 16:03:15] [INFO] Found 2 existing nginx process(es)
[2025-11-04 16:03:15] [WARN] nginx is running but NOT listening on port 80 - cleaning up...
[2025-11-04 16:03:17] [SUCCESS] Old nginx processes terminated
[2025-11-04 16:03:17] [INFO] Starting nginx with correct configuration...
[2025-11-04 16:03:20] [SUCCESS] nginx successfully started and listening on port 80
```

## 🛠️ 故障排除

### 問題 1：GUI 提示需要管理員權限但不想重啟
**解決方案**：
1. 關閉當前 PowerShell
2. 右鍵點擊 PowerShell 圖標
3. 選擇「以系統管理員身分執行」
4. 執行 `cd C:\Jarvis\22_nginx; .\scripts\nginx-gui.ps1`

### 問題 2：GUI 啟動後顯示 port 80 未監聽
**解決方案**：
```powershell
# 運行診斷腳本
.\scripts\diagnose.ps1

# 或手動重啟
.\scripts\restart-admin.ps1
```

### 問題 3：無法終止舊的 nginx 進程
**解決方案**：
```powershell
# 以管理員身份執行
taskkill /F /IM nginx.exe
Start-Sleep -Seconds 2
.\scripts\nginx-manager.ps1 -Action start
```

### 問題 4：想跳過自動檢查直接啟動
**說明**：目前版本會強制執行啟動檢查以確保 nginx 正常運行。如果你確定 nginx 已正確配置，可以手動註釋掉 `nginx-gui.ps1` 中的檢查代碼（第 24-130 行）。

## 📝 測試工具

### 測試啟動邏輯
```powershell
.\scripts\test-gui-startup.ps1
```
這個腳本會模擬 GUI 的啟動檢查，但不會實際啟動 GUI。

### 診斷 nginx 狀態
```powershell
.\scripts\diagnose.ps1
```
全面診斷 nginx 配置、進程、端口監聽等狀態。

### 驗證 hosts 文件
```powershell
.\scripts\verify-hosts.ps1
```
檢查所有代理域名是否已添加到 hosts 文件。

## 🎯 最佳實踐

1. **始終以管理員身份運行 GUI**
   - 避免權限問題
   - 可以自動修改 hosts 文件
   - 可以正確管理 nginx 進程

2. **讓 GUI 自動處理 nginx 狀態**
   - GUI 會自動檢測並修復常見問題
   - 不需要手動干預

3. **查看日誌了解詳情**
   - 所有操作都會記錄到 `logs\gui.log`
   - 出現問題時先查看日誌

4. **定期運行診斷**
   - 使用 `diagnose.ps1` 檢查系統狀態
   - 使用 `verify-hosts.ps1` 驗證 hosts 文件

## 🔐 安全提示

- GUI 需要管理員權限是因為：
  1. 修改 hosts 文件（系統文件）
  2. 管理 nginx 進程（可能需要終止其他用戶的進程）
  3. 綁定到 port 80（特權端口）

- 始終從可信來源運行腳本
- 定期檢查 `logs\gui.log` 以確保沒有異常操作
