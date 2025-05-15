#!/bin/bash

username=$(whoami) # 获取当前用户名
domains_path="/home/$username/domains/"

# Domain 参数处理
if [ -z "$1" ]; then
    echo "提示：未提供域名参数，尝试在 $domains_path 中自动检测..."

    # 获取 $domains_path 下所有一级子目录的名称，并存入数组
    # 使用 find 获取目录名，并通过 sort 对其排序
    mapfile -t available_domains < <(find "$domains_path" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; 2>/dev/null | sort)
    
    domain_count=${#available_domains[@]}

    if (( domain_count == 0 )); then
        echo "错误：未提供域名，并且在 $domains_path 中未能自动找到任何域名对应的目录。"
        echo "用法: $0 [domain]"
        exit 1
    elif (( domain_count == 1 )); then
        domain="${available_domains[0]}"  
        echo "自动检测到唯一的域名为: $domain"
    else
        # 发现多个域名，让用户选择
        echo "在 $domains_path 发现以下多个域名目录，请选择一个："
        for i in "${!available_domains[@]}"; do
            printf "  %d) %s\n" $((i+1)) "${available_domains[$i]}"
        done
        
        user_choice=""
        while true; do
            read -p "请输入数字选择一个域名 (1-${domain_count}): " user_choice
            # 校验输入是否为数字且在有效范围内
            if [[ "$user_choice" =~ ^[0-9]+$ ]] && (( user_choice >= 1 && user_choice <= domain_count )); then
                domain="${available_domains[$((user_choice-1))]}" # 数组索引从0开始
                echo "您已选择域名: $domain"
                break
            else  
                echo "无效的选择。请输入 1 到 ${domain_count} 之间的数字。"
            fi
        done
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

# UUID 参数处理 (默认值逻辑)
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

echo "安装完毕"
