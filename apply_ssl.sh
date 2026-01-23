#!/bin/bash

# ==========================================================
# 脚本名称: apply_ssl.sh
# 功能: 使用 Cloudflare API Token 申请通配符证书 (DNS-01)
# ==========================================================

# 1. 交互获取输入 (如果运行脚本没带参数)
TOKEN=$1
DOMAIN=$2

if [ -z "$TOKEN" ]; then
    read -p "请输入你的 Cloudflare API Token: " TOKEN
fi

if [ -z "$DOMAIN" ]; then
    read -p "请输入你的主域名 (例如 example.com): " DOMAIN
fi

# 再次校验
if [ -z "$TOKEN" ] || [ -z "$DOMAIN" ]; then
    echo "错误: Token 和域名不能为空。"
    exit 1
fi

# 2. 导出环境变量 (acme.sh 只需要 CF_Token)
export CF_Token="$TOKEN"

# 3. 确保证书存放目录存在
CERT_PATH="/etc/nginx/ssl/$DOMAIN"
sudo mkdir -p "$CERT_PATH"

echo "--------------------------------------------"
echo "准备申请域名: $DOMAIN 和 *.$DOMAIN"
echo "证书存放路径: $CERT_PATH"
echo "--------------------------------------------"

# 4. 检查并安装 acme.sh
if [ ! -f "$HOME/.acme.sh/acme.sh" ]; then
    echo "正在安装 acme.sh..."
    curl https://get.acme.sh | sh -s email=admin@$DOMAIN
    source ~/.bashrc
fi

# 5. 开始申请证书 (使用 DNS-01 验证)
~/.acme.sh/acme.sh --issue --dns dns_cf \
    -d "$DOMAIN" \
    -d "*.$DOMAIN" \
    --force

# 6. 安装证书到指定目录
if [ $? -eq 0 ]; then
    ~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
        --key-file       "$CERT_PATH/privatekey.pem"  \
        --fullchain-file "$CERT_PATH/fullchain.pem"
        # --reloadcmd      "sudo systemctl reload nginx || true"

    echo "--------------------------------------------"
    echo "✅ 证书申请成功！"
    echo "私钥: $CERT_PATH/privatekey.pem"
    echo "证书: $CERT_PATH/fullchain.pem"
    echo "提示: acme.sh 已配置自动续期，无需手动干预。"
    echo "--------------------------------------------"
else
    echo "❌ 证书申请失败，请检查 Token 权限或域名是否正确。"
    exit 1
fi
