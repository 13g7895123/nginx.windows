# Windows Nginx 反向代理管理工具

本專案提供完整的 Windows 環境下 nginx 反向代理解決方案，專為本地開發環境設計，包含快速配置、自簽憑證生成、hosts 文件自動管理等功能。

## 📋 目錄

- [功能特性](#功能特性)
- [環境需求](#環境需求)
- [快速開始](#快速開始)
- [GUI 圖形介面](#gui-圖形介面)
- [詳細使用說明](#詳細使用說明)
- [配置範例](#配置範例)
- [常見問題](#常見問題)
- [目錄結構](#目錄結構)

---

## ✨ 功能特性

- ✅ **自動化部署**：一鍵下載並配置最新穩定版 nginx
- ✅ **反向代理**：支援 HTTP、HTTPS、WebSocket、負載平衡
- ✅ **快速配置**：PowerShell 腳本快速添加/刪除/管理代理規則
- ✅ **自簽憑證**：自動生成開發用 SSL 憑證
- ✅ **配置模板**：提供多種場景的配置範本
- ✅ **GUI 介面**：Windows Forms 圖形化管理工具
- ✅ **自動診斷**：內建診斷工具快速排查問題
- ✅ **智能啟動**：GUI 自動檢查管理員權限、nginx 狀態、端口監聽
- ✅ **自動修復**：偵測並清理孤立的 nginx 進程
- ✅ **UTF-8 無 BOM**：自動處理配置檔案編碼問題
- ✅ **簡易管理**：啟動、停止、重載 nginx 只需一行命令

---

## 🔧 環境需求

- **作業系統**：Windows 7/8/10/11 或 Windows Server 2012 或更高版本
- **PowerShell**：5.1 或更高版本（Windows 10/11 預裝）
- **權限**：修改 hosts 文件需要管理員權限

### 確認 PowerShell 版本

```powershell
$PSVersionTable.PSVersion
```

---

## 🚀 快速開始

### 1. 驗證專案結構

專案已包含最新版 nginx (1.29.3) 和所有必要配置：

```
22_nginx/
├── nginx/          # nginx 執行檔（已下載）
├── conf/           # 主配置文件
├── conf.d/         # 模組化配置目錄
├── scripts/        # PowerShell 管理腳本
├── ssl/            # SSL 憑證目錄
└── logs/           # 日誌文件目錄
```

### 2. 啟動 nginx

```powershell
# 切換到專案目錄
cd c:\Jarvis\22_nginx

# 啟動 nginx
.\scripts\nginx-manager.ps1 -Action start
```

### 3. 添加第一個反向代理

#### 範例 1：簡單的 HTTP 反向代理

```powershell
# 將 myapp.local 代理到本地端口 3000
.\scripts\add-proxy.ps1 -Domain "myapp.local" -TargetUrl "http://localhost:3000" -AddToHosts
```

#### 範例 2：HTTPS 反向代理（自動生成憑證）

```powershell
# 將 secure.local 代理到本地端口 8080，並啟用 HTTPS
.\scripts\add-proxy.ps1 -Domain "secure.local" -TargetUrl "http://localhost:8080" -Type https -AddToHosts
```

### 4. 重新載入配置

```powershell
.\scripts\nginx-manager.ps1 -Action reload
```
### 5. 訪問服務

在瀏覽器中訪問：
- HTTP: `http://myapp.local`
- HTTPS: `https://secure.local`（首次訪問需接受自簽憑證警告）

---

## 🔧 重要配置修復（已完成）

**本專案已修復以下關鍵問題：**

### 1. nginx.conf 路徑修復
**問題**：nginx 無法載入 conf.d 目錄下的配置文件  
**原因**：`include` 路徑錯誤（`../../conf.d/*.conf`）  
**修復**：已更正為 `../conf.d/*.conf`  
**影響**：nginx 現在可以正確載入所有反向代理配置

### 2. UTF-8 BOM 編碼問題
**問題**：nginx 解析配置文件時出現 `unknown directive '嚜?'` 錯誤  
**原因**：配置文件包含 UTF-8 BOM 標記  
**修復**：所有腳本已更新為無 BOM 的 UTF-8 編碼  
**影響**：配置文件現在可以正常解析

### 3. 端口 80 監聽確認
**問題**：nginx 啟動但未監聽 80 端口  
**原因**：配置文件載入失敗導致默認配置未生效  
**驗證**：使用 `netstat -ano | Select-String ":80"` 確認監聽狀態  
**狀態**：✅ 已確認正常監聽

### 4. 管理員權限管理
**功能**：GUI 啟動時自動檢查管理員權限  
**行為**：如未以管理員身份運行，會提示使用 UAC 提升權限  
**原因**：修改 hosts 文件、管理 nginx 進程、綁定 80 端口需要管理員權限

**驗證方式：**
```powershell
# 檢查 nginx 配置
.\scripts\nginx-manager.ps1 -Action test

# 檢查端口 80 監聽
netstat -ano | Select-String ":80" | Select-String "LISTENING"

# 運行診斷工具
.\scripts\diagnose.ps1
```

---

## 🖥️ GUI 圖形介面

### 啟動 GUI 管理工具

```powershell
# 切換到專案目錄
cd c:\Jarvis\22_nginx

# 啟動 GUI
.\scripts\nginx-gui.ps1
```

### GUI 功能介紹

**智能啟動檢查**（自動執行）

GUI 啟動時會自動執行以下檢查：

1. **管理員權限檢查** 🔐
   - 檢測是否以管理員身份運行
   - 如果沒有，會彈出對話框詢問是否要以管理員身份重新啟動
   - 點擊「是」會觸發 UAC 提升權限並重新啟動 GUI

2. **nginx 進程檢查** 🔍
   - 檢測是否有 nginx 進程正在運行
   - 檢測 nginx 是否正確監聽 80 端口

3. **自動修復** 🔧
   - 如果發現 nginx 進程存在但未監聽 80 端口（孤立進程）
   - 自動強制終止所有 nginx 進程
   - 重新啟動 nginx 並驗證 80 端口監聽
   - 顯示結果訊息框

4. **自動啟動** 🚀
   - 如果沒有 nginx 進程運行
   - 自動啟動 nginx
   - 驗證 80 端口監聽
   - 如果啟動失敗會顯示警告

**主控制區**（頂部）
- 🟢/🔴 **nginx 狀態顯示**：即時顯示 nginx 運行狀態
- **啟動/停止/重載/重啟按鈕**：一鍵控制 nginx 服務
- **測試配置按鈕**：快速驗證配置文件
- **刷新按鈕**：更新狀態和列表

**Tab 頁面**

1. **代理管理** Tab
   - 📊 代理列表：以表格形式顯示所有反向代理配置
   - ➕ 添加代理：圖形化界面快速添加新代理
   - ✏️ 編輯配置：雙擊列表項或點擊編輯按鈕打開配置文件
   - 🗑️ 刪除代理：選擇並刪除代理，可選擇是否同時從 hosts 移除
   - 📁 打開配置目錄：快速訪問配置文件夾

2. **SSL 憑證** Tab
   - 📜 憑證列表：顯示所有已生成的 SSL 憑證及狀態
   - 🔐 生成憑證：圖形化界面生成自簽 SSL 憑證
   - 🔄 刷新列表：更新憑證列表
   - 📁 打開憑證目錄：快速訪問憑證文件夾

3. **日誌查看** Tab
   - 📋 日誌類型選擇：錯誤日誌 / 訪問日誌
   - 📖 載入日誌：查看最近 500 行日誌內容
   - 🗑️ 清空日誌：清除日誌文件內容
   - 📁 打開日誌目錄：快速訪問日誌文件夾

4. **關於** Tab
   - ℹ️ 專案信息、版本號、使用說明

**快捷鍵**
- `F5` - 刷新狀態和列表
- `Ctrl+R` - 重載 nginx 配置
- `Ctrl+T` - 測試配置文件

### GUI 使用範例

#### 範例 1：使用 GUI 添加代理

1. 啟動 GUI：`.\scripts\nginx-gui.ps1`
2. 點擊「啟動」按鈕啟動 nginx
3. 切換到「代理管理」Tab
4. 點擊「添加代理」按鈕
5. 填寫域名（如 `myapp.local`）和目標 URL（如 `http://localhost:3000`）
6. 選擇代理類型（http/https/websocket）
7. 勾選「自動添加到 Windows hosts 文件」
8. 點擊「確定」
9. 點擊「重載配置」按鈕使配置生效
10. 在瀏覽器訪問 `http://myapp.local`

#### 範例 2：使用 GUI 生成 SSL 憑證

1. 切換到「SSL 憑證」Tab
2. 點擊「生成憑證」按鈕
3. 輸入域名（如 `secure.local`）
4. 設置有效期（預設 365 天）
5. 點擊「生成」
6. 憑證生成完成後會自動顯示在列表中

#### 範例 3：使用 GUI 查看日誌

1. 切換到「日誌查看」Tab
2. 選擇日誌類型（錯誤日誌或訪問日誌）
3. 點擊「載入日誌」按鈕
4. 查看最近 500 行日誌內容

### GUI vs 命令列

| 功能 | GUI 方式 | 命令列方式 |
|------|---------|-----------|
| **易用性** | ⭐⭐⭐⭐⭐ 圖形界面，操作直觀 | ⭐⭐⭐ 需要記憶命令 |
| **速度** | ⭐⭐⭐ 需要點擊操作 | ⭐⭐⭐⭐⭐ 直接執行 |
| **批量操作** | ⭐⭐ 需要逐個操作 | ⭐⭐⭐⭐⭐ 可腳本化 |
| **視覺化** | ⭐⭐⭐⭐⭐ 清晰的狀態顯示 | ⭐⭐ 純文字輸出 |
| **適合對象** | 初學者、偶爾使用者 | 進階使用者、自動化需求 |

**建議：**
- 🆕 初次使用或學習階段 → 使用 **GUI**
- 🚀 日常開發和快速操作 → 使用**命令列**
- 🤖 自動化部署和 CI/CD → 使用**命令列腳本**

---

## 🩺 診斷工具

### 使用診斷腳本

如果遇到問題，首先運行診斷工具進行全面檢查：

```powershell
.\scripts\diagnose.ps1
```

**診斷工具會檢查：**

1. ✅ **nginx 進程狀態**
   - 檢查是否有 nginx.exe 進程運行
   - 顯示進程 PID 和數量

2. ✅ **端口 80 監聽狀態**
   - 使用 netstat 檢查 nginx 是否監聽 80 端口
   - 確認監聽地址（應為 0.0.0.0:80 或 [::]:80）

3. ✅ **nginx 配置測試**
   - 執行 `nginx -t` 測試配置文件語法
   - 顯示配置文件路徑和測試結果

4. ✅ **hosts 文件記錄**
   - 檢查 hosts 文件中所有已配置的域名
   - 確認是否正確指向 127.0.0.1

5. ✅ **代理目標可達性**
   - 測試每個配置的後端服務是否可連接
   - 使用 Test-NetConnection 檢查端口

6. ✅ **錯誤日誌分析**
   - 顯示最近 10 行錯誤日誌
   - 幫助快速定位問題

**診斷輸出範例：**

```
╔══════════════════════════════════════════════════════════╗
║              nginx 診斷報告              ║
╚══════════════════════════════════════════════════════════╝

[✓] nginx 進程: 2 個進程運行中
    PID: 27540, 35872

[✓] 端口 80 監聽: 正常
    TCP    0.0.0.0:80    0.0.0.0:0    LISTENING    35872

[✓] 配置測試: 通過
    nginx: configuration file test is successful

[✓] hosts 文件記錄:
    127.0.0.1 -> cm.re

[✓] 代理目標可達性:
    ✓ localhost:9101 可連接

[ℹ] 最近錯誤日誌: 無錯誤

╔══════════════════════════════════════════════════════════╗
║                    建議                    ║
╚══════════════════════════════════════════════════════════╝
系統運行正常，無需額外操作。
```

### 快速診斷命令

```powershell
# 檢查 nginx 進程
Get-Process -Name "nginx" -ErrorAction SilentlyContinue

# 檢查端口 80
netstat -ano | Select-String ":80" | Select-String "LISTENING"

# 測試配置
.\scripts\nginx-manager.ps1 -Action test

# 查看錯誤日誌
Get-Content .\logs\error.log -Tail 20

# 查看訪問日誌
Get-Content .\logs\access.log -Tail 20
```

### GUI 測試工具

測試 GUI 啟動邏輯而不實際啟動 GUI：

```powershell
.\scripts\test-gui-startup.ps1
```

**輸出範例：**
```
=== GUI 啟動檢查測試 ===

[1] 檢查管理員權限...
    狀態: [FAIL] 需要管理員權限

[2] 檢查現有 nginx 進程...
    狀態: [INFO] 找到 2 個 nginx 進程
    PID: 27540, 35872

[3] 檢查 80 端口監聽...
    狀態: [OK] nginx 正在監聽 80 端口
    TCP    0.0.0.0:80    LISTENING

=== 預測 GUI 行為 ===
→ 會提示以管理員身份重新啟動
→ nginx 運行正常，無需額外操作
```

### 快速啟動 GUI（管理員模式）

```powershell
# 直接以管理員身份啟動 GUI
.\scripts\launch-gui-admin.ps1
```

---

## 📖 詳細使用說明

### nginx 服務管理

使用 `nginx-manager.ps1` 管理 nginx 服務：

```powershell
# 啟動 nginx
.\scripts\nginx-manager.ps1 -Action start

# 停止 nginx
.\scripts\nginx-manager.ps1 -Action stop

# 重啟 nginx
.\scripts\nginx-manager.ps1 -Action restart

# 重新載入配置（不中斷服務）
.\scripts\nginx-manager.ps1 -Action reload

# 檢查 nginx 狀態
.\scripts\nginx-manager.ps1 -Action status

# 測試配置文件
.\scripts\nginx-manager.ps1 -Action test
```

### 添加反向代理

使用 `add-proxy.ps1` 快速添加新的反向代理配置：

#### 基本用法

```powershell
.\scripts\add-proxy.ps1 -Domain "<域名>" -TargetUrl "<目標URL>" [選項]
```

#### 參數說明

| 參數 | 說明 | 必填 | 預設值 |
|------|------|------|--------|
| `-Domain` | 代理域名（如 api.local） | ✅ | - |
| `-TargetUrl` | 後端服務 URL（如 http://localhost:3000） | ✅ | - |
| `-Type` | 代理類型：`http`、`https`、`websocket` | ❌ | `http` |
| `-AddToHosts` | 自動添加到 hosts 文件 | ❌ | `false` |
| `-EnableSSL` | 啟用 SSL（適用於 https 類型） | ❌ | `false` |

#### 使用範例

**HTTP 代理（最常用）**

```powershell
# 基本 HTTP 反向代理
.\scripts\add-proxy.ps1 -Domain "api.local" -TargetUrl "http://localhost:5000" -AddToHosts
```

**HTTPS 代理（自動生成憑證）**

```powershell
# HTTPS 反向代理，自動生成自簽憑證
.\scripts\add-proxy.ps1 -Domain "secure.local" -TargetUrl "http://localhost:5000" -Type https -AddToHosts
```

**WebSocket 代理**

```powershell
# WebSocket 反向代理（適用於 Socket.io、SignalR 等）
.\scripts\add-proxy.ps1 -Domain "ws.local" -TargetUrl "http://localhost:3001" -Type websocket -AddToHosts
```

**多個域名指向同一服務**

```powershell
# 開發環境
.\scripts\add-proxy.ps1 -Domain "dev.myapp.local" -TargetUrl "http://localhost:3000" -AddToHosts

# 測試環境
.\scripts\add-proxy.ps1 -Domain "test.myapp.local" -TargetUrl "http://localhost:3001" -AddToHosts
```

### 移除反向代理

使用 `remove-proxy.ps1` 移除代理配置：

```powershell
# 移除配置文件
.\scripts\remove-proxy.ps1 -Domain "api.local"

# 同時從 hosts 文件中移除
.\scripts\remove-proxy.ps1 -Domain "api.local" -RemoveFromHosts

# 強制刪除（不確認）
.\scripts\remove-proxy.ps1 -Domain "api.local" -RemoveFromHosts -Force
```

### 查看所有代理

使用 `list-proxy.ps1` 查看當前所有反向代理配置：

```powershell
# 簡單列表
.\scripts\list-proxy.ps1

# 詳細信息（包含日誌路徑等）
.\scripts\list-proxy.ps1 -Detailed
```

**輸出範例：**

```
======================================================================
當前反向代理配置列表
======================================================================

配置文件: api.local.conf
  類型: HTTP
  域名: api.local
  端口: 80
  目標: http://localhost:5000

配置文件: secure.local.conf
  類型: HTTPS
  域名: secure.local
  端口: 443, 80
  目標: http://localhost:8080

======================================================================
總計: 2 個配置
======================================================================

Hosts 文件中的相關記錄:
  127.0.0.1 -> api.local
  127.0.0.1 -> secure.local
```

### 生成 SSL 憑證

使用 `generate-ssl.ps1` 為指定域名生成自簽憑證：

```powershell
# 基本用法
.\scripts\generate-ssl.ps1 -Domain "example.local"

# 自定義有效期（預設 365 天）
.\scripts\generate-ssl.ps1 -Domain "example.local" -Days 730

# 自定義憑證信息
.\scripts\generate-ssl.ps1 -Domain "example.local" `
    -Country "TW" `
    -State "Taiwan" `
    -City "Taipei" `
    -Organization "My Company" `
    -OrganizationalUnit "Development"
```

**憑證文件位置：**
- 證書：`ssl\<domain>.crt`
- 私鑰：`ssl\<domain>.key`

---

## 📝 配置範例

### 範例 1：前端開發環境

```powershell
# React 開發服務器
.\scripts\add-proxy.ps1 -Domain "react.local" -TargetUrl "http://localhost:3000" -AddToHosts

# Vue 開發服務器
.\scripts\add-proxy.ps1 -Domain "vue.local" -TargetUrl "http://localhost:8080" -AddToHosts

# API 後端
.\scripts\add-proxy.ps1 -Domain "api.local" -TargetUrl "http://localhost:5000" -AddToHosts

# 重載配置
.\scripts\nginx-manager.ps1 -Action reload
```

訪問：
- `http://react.local`
- `http://vue.local`
- `http://api.local`

### 範例 2：全棧應用（帶 HTTPS）

```powershell
# 前端（HTTPS）
.\scripts\add-proxy.ps1 -Domain "app.local" -TargetUrl "http://localhost:3000" -Type https -AddToHosts

# API（HTTPS）
.\scripts\add-proxy.ps1 -Domain "api.app.local" -TargetUrl "http://localhost:5000" -Type https -AddToHosts

# WebSocket（HTTPS）
.\scripts\add-proxy.ps1 -Domain "ws.app.local" -TargetUrl "http://localhost:3001" -Type websocket -AddToHosts

# 重載配置
.\scripts\nginx-manager.ps1 -Action reload
```

訪問：
- `https://app.local`
- `https://api.app.local`
- `wss://ws.app.local`

### 範例 3：微服務架構

```powershell
# 用戶服務
.\scripts\add-proxy.ps1 -Domain "user.local" -TargetUrl "http://localhost:3001" -AddToHosts

# 訂單服務
.\scripts\add-proxy.ps1 -Domain "order.local" -TargetUrl "http://localhost:3002" -AddToHosts

# 產品服務
.\scripts\add-proxy.ps1 -Domain "product.local" -TargetUrl "http://localhost:3003" -AddToHosts

# API 網關
.\scripts\add-proxy.ps1 -Domain "gateway.local" -TargetUrl "http://localhost:8080" -AddToHosts

# 重載配置
.\scripts\nginx-manager.ps1 -Action reload
```

---

## 🔧 手動配置（進階）

### 使用配置範本

專案提供以下配置範本（位於 `conf.d/` 目錄）：

1. **`example-http.conf.template`** - HTTP 反向代理
2. **`example-https.conf.template`** - HTTPS 反向代理
3. **`example-websocket.conf.template`** - WebSocket 反向代理
4. **`example-loadbalance.conf.template`** - 負載平衡

#### 使用步驟：

1. 複製範本文件並重命名（移除 `.template` 後綴）：

```powershell
Copy-Item conf.d\example-http.conf.template conf.d\myapp.local.conf
```

2. 編輯配置文件：

```nginx
server {
    listen       80;
    server_name  myapp.local;  # 修改為你的域名

    location / {
        proxy_pass http://localhost:3000;  # 修改為你的後端地址
    }
}
```

3. 手動添加 hosts 記錄（需要管理員權限）：

```powershell
# 編輯 hosts 文件
notepad C:\Windows\System32\drivers\etc\hosts

# 添加以下行：
127.0.0.1    myapp.local
```

4. 測試並重載：

```powershell
.\scripts\nginx-manager.ps1 -Action test
.\scripts\nginx-manager.ps1 -Action reload
```

### 負載平衡配置

編輯 `conf.d/loadbalance.conf`：

```nginx
upstream backend_servers {
    # 負載平衡策略
    least_conn;  # 最少連接數優先
    
    server localhost:3000 weight=3;
    server localhost:3001 weight=2;
    server localhost:3002 weight=1;
    server localhost:3003 backup;  # 備援服務器
}

server {
    listen       80;
    server_name  lb.local;

    location / {
        proxy_pass http://backend_servers;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
    }
}
```

---

## ❓ 常見問題

### 1. nginx 啟動失敗

**可能原因：**
- 端口被佔用（80 或 443）
- 配置文件語法錯誤

**解決方法：**

```powershell
# 檢查端口佔用
netstat -ano | findstr ":80"
netstat -ano | findstr ":443"

# 測試配置文件
.\scripts\nginx-manager.ps1 -Action test

# 查看錯誤日誌
Get-Content logs\error.log -Tail 20
```

### 2. 無法訪問代理域名

**檢查清單：**

1. 確認 nginx 正在運行：

```powershell
.\scripts\nginx-manager.ps1 -Action status
```

2. 確認 hosts 文件已添加記錄：

```powershell
Select-String -Path "C:\Windows\System32\drivers\etc\hosts" -Pattern "127.0.0.1"
```

3. 確認後端服務正在運行：

```powershell
# 檢查後端端口
netstat -ano | findstr ":<端口號>"
```

4. 清除瀏覽器 DNS 緩存：

```powershell
# Chrome
chrome://net-internals/#dns

# 清除 Windows DNS 緩存
ipconfig /flushdns
```

### 3. HTTPS 憑證警告

**說明：**
自簽憑證會在瀏覽器中顯示安全警告，這是正常現象。

**解決方法：**

- **Chrome**：點擊「進階」→「繼續前往 xxx.local（不安全）」
- **Firefox**：點擊「進階」→「接受風險並繼續」
- **Edge**：點擊「進階」→「繼續前往 xxx.local（不安全）」

### 4. 修改 hosts 文件需要管理員權限

**錯誤訊息：**
```
警告: 需要管理員權限才能修改 hosts 文件
```

**解決方法：**

以管理員身份運行 PowerShell：

```powershell
# 右鍵點擊 PowerShell → "以系統管理員身分執行"
# 或在 PowerShell 中執行：
Start-Process powershell -Verb RunAs
```

### 5. WebSocket 連接失敗

**確認配置：**

```nginx
location / {
    proxy_pass http://localhost:3001;
    
    # 必要的 WebSocket 配置
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    
    # 增加超時時間
    proxy_read_timeout 86400;
}
```

### 6. 配置修改後未生效

**解決方法：**

```powershell
# 測試配置
.\scripts\nginx-manager.ps1 -Action test

# 重新載入配置（推薦，不中斷服務）
.\scripts\nginx-manager.ps1 -Action reload

# 或完全重啟（會中斷服務）
.\scripts\nginx-manager.ps1 -Action restart
```

### 7. nginx 進程存在但不工作（孤立進程）

**症狀：**
- `Get-Process nginx` 顯示有進程
- `netstat -ano | Select-String ":80"` 沒有監聽
- 無法訪問代理域名

**原因：**
之前的 nginx 實例啟動失敗但進程殘留

**解決方法：**

```powershell
# 方法 1: 使用管理員重啟腳本（推薦）
.\scripts\restart-admin.ps1

# 方法 2: 手動清理
taskkill /F /IM nginx.exe
Start-Sleep -Seconds 2
.\scripts\nginx-manager.ps1 -Action start

# 驗證端口監聽
netstat -ano | Select-String ":80"
```

### 8. UTF-8 BOM 配置錯誤

**錯誤訊息：**
```
unknown directive '嚜?'
```

**原因：**
配置文件包含 UTF-8 BOM（Byte Order Mark）

**解決方法：**

本專案的所有腳本已更新為無 BOM 模式。如果手動編輯配置文件，請確保：

```powershell
# 使用 PowerShell 重新保存文件（無 BOM）
$content = Get-Content .\conf.d\yourfile.conf -Raw
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText(".\conf.d\yourfile.conf", $content, $utf8NoBom)

# 或使用 VSCode
# 1. 開啟文件
# 2. 點擊右下角編碼選擇
# 3. 選擇 "Save with Encoding"
# 4. 選擇 "UTF-8"
```

### 9. GUI 啟動後立即關閉

**原因：**
可能是權限問題或腳本載入錯誤

**診斷方法：**

```powershell
# 查看 GUI 日誌
Get-Content .\logs\gui.log -Tail 50

# 測試 GUI 啟動邏輯
.\scripts\test-gui-startup.ps1

# 以管理員身份啟動
.\scripts\launch-gui-admin.ps1
```

### 10. 無法綁定 80 端口（權限被拒）

**錯誤訊息：**
```
bind() to 0.0.0.0:80 failed (10013: An attempt was made to access a socket in a way forbidden by its access permissions)
```

**原因：**
1. 其他程序佔用 80 端口
2. Windows 保留端口範圍衝突
3. 沒有管理員權限

**解決方法：**

```powershell
# 1. 檢查端口佔用
netstat -ano | Select-String ":80"

# 2. 找出佔用進程
Get-Process -Id <PID>

# 3. 檢查保留端口範圍
netsh interface ipv4 show excludedportrange protocol=tcp

# 4. 以管理員身份啟動
.\scripts\restart-admin.ps1
```

---

## 📂 目錄結構

```
22_nginx/
│
├── nginx/                          # nginx 執行檔目錄
│   ├── nginx.exe                   # nginx 主程式
│   ├── conf/                       # nginx 原始配置（未使用）
│   ├── html/                       # 預設網頁目錄
│   └── ...
│
├── conf/                           # 主配置目錄
│   └── nginx.conf                  # nginx 主配置文件
│
├── conf.d/                         # 模組化配置目錄
│   ├── *.conf                      # 實際生效的配置文件
│   ├── example-http.conf.template  # HTTP 範本
│   ├── example-https.conf.template # HTTPS 範本
│   ├── example-websocket.conf.template  # WebSocket 範本
│   └── example-loadbalance.conf.template # 負載平衡範本
│
├── scripts/                        # PowerShell 管理腳本
│   ├── nginx-manager.ps1           # nginx 服務管理
│   ├── add-proxy.ps1               # 添加反向代理
│   ├── remove-proxy.ps1            # 移除反向代理
│   ├── list-proxy.ps1              # 列出所有代理
│   ├── generate-ssl.ps1            # 生成 SSL 憑證
│   ├── nginx-gui.ps1               # GUI 主程式
│   ├── gui-helpers.ps1             # GUI 輔助函數
│   ├── diagnose.ps1                # 診斷工具（新）
│   ├── restart-admin.ps1           # 管理員重啟工具（新）
│   ├── test-gui-startup.ps1        # GUI 啟動測試（新）
│   └── launch-gui-admin.ps1        # 快速管理員啟動（新）
│
├── ssl/                            # SSL 憑證目錄
│   ├── <domain>.crt                # 憑證文件
├── logs/                           # 日誌文件目錄
│   ├── error.log                   # nginx 錯誤日誌
│   ├── access.log                  # nginx 訪問日誌
│   ├── nginx.pid                   # nginx 進程 ID
│   └── <domain>.*.log              # 各域名的專屬日誌
│
├── 啟動GUI.bat                     # GUI 快速啟動器（雙擊運行）
└── README.md                       # 本說明文件屬日誌
│
└── README.md                       # 本說明文件
```

---

## 🛠️ 進階技巧

### 自動啟動 nginx（開機啟動）

**方法 1：使用任務計劃程序**

1. 開啟「工作排程器」（Task Scheduler）
2. 創建基本任務
3. 觸發條件：「電腦啟動時」
4. 動作：「啟動程式」
   - 程式：`powershell.exe`
   - 參數：`-File "c:\Jarvis\22_nginx\scripts\nginx-manager.ps1" -Action start`

**方法 2：使用啟動資料夾**

創建批次檔案 `start-nginx.bat`：

```batch
@echo off
cd /d c:\Jarvis\22_nginx
powershell -ExecutionPolicy Bypass -File ".\scripts\nginx-manager.ps1" -Action start
```

將檔案放到啟動資料夾：`C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp`

### 查看即時日誌

```powershell
# 查看錯誤日誌（最後 20 行）
Get-Content logs\error.log -Tail 20

# 即時監控訪問日誌
Get-Content logs\access.log -Wait -Tail 10

# 查看特定域名的日誌
Get-Content logs\api.local.access.log -Tail 50
```

### 效能調校

編輯 `conf/nginx.conf`：

```nginx
# 增加工作進程數（根據 CPU 核心數調整）
worker_processes  2;

events {
    # 增加連接數
    worker_connections  2048;
}

http {
    # 啟用快取
    proxy_cache_path ../cache levels=1:2 keys_zone=my_cache:10m max_size=1g inactive=60m;
    proxy_cache my_cache;
    
    # 壓縮設定
    gzip  on;
    gzip_min_length 1024;
    gzip_comp_level 5;
    gzip_types text/plain text/css application/json application/javascript;
}
```

---

## 📚 相關資源

- **nginx 官方文件**：https://nginx.org/en/docs/
- **nginx Windows 下載**：https://nginx.org/en/download.html
- **OpenSSL for Windows**：https://slproweb.com/products/Win32OpenSSL.html

---

## 🤝 支援與反饋

如遇到問題或有改進建議，請檢查以下資源：

1. 查看錯誤日誌：`logs\error.log`
2. 測試配置文件：`.\scripts\nginx-manager.ps1 -Action test`
3. 參考本文件的「常見問題」章節

---

## 📄 授權

本專案僅供學習和本地開發使用。

**注意事項：**
- 本專案生成的 SSL 憑證為自簽憑證，僅供開發測試使用
- 不要在生產環境中使用自簽憑證
- 修改系統 hosts 文件需要管理員權限

---

## 📋 更新日誌

### v1.1.0 (2025-11-04)

**主要更新：**
- ✅ 修復 nginx.conf include 路徑錯誤（`../../conf.d/*.conf` → `../conf.d/*.conf`）
- ✅ 修復 UTF-8 BOM 編碼問題，所有配置文件現在使用無 BOM 的 UTF-8
- ✅ 新增診斷工具 `diagnose.ps1`，提供全面的系統檢查
- ✅ 新增 GUI 智能啟動檢查（管理員權限、nginx 狀態、端口監聽）
- ✅ 新增自動清理孤立 nginx 進程功能
- ✅ 新增管理員重啟工具 `restart-admin.ps1`
- ✅ 新增 GUI 啟動測試工具 `test-gui-startup.ps1`
- ✅ 新增快速管理員啟動腳本 `launch-gui-admin.ps1`
- ✅ GUI 完整日誌記錄功能（`logs/gui.log`）
- ✅ 確認端口 80 正常監聽

**文件更新：**
- 📝 新增 `docs/GUI_USAGE.md` - GUI 詳細使用指南
- 📝 更新 README.md 包含所有新功能說明
- 📝 新增故障排除指南

### v1.0.0 (2025-11-03)

**初始版本：**
- nginx 1.29.3 for Windows
- 反向代理管理腳本
- GUI 圖形介面
- SSL 憑證生成
- hosts 文件自動管理

---

## 🔗 相關文件

- **GUI 使用指南**：[docs/GUI_USAGE.md](docs/GUI_USAGE.md)
- **故障排除**：運行 `.\scripts\diagnose.ps1`
- **配置範例**：查看 `conf.d/*.template` 文件

---

**版本**：1.1.0  
**最後更新**：2025-11-04  
**nginx 版本**：1.29.3  
**狀態**：✅ 生產就緒
