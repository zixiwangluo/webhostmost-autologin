const puppeteer = require('puppeteer');

async function login(username, password) {
  console.log(`Attempting to login with username: ${username}`);
  
  // 启动浏览器
  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  
  try {
    const page = await browser.newPage();
    
    // 设置视窗大小
    await page.setViewport({ width: 1280, height: 800 });
    
    // 导航到登录页面
    await page.goto('https://client.webhostmost.com/login', {
      waitUntil: 'networkidle2',
      timeout: 60000
    });
    
    // 等待登录表单加载
    await page.waitForSelector('#inputEmail', { timeout: 10000 });
    
    // 输入用户名和密码
    await page.type('#inputEmail', username);
    await page.type('#inputPassword', password);
    
    // 点击登录按钮
    await Promise.all([
      page.click('button[type="submit"]'),
      page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 60000 })
    ]);
    
    // 检查是否登录成功
    const url = page.url();
    if (url.includes('clientarea.php')) {
      console.log(`Successfully logged in with ${username}`);
    } else {
      console.log(`Failed to login with ${username}`);
    }
    
    // 截图以便验证（可选）
    await page.screenshot({ path: `${username.split('@')[0]}-screenshot.png` });
    
  } catch (error) {
    console.error(`Error during login process for ${username}:`, error);
  } finally {
    await browser.close();
  }
}

async function main() {
  // 从环境变量获取凭据
  const credentials = process.env.USERNAME_AND_PASSWORD;
  
  if (!credentials) {
    console.error('No credentials provided. Please set the USERNAME_AND_PASSWORD secret.');
    process.exit(1);
  }
  
  // 解析凭据
  const lines = credentials.split('\n');
  
  for (const line of lines) {
    if (!line.trim()) continue;
    
    try {
      // 提取用户名和密码
      const usernamePart = line.match(/"Username:([^"]+)"/);
      const passwordPart = line.match(/"Password:([^"]+)"/);
      
      if (!usernamePart || !passwordPart) {
        console.error(`Invalid credential format: ${line}`);
        continue;
      }
      
      const username = usernamePart[1];
      const password = passwordPart[1];
      
      // 执行登录
      await login(username, password);
      
      // 在账户之间添加延迟，避免被检测为自动化
      await new Promise(resolve => setTimeout(resolve, 5000));
      
    } catch (error) {
      console.error(`Error processing line: ${line}`, error);
    }
  }
}

main().catch(console.error);
