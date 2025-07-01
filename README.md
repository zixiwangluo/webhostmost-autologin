webhostmost - 控制面板自动登录脚本  
使用方法  
　　在 GitHub 仓库中，进入右上角Settings，在侧边栏找到Secrets and variables，点击展开选择Actions，点击New repository secret，然后创建一个名为：“USERNAME_AND_PASSWORD”的Secret，将 JSON 格式的账号密码字符串作为它的值，如下格式：  
{
  "user1@example.com": "password123",
  "user2@example.com": "password456",
  "user3@example.com": "password789"
}
