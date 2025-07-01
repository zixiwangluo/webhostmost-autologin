# webhostmost 控制面板自动登录脚本

## 📌 项目简介

一个使用 Puppeteer 实现的 webhostmost 控制面板自动登录脚本，支持多账户批量登录和操作。

## 🛠️ 功能特性

- ✅ 多账户批量自动登录
- ✅ 登录结果截图保存
- ✅ 完善的错误处理和日志记录
- ✅ 账户间智能延迟防止封禁
- ✅ 支持 GitHub Actions 自动化执行

## ⚙️ 安装与配置

### 环境要求

- Node.js 16+
- Puppeteer 最新版

### 配置步骤

1. **Fork 本仓库**  
   点击 GitHub 右上角的 Fork 按钮创建您自己的副本

2. **设置账户凭据**  
   按以下步骤添加您的登录凭据：

   - 进入仓库 Settings → Secrets and variables → Actions
   - 点击 "New repository secret"
   - 输入名称：`USERNAME_AND_PASSWORD`
   - 在值区域粘贴您的 JSON 格式账户信息：

     ```json
     {
       "your_account1@example.com": "your_password1",
       "your_account2@example.com": "your_password2"
     }
     ```

3. **（可选）本地运行配置**  
   如需本地运行，创建 `.env` 文件：

   ```env
   USERNAME_AND_PASSWORD={"your_account@example.com":"your_password"}
   ```

## 🚀 使用方法

### GitHub Actions 自动运行

1. 默认配置下，工作流会在每月20号的 UTC 时间 00:00 运行
2. 如需手动触发：
   - 进入仓库 Actions 标签页
   - 选择 "WebHostMost Login"
   - 点击 "Run workflow"

### 本地运行命令

```bash
npm install
npm start
```

## 📋 账户配置规范

### JSON 格式要求

```json
{
  "邮箱或用户名1": "密码1",
  "邮箱或用户名2": "密码2"
}
```

### 注意事项

1. **密码特殊字符处理**：
   - 包含引号 `"` 的密码：使用反斜杠转义 `\"`
   - 示例：`"password\"123"`

2. **多账户建议**：
   ```json
   {
     "account1@domain.com": "P@ssw0rd1!",
     "account2@domain.com": "P@ssw0rd2\"",
     "account3@domain.com": "P@ssw0rd3\\"
   }
   ```

## 📜 输出结果

- 每个账户登录后会生成截图：`用户名-screenshot.png`
- 控制台输出示例：
  ```
  === Processing account: user1@example.com ===
  ✅ Successfully logged in as user1@example.com
  Waiting 5 seconds before next account...
  
  === Processing account: user2@example.com ===
  ❌ Failed to login as user2@example.com
  ```
## ❓ 常见问题

### Q1: 登录失败怎么办？
- 检查密码是否包含需要转义的特殊字符
- 手动访问网站确认账户可用性
- 查看生成的截图分析失败原因

### Q2: 如何修改执行频率？
编辑 `.github/workflows/webhostmost_login.yml` 中的 `schedule` 部分：

```yaml
schedule:
    # 每月20号的 UTC 时间 00:00 运行
    - cron: '0 0 20 * *'
```

### Q3: 如何添加更多操作？
修改 `login.js` 脚本，在登录成功后添加所需操作：

```javascript
// 登录成功后示例操作
await page.click('#navigation-menu');
await page.waitForSelector('.account-dashboard');
```

### 关于sftp
开通的时候邮件内会给你一个.ppk的文件，mt管理器内支持sftp，
主机填写：server7.webhostmost.com
端口写：2323
用户名就是邮件内的用户名
选择使用密钥登陆，选择密钥文件，如果直接选择.ppk文件作为密钥，会登陆失败。
实际上，需要把ppk格式的文件，使用相关的转换工具或者网站转成pem格式的密钥证书才能成功登陆，我用的在线转换网站：
[PPK to PEM Converter Online - Free SSH Key Format Conversion Tool](https://showdns.net/ssh-key-converter/ppk-to-pem)

转成pem后，使用pem文件，或者复制转换后的pem文件内容作为密钥即可登陆sftp。
## 📄 许可证

本项目基于 [Airskotex1/webhostmost-autolive](https://github.com/Airskotex1/webhostmost-autolive)  修改，采用 [MIT License](LICENSE) 开源。
