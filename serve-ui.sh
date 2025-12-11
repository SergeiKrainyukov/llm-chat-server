#!/bin/bash

SERVER_USER="root"
SERVER_IP="45.144.30.160"

echo "🌐 Setting up Web UI on server..."

# Создать директорию для UI и скопировать файл
ssh $SERVER_USER@$SERVER_IP "mkdir -p /var/www/llm-chat"
scp chat-ui.html $SERVER_USER@$SERVER_IP:/var/www/llm-chat/index.html

# Настроить nginx для раздачи UI на порту 80
ssh $SERVER_USER@$SERVER_IP << 'EOF'
apt-get update -qq
apt-get install -y nginx -qq

# Создать конфиг nginx
cat > /etc/nginx/sites-available/llm-chat << 'NGINX_CONF'
server {
    listen 80;
    server_name _;

    root /var/www/llm-chat;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
NGINX_CONF

# Активировать конфиг
ln -sf /etc/nginx/sites-available/llm-chat /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Перезапустить nginx
systemctl restart nginx
systemctl enable nginx

# Открыть порт 80
ufw allow 80/tcp 2>/dev/null || true
EOF

echo ""
echo "✅ Web UI deployed!"
echo ""
echo "🌐 Open in browser: http://$SERVER_IP/"
echo "   (No need to specify port, just http://$SERVER_IP/)"
echo ""
