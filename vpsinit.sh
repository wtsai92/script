#!/bin/bash

# 确保以 root 权限运行
if [ "$EUID" -ne 0 ]; then 
  echo "请以 root 用户运行此脚本"
  exit 1
fi

echo "------------------------------------------------"
echo "          VPS 环境初始化脚本开始运行            "
echo "------------------------------------------------"

# 1. 查看发行版本和内核版本
echo "### 1. 系统信息"
if [ -f /etc/os-release ]; then
    cat /etc/os-release | grep -E '^(PRETTY_NAME|VERSION)='
else
    lsb_release -a
fi
echo -n "Kernel Version: "
uname -r
echo ""

# 2. 更新系统软件包
echo "### 2. 更新系统软件包..."
apt update && apt upgrade -y

# 3. 修改 root 密码
echo "### 3. 修改 root 密码"
passwd root

# 4. 时区设置 (数字选项)
echo "### 4. 时区设置"
echo "当前时区信息："
timedatectl | grep "Time zone" || date
echo ""
echo "请选择要设置的时区编号:"
echo "1) Asia/Singapore (新加坡)"
echo "2) Asia/Taipei    (台北)"
echo "3) Asia/Hong_Kong (香港)"
echo "4) Skip           (跳过/不修改)"
echo ""
read -p "请输入数字 [1-4]: " tz_choice

case $tz_choice in
    1)
        timedatectl set-timezone Asia/Singapore
        echo "已成功设置为 Asia/Singapore"
        ;;
    2)
        timedatectl set-timezone Asia/Taipei
        echo "已成功设置为 Asia/Taipei"
        ;;
    3)
        timedatectl set-timezone Asia/Hong_Kong
        echo "已成功设置为 Asia/Hong_Kong"
        ;;
    4)
        echo "已跳过时区设置"
        ;;
    *)
        echo "输入无效，跳过此步骤"
        ;;
esac
echo ""

# 5. 检查并开启 BBR
echo "### 5. 检查 BBR 状态"
if lsmod | grep -q bbr; then
    echo "BBR 已经开启，无需重复安装。"
else
    echo "未检测到 BBR，正在准备安装..."
    wget --no-check-certificate -O /opt/bbr.sh https://github.com/teddysun/across/raw/master/bbr.sh
    chmod 755 /opt/bbr.sh
    /opt/bbr.sh
fi

# 6. 修复 Vim 并配置别名
echo "### 6. 重装 Vim 及配置别名..."
apt-get remove vim-common -y
apt-get install vim -y

# 添加 ll 等常用别名到 .bashrc (检查是否已存在，避免重复添加)
if ! grep -q "alias ll='ls -la'" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Custom Aliases" >> ~/.bashrc
    echo "alias ll='ls -la'" >> ~/.bashrc
    echo "alias la='ls -A'" >> ~/.bashrc
    echo "alias l='ls -CF'" >> ~/.bashrc
    echo "已添加 ll 等别名到 .bashrc"
fi
source .bashrc

# 7. 安装常用工具
echo "### 7. 安装常用工具包..."
apt install -y vnstat iftop nethogs dnsutils htop curl unzip
# 安装 nxtrace
curl -sL nxtrace.org/nt | bash

# 8. 查看 DNS 配置
echo "### 8. 当前 DNS 配置"
cat /etc/resolv.conf

echo "------------------------------------------------"
echo "          VPS 初始化完成！                      "
echo "          请执行: source ~/.bashrc 使别名生效   "
echo "------------------------------------------------"
