const puppeteer = require('puppeteer');

async function login(username, password) {
  console.log(`尝试登录账号: ${username}`);
  
  // 启动浏览器
  const browser = await puppeteer.launch({
    headless: 'new',
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
    await page.waitForSelector('#username', { timeout: 10000 });
    await page.waitForSelector('#password', { timeout: 10000 });
    
    // 输入用户名和密码
    await page.type('#username', username);
    await page.type('#password', password);
    
    // 点击登录按钮
    await page.click('button[type="submit"]');
    
    // 等待登录完成
    await page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 30000 });
    
    // 检查是否登录成功
    const url = page.url();
    if (url.includes('clientarea.php')) {
      console.log(`${username} 登录成功!`);
    } else {
      console.log(`${username} 登录失败!`);
    }
    
    // 截图以验证登录状态
    await page.screenshot({ path: `${username.split('@')[0]}-screenshot.png` });
    
    // 等待几秒钟
    await new Promise(resolve => setTimeout(resolve, 3000));
    
  } catch (error) {
    console.error(`登录 ${username} 时出错:`, error);
  } finally {
    await browser.close();
  }
}

async function main() {
  // 从环境变量获取凭据
  const credentials = process.env.USERNAME_AND_PASSWORD;
  
  if (!credentials) {
    console.error('没有找到凭据。请确保设置了 USERNAME_AND_PASSWORD 环境变量。');
    process.exit(1);
  }
  
  // 解析凭据
  const lines = credentials.split('\n');
  
  for (const line of lines) {
    if (!line.trim()) continue;
    
    try {
      // 提取用户名和密码
      const usernamePart = line.match(/"Username:(.*?)"/i);
      const passwordPart = line.match(/"Password:(.*?)"/i);
      
      if (!usernamePart || !passwordPart) {
        console.error(`无法解析凭据行: ${line}`);
        continue;
      }
      
      const username = usernamePart[1].trim();
      const password = passwordPart[1].trim();
      
      // 登录当前账号
      await login(username, password);
      
      // 在账号之间添加延迟
      await new Promise(resolve => setTimeout(resolve, 5000));
      
    } catch (error) {
      console.error(`处理凭据时出错: ${error.message}`);
    }
  }
}

main().catch(error => {
  console.error('程序执行出错:', error);
  process.exit(1);
});
