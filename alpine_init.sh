#!/bin/sh

# =========================================================
# 脚本名称: alpine_ultimate_init.sh
# 适用环境: Alpine Linux (128MB/256MB RAM / 1GB Disk / 极致精简)
# 功能：虚拟内存、BBR、监控工具、时区、日志滚动、磁盘优化
# =========================================================

# 1. 检查并创建 256MB Swap 虚拟内存
# 256MB 既能缓解 128MB 物理内存的压力，又不会占用太多磁盘空间
if [ ! -f /swapfile ]; then
    echo "--- 正在创建 256MB 虚拟内存 (Swap) ---"
    dd if=/dev/zero of=/swapfile bs=1M count=256
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile none swap sw 0 0" >> /etc/fstab
    echo "Swap 创建成功。"
fi

# 2. 限制系统日志大小 (关键：防止 1GB 硬盘爆满)
# 修改 Alpine 默认的 syslogd 配置：单个日志最大 2MB，保留 3 个备份
echo "--- 正在设置日志滚动限制 (防止磁盘溢出) ---"
if [ -f /etc/conf.d/syslog ]; then
    # -s 2048 表示 2048KB (2MB)，-b 3 表示保留 3 个旧日志文件
    sed -i 's/SYSLOGD_OPTS=.*/SYSLOGD_OPTS="-s 2048 -b 3"/' /etc/conf.d/syslog
    rc-service syslog restart
fi

# 3. 更新系统并安装监控工具
echo "--- 正在更新系统并安装工具 (htop, iftop, vnstat) ---"
apk update && apk upgrade
apk add htop iftop vnstat bash curl tzdata

# 4. 设置系统时区为上海 (CST)
echo "--- 正在配置系统时区 ---"
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo "Asia/Shanghai" > /etc/timezone

# 5. 开启内核 BBR 加速
echo "--- 正在开启内核 BBR 加速 ---"
cat >> /etc/sysctl.conf <<EOF
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
sysctl -p

# 6. 配置并启动 vnStat 流量统计
echo "--- 正在启动流量统计服务 ---"
rc-update add vnstat default
rc-service vnstat start

# 7. 最后的磁盘清理
echo "--- 正在清理临时文件 ---"
rm -rf /var/cache/apk/*
rm -rf /tmp/*

echo "========================================================="
echo "初始化完成！系统现在非常稳健且精简。"
echo "日志限制：已启用 (Max 2MB x 3)"
echo "当前磁盘：df -h"
echo "当前内存：free -m"
echo "========================================================="
