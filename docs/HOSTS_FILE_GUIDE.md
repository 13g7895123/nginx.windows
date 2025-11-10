# Hosts File Management Guide

## 問題說明

添加 nginx 反向代理配置後，必須修改 Windows hosts 文件才能讓域名解析到本地。但是修改 hosts 文件需要**管理員權限**。

## 快速檢查

查看哪些域名還沒有被添加到 hosts 文件：

```powershell
.\scripts\verify-hosts.ps1
```

輸出示例：
```
========================================
  Verify Hosts File Entries
========================================

Checking 3 domain(s):

  [OK] example.local
  [MISSING] test.local
  [MISSING] app.local

========================================
Results: 1 / 3 domains in hosts file
========================================

Missing domains:
  - test.local
  - app.local
```

## 自動更新（推薦）

使用此命令會自動掃描所有代理配置，並將缺失的域名添加到 hosts 文件：

```powershell
.\scripts\update-hosts.ps1
```

這個腳本會：
1. 自動彈出 UAC 提示請求管理員權限
2. 掃描所有 conf.d/*.conf 配置文件
3. 提取所有域名
4. 檢查哪些域名還沒在 hosts 文件中
5. 只添加缺失的域名（不會重複添加）
6. 自動備份 hosts 文件
7. 驗證每個域名是否成功添加
8. 自動刷新 DNS 緩存

輸出示例：
```
========================================
  SUCCESS: Hosts File Updated
========================================

Verifying entries...
  [OK] test.local
  [OK] app.local
  [OK] api.local

========================================
Added: 3 / 3 domain(s)
========================================

Flushing DNS cache...
DNS cache flushed successfully

You can now access these domains in your browser!
Press any key to exit...
```

## 添加代理時自動更新

在添加代理時使用 `-AddToHosts` 參數：

```powershell
.\scripts\add-proxy.ps1 -Domain myapp.local -TargetUrl http://localhost:3000 -Type http -AddToHosts
```

**注意：**
- 如果當前 PowerShell **沒有**管理員權限，會顯示紅色警告：
  ```
  ========================================
    ADMINISTRATOR PRIVILEGES REQUIRED
  ========================================
  
  Cannot modify hosts file without admin privileges!
  
  Please run this command as Administrator:
    .\scripts\update-hosts.ps1
  ```

- 如果當前 PowerShell **有**管理員權限，會自動添加並驗證：
  ```
  SUCCESS: Added to hosts file: 127.0.0.1 -> myapp.local
  Flushing DNS cache...
  DNS cache flushed
  ```

## 手動添加

如果你不想使用自動化腳本，可以手動編輯 hosts 文件：

1. 以管理員身份打開記事本：
   ```powershell
   notepad C:\Windows\System32\drivers\etc\hosts
   ```

2. 在文件末尾添加：
   ```
   127.0.0.1    your-domain.local    # Added by nginx-manager
   ```

3. 保存文件

4. 刷新 DNS 緩存：
   ```powershell
   ipconfig /flushdns
   ```

## GUI 操作

在 GUI 中添加代理時：
1. "Auto add to Windows hosts file (requires admin)" 選項默認勾選
2. 如果 GUI **不是**以管理員身份運行，會在日誌中顯示錯誤
3. 建議：添加代理後，以管理員身份運行 `.\scripts\update-hosts.ps1`

## 常見問題

### Q: 為什麼需要管理員權限？
A: Windows hosts 文件 (`C:\Windows\System32\drivers\etc\hosts`) 是系統文件，需要管理員權限才能修改。

### Q: 如何以管理員身份運行 PowerShell？
A: 
1. 右鍵點擊開始按鈕
2. 選擇 "Windows PowerShell (管理員)" 或 "終端機 (管理員)"
3. 在 UAC 提示中點擊"是"

### Q: update-hosts.ps1 會重複添加域名嗎？
A: 不會。腳本會自動檢查域名是否已存在，只添加缺失的條目。

### Q: 如何刪除 hosts 文件中的條目？
A: 可以手動編輯 hosts 文件，刪除包含 `# Added by nginx-manager` 註釋的行。

### Q: 修改 hosts 文件後多久生效？
A: 立即生效。腳本會自動執行 `ipconfig /flushdns` 刷新 DNS 緩存，確保變更立即生效。

## 驗證是否生效

1. 運行驗證腳本：
   ```powershell
   .\scripts\verify-hosts.ps1
   ```

2. 使用 ping 測試：
   ```powershell
   ping your-domain.local
   ```
   應該看到 `127.0.0.1` 的回應

3. 在瀏覽器訪問：
   ```
   http://your-domain.local
   ```

## 腳本文件說明

| 腳本 | 用途 | 需要管理員 |
|------|------|-----------|
| `add-proxy.ps1` | 添加代理配置，可選添加 hosts | 使用 `-AddToHosts` 時需要 |
| `update-hosts.ps1` | 啟動器，會自動請求管理員權限 | 自動提權 |
| `update-hosts-admin.ps1` | 實際執行 hosts 更新的腳本 | 必須 |
| `verify-hosts.ps1` | 檢查哪些域名在 hosts 文件中 | 不需要 |

## 備份與恢復

`update-hosts-admin.ps1` 會自動創建備份：
```
C:\Windows\System32\drivers\etc\hosts.backup.20251104_153045
```

如果需要恢復：
```powershell
Copy-Item "C:\Windows\System32\drivers\etc\hosts.backup.20251104_153045" "C:\Windows\System32\drivers\etc\hosts" -Force
```

## 最佳實踐

1. **推薦流程**：
   - 先添加代理：`.\scripts\add-proxy.ps1 -Domain app.local -TargetUrl http://localhost:3000 -Type http`
   - 然後統一更新 hosts：`.\scripts\update-hosts.ps1`

2. **批量添加**：
   如果要添加多個代理，可以全部添加完後，只運行一次 `update-hosts.ps1`

3. **定期驗證**：
   定期運行 `verify-hosts.ps1` 確保所有配置都正確

4. **GUI 使用**：
   如果經常使用 GUI，建議以管理員身份啟動 PowerShell，然後運行 GUI：
   ```powershell
   .\scripts\nginx-gui.ps1
   ```
