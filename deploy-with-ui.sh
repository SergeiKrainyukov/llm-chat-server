#!/bin/bash

SERVER_USER="root"
SERVER_IP="45.144.30.160"
SERVER_PATH="/llm-chat-server"
WEB_PATH="/var/www/html"

echo "🚀 Deploying with Web UI..."

# 1. Deploy server files
echo "📦 Syncing server files..."
rsync -avz --exclude 'build/' --exclude '.gradle/' . $SERVER_USER@$SERVER_IP:$SERVER_PATH/

# 2. Copy UI to web directory
echo "🌐 Copying UI to web directory..."
ssh $SERVER_USER@$SERVER_IP "mkdir -p $WEB_PATH && cp $SERVER_PATH/chat-ui.html $WEB_PATH/index.html"

# 3. Update UI to use server IP
echo "⚙️  Configuring UI..."
ssh $SERVER_USER@$SERVER_IP "sed -i 's|http://localhost:8080|http://$SERVER_IP:8080|g' $WEB_PATH/index.html"

# 4. Install and start nginx (если нет Apache)
echo "📡 Setting up web server..."
ssh $SERVER_USER@$SERVER_IP << 'EOF'
# Если Apache остановлен, используем nginx на порту 80
if ! systemctl is-active --quiet apache2; then
    apt-get update -qq
    apt-get install -y nginx -qq
    systemctl start nginx
    systemctl enable nginx
fi
EOF

echo ""
echo "✅ Deploy complete!"
echo ""
echo "Access points:"
echo "  🌐 Web UI: http://$SERVER_IP/"
echo "  🔌 API: http://$SERVER_IP:8080/status"
echo ""
