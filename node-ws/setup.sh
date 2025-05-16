#!/bin/bash

username=$(whoami) # 获取当前用户名

# Domain 参数处理
if [ -z "$1" ]; then
    # 如果没有提供 domain 参数，则尝试自动检测
    domains_path="/home/$username/domains/"
    echo "提示：未提供域名参数，尝试在 $domains_path 中自动检测..."

    # 查找 domains_path 下的第一个目录名作为 domain
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
    # 使用 xargs 清理 wc -l 可能产生的空格，并使用算术比较 (( ))
    all_domain_dirs_count_output=$(find "$domains_path" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l)
    all_domain_dirs_count=$(echo "$all_domain_dirs_count_output" | xargs) # 清理空格

    if (( all_domain_dirs_count > 1 )); then # 使用算术比较
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

curl -fLso "/home/$username/domains/$domain/public_html/index.js" "https://raw.githubusercontent.com/Airskotex1/webhostmost-autolive/main/node-ws/index.js"
if [ $? -ne 0 ]; then
    echo "错误：下载脚本 index.js 失败！"
    exit 1
fi

curl -fLso "/home/$username/cron.sh" "https://raw.githubusercontent.com/Airskotex1/webhostmost-autolive/main/node-ws/cron.sh"
if [ $? -ne 0 ]; then
    echo "错误：下载脚本 cron.sh 失败！"
    exit 1
fi
chmod +x /home/$username/cron.sh

# UUID 参数处理
default_uuid="0196d2a9-b1c0-708e-b48b-6d7634c7fba9"
read -p "输入UUID (直接回车使用默认值: $default_uuid): " uuid
if [ -z "$uuid" ]; then
    uuid="$default_uuid"
    echo "未输入UUID，使用默认UUID: $uuid"
else
    echo "你输入的UUID: $uuid"
fi

# 探针安装逻辑
read -p "是否安装探针? [y/n] (默认为n): " input
input=${input:-n}

nezha_server=""
nezha_port=""
nezha_key=""

if [ "$input" != "n" ] && [ "$input" != "N" ]; then
   read -p "输入NEZHA_SERVER (哪吒v1填写形式：nz.abc.com:8008, 哪吒v0填写形式：nz.abc.com): " nezha_server
   if [ -z "$nezha_server" ]; then
       echo "错误: NEZHA_SERVER 不能为空！"
       exit 1
   fi
   read -p "输入NEZHA_PORT (v1面板此处按回车, v0的agent端口为{443,8443,2096,2087,2083,2053}其中之一时开启tls): " nezha_port
   read -p "输入NEZHA_KEY (v1的NZ_CLIENT_SECRET或v0的agent端口): " nezha_key
   if [ -z "$nezha_key" ]; then
       echo "错误: NEZHA_KEY 不能为空！"
       exit 1
   fi
   echo "你输入的探针信息: NEZHA_SERVER=$nezha_server, NEZHA_PORT=$nezha_port, NEZHA_KEY=$nezha_key"
else
    echo "不安装探针。"
fi

# 文件内容替换
echo "正在配置 index.js..."
sed -i "s/NEZHA_SERVER || ''/NEZHA_SERVER || '$nezha_server'/g" "/home/$username/domains/$domain/public_html/index.js"
sed -i "s/NEZHA_PORT || ''/NEZHA_PORT || '$nezha_port'/g" "/home/$username/domains/$domain/public_html/index.js"
sed -i "s/NEZHA_KEY || ''/NEZHA_KEY || '$nezha_key'/g" "/home/$username/domains/$domain/public_html/index.js"
sed -i "s/1234.abc.com/$domain/g" "/home/$username/domains/$domain/public_html/index.js"
sed -i "s/3000;/$random_port;/g" "/home/$username/domains/$domain/public_html/index.js"
sed -i "s/0196d2a9-b1c0-708e-b48b-6d7634c7fba9/$uuid/g" "/home/$username/domains/$domain/public_html/index.js"

if [ "$input" = "y" ] || [ "$input" = "Y" ]; then
    echo "正在配置 cron.sh 以启用探针检查..."
    sed -i "s/nezha_check=false/nezha_check=true/g" "/home/$username/cron.sh"
fi

# 创建 package.json
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

# 配置 cron

echo "*/1 * * * * cd /home/$username/public_html && /home/$username/cron.sh" > ./mycron
crontab ./mycron >/dev/null 2>&1
rm ./mycron
# 使用 grep 和正则表达式提取 SUB_PATH 的默认值
sub_path=$(grep -o "const SUB_PATH = process.env.SUB_PATH || '[^']*'" "$index_js_path" | sed "s/const SUB_PATH = process.env.SUB_PATH || '\([^']*\)'/\1/")

# 如果没有找到值，检查是否使用了双引号
if [ -z "$sub_path" ]; then
    sub_path=$(grep -o 'const SUB_PATH = process.env.SUB_PATH || "[^"]*"' "$index_js_path" | sed 's/const SUB_PATH = process.env.SUB_PATH || "\([^"]*\)"/\1/')
fi

# 检查是否成功提取了值
if [ -z "$sub_path" ]; then
    echo "无法从 index.js 中提取 SUB_PATH 的值，使用默认值 'webhostmost'"
    sub_path="webhostmost"
else
    echo "从 index.js 中提取的 SUB_PATH 值为: $sub_path"
fi
# 现在你可以使用 $sub_path 变量了
echo "将使用路径: http://$domain/$sub_path 配置每十分钟访问一次保活"
(crontab -l 2>/dev/null; echo "*/10 * * * * curl http://$domain/$sub_path") | crontab -


echo "安装完毕"
