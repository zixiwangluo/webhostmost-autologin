#!/bin/bash

username=$(whoami) # 获取当前用户名

# Domain 参数处理
if [ -z "$1" ]; then
    # 如果没有提供 domain 参数，则尝试自动检测
    domains_path="/home/$username/domains/"
    echo "提示：未提供域名参数，尝试在 $domains_path 中自动检测..."

    # 使用 find 命令更安全地处理各种目录名
    first_domain_dir=$(find "$domains_path" -maxdepth 1 -mindepth 1 -type d -print -quit 2>/dev/null)  

    if [ -z "$first_domain_dir" ]; then
        echo "错误：未提供域名，并且在 $domains_path 中未能自动找到任何域名对应的目录。"
        echo "用法: $0 [domain]"
        exit 1
    fi
    domain=$(basename "$first_domain_dir")
    echo "自动检测到域名为: $domain"

    # 检查是否还有其他域名目录，给出提示
    all_domain_dirs_count=$(find "$domains_path" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l)  
    if [ "$all_domain_dirs_count" -gt 1 ]; then
        echo "警告：在 $domains_path 发现多个域名目录。当前脚本使用了第一个找到的 '$domain'。"
        echo "其他发现的目录有:"
        find "$domains_path" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | sed "s/^/  - /"
    fi
else
    domain=$1
    echo "使用提供的域名: $domain"
fi

random_port=$((RANDOM % 40001 + 20000))

echo "准备将 index.js 下载到 /home/$username/domains/$domain/public_html/index.js"
# 确保目标目录存在
mkdir -p "/home/$username/domains/$domain/public_html/"

curl -s -o "/home/$username/domains/$domain/public_html/index.js" "https://raw.githubusercontent.com/frankiejun/node-ws/main/index.js"  
if [ $? -ne 0 ]; then
    echo "错误：下载脚本 index.js 失败！"
    exit 1
fi

curl -s -o "/home/$username/cron.sh" "https://raw.githubusercontent.com/frankiejun/node-ws/main/cron.sh"
if [ $? -ne 0 ]; then
    echo "错误：下载脚本 cron.sh 失败！"
    exit 1
fi
chmod +x /home/$username/cron.sh

# UUID 参数处理
default_uuid="0196d2a9-b1c0-708e-b48b-6d7634c7fba9"
read -p "输入UUID (直接回车使用默认值: $default_uuid): " uuid  # 添加空格以改善提示
if [ -z "$uuid" ]; then
    uuid="$default_uuid"
    echo "未输入UUID，使用默认UUID: $uuid"
else
    echo "你输入的UUID: $uuid"
fi

# 探针安装逻辑 (与原脚本保持一致)
read -p "是否安装探针? [y/n] (默认为n): " input # 修正提示，更清晰
input=${input:-n} # 如果用户直接回车，默认为 n

nezha_server=""
nezha_port=""
nezha_key=""

if [ "$input" != "n" ] && [ "$input" != "N" ]; then # 接受小写和大写 y
   read -p "输入NEZHA_SERVER (哪吒v1填写形式：nz.abc.com:8008, 哪吒v0填写形式：nz.abc.com): " nezha_server
   if [ -z "$nezha_server" ]; then
       echo "错误: NEZHA_SERVER 不能为空！"
       exit 1
   fi
   read -p "输入NEZHA_PORT (v1面板此处按回车, v0的agent端口为{443,8443,2096,2087,2083,2053}其中之一时开启tls): " nezha_port
   # nezha_port 可以为空，所以不需要检查 -z
   read -p "输入NEZHA_KEY (v1的NZ_CLIENT_SECRET或v0的agent端口): " nezha_key
   if [ -z "$nezha_key" ]; then
       echo "错误: NEZHA_KEY 不能为空！"
       exit 1
   fi
   echo "你输入的探针信息: NEZHA_SERVER=$nezha_server, NEZHA_PORT=$nezha_port, NEZHA_KEY=$nezha_key"
else
    echo "不安装探针。"
fi

# 文件内容替换 (与原脚本逻辑类似，注意转义特殊字符)
echo "正在配置 index.js..."
sed -i "s/NEZHA_SERVER || ''/NEZHA_SERVER || '$nezha_server'/g" "/home/$username/domains/$domain/public_html/index.js"
sed -i "s/NEZHA_PORT || ''/NEZHA_PORT || '$nezha_port'/g" "/home/$username/domains/$domain/public_html/index.js"
sed -i "s/NEZHA_KEY || ''/NEZHA_KEY || '$nezha_key'/g" "/home/$username/domains/$domain/public_html/index.js"
sed -i "s/1234.abc.com/$domain/g" "/home/$username/domains/$domain/public_html/index.js"
sed -i "s/3000;/$random_port;/g" "/home/$username/domains/$domain/public_html/index.js"
sed -i "s/de04add9-5c68-6bab-950c-08cd5320df33/$uuid/g" "/home/$username/domains/$domain/public_html/index.js"

if [ "$input" = "y" ] || [ "$input" = "Y" ]; then
    echo "正在配置 cron.sh 以启用探针检查..."
    sed -i "s/nezha_check=false/nezha_check=true/g" "/home/$username/cron.sh"
fi

# 创建 package.json (与原脚本一致)
echo "正在创建 package.json..."
cat > "/home/$username/domains/$domain/public_html/package.json" << EOF
{
  "name": "node-ws",
  "version": "1.0.0",
  "description": "Node.js Server",
  "main": "index.js",
  "author": "eoovve",
  "repository": "https://github.com/eoovve/node-ws",
  "license": "MIT",
  "private": false,
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "ws": "^8.14.2",
    "axios": "^1.6.2"
  },
  "engines": {
    "node": ">=14"
  }
}
EOF

echo "*/1 * * * * cd /home/$username/public_html && /home/$username/cron.sh" > ./mycron
crontab ./mycron >/dev/null 2>&1
rm ./mycron

echo "安装完毕"
