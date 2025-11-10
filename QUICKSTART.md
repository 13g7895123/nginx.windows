# 快速參考指南

## 常用命令

### 服務管理
```powershell
# 啟動
.\scripts\nginx-manager.ps1 -Action start

# 停止
.\scripts\nginx-manager.ps1 -Action stop

# 重載配置
.\scripts\nginx-manager.ps1 -Action reload

# 查看狀態
.\scripts\nginx-manager.ps1 -Action status
```

### 代理管理
```powershell
# 添加 HTTP 代理
.\scripts\add-proxy.ps1 -Domain "app.local" -TargetUrl "http://localhost:3000" -AddToHosts

# 添加 HTTPS 代理
.\scripts\add-proxy.ps1 -Domain "secure.local" -TargetUrl "http://localhost:3000" -Type https -AddToHosts

# 添加 WebSocket 代理
.\scripts\add-proxy.ps1 -Domain "ws.local" -TargetUrl "http://localhost:3001" -Type websocket -AddToHosts

# 查看所有代理
.\scripts\list-proxy.ps1

# 移除代理
.\scripts\remove-proxy.ps1 -Domain "app.local" -RemoveFromHosts
```

### SSL 憑證
```powershell
# 生成自簽憑證
.\scripts\generate-ssl.ps1 -Domain "example.local"
```

## 快速開始流程

### 方式 1：使用 GUI（推薦初學者）

1. **啟動 GUI**
   - 雙擊專案根目錄的 `啟動GUI.bat`
   - 或執行 `.\scripts\nginx-gui.ps1`

2. **啟動 nginx**
   - 點擊「啟動」按鈕

3. **添加代理**
   - 切換到「代理管理」Tab
   - 點擊「添加代理」
   - 填寫域名和目標 URL
   - 勾選「自動添加到 hosts」
   - 點擊「確定」

4. **重載配置**
   - 點擊「重載配置」按鈕

5. **訪問服務**
   - 打開瀏覽器訪問配置的域名

### 方式 2：使用命令列（適合進階使用者）

1. **啟動 nginx**
   ```powershell
   .\scripts\nginx-manager.ps1 -Action start
   ```

2. **添加代理**
   ```powershell
   .\scripts\add-proxy.ps1 -Domain "myapp.local" -TargetUrl "http://localhost:3000" -AddToHosts
   ```

3. **重載配置**
   ```powershell
   .\scripts\nginx-manager.ps1 -Action reload
   ```

4. **訪問服務**
   - 打開瀏覽器訪問 `http://myapp.local`

## 目錄說明

- `nginx/` - nginx 執行檔
- `conf/` - 主配置文件
- `conf.d/` - 模組化配置（實際生效）
- `scripts/` - 管理腳本
- `ssl/` - SSL 憑證
- `logs/` - 日誌文件

## 常見端口

- HTTP: 80
- HTTPS: 443
- 常見後端端口: 3000, 5000, 8080

## 故障排除

1. **nginx 無法啟動** → 檢查端口佔用 `netstat -ano | findstr ":80"`
2. **無法訪問域名** → 確認 hosts 文件和 nginx 狀態
3. **配置不生效** → 重載配置 `reload`
4. **SSL 警告** → 正常現象，接受自簽憑證即可

詳細說明請參考 `README.md`
