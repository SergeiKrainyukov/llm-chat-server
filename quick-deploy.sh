#!/bin/bash

SERVER_IP="45.144.30.160"

echo "╔════════════════════════════════════════╗"
echo "║   Quick Deploy (No Rebuild)            ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Password: wOavaBt5H8H2"
echo ""

# Убиваем зависшие процессы на сервере
echo "Step 1: Cleaning up server..."
ssh root@$SERVER_IP << 'ENDSSH'
echo "Killing old processes..."
pkill -9 -f gradle 2>/dev/null || true
pkill -9 -f GradleDaemon 2>/dev/null || true
pkill -9 -f kotlin 2>/dev/null || true
lsof -ti :8080 | xargs kill -9 2>/dev/null || true
sleep 3
echo "✅ Cleanup done"
ENDSSH

echo ""
echo "Step 2: Uploading files..."

# Копируем только необходимые файлы
echo "→ Main.kt..."
scp src/main/kotlin/Main.kt root@$SERVER_IP:/llm-chat-server/src/main/kotlin/

echo "→ users_data.json..."
scp src/main/resources/users_data.json root@$SERVER_IP:/llm-chat-server/src/main/resources/

echo "→ chat-ui.html..."
scp chat-ui.html root@$SERVER_IP:/llm-chat-server/

echo "→ Pre-built JAR..."
scp build/libs/llm-chat-server-1.0.0.jar root@$SERVER_IP:/llm-chat-server/build/libs/

echo "✅ Files uploaded"
echo ""

echo "Step 3: Deploying on server..."
ssh root@$SERVER_IP << 'ENDSSH'
cd /llm-chat-server

echo "→ Updating web UI..."
if [ -f /var/www/html/index.html ]; then
    cp chat-ui.html /var/www/html/index.html
    echo "  ✅ Updated /var/www/html/index.html"
fi

if [ -f /usr/share/nginx/html/index.html ]; then
    cp chat-ui.html /usr/share/nginx/html/index.html
    echo "  ✅ Updated /usr/share/nginx/html/index.html"
fi

echo ""
echo "→ Starting server with pre-built JAR..."
nohup ./run-local.sh > server.log 2>&1 &
sleep 10

echo "→ Checking server..."
if lsof -ti :8080 > /dev/null 2>&1; then
    echo "✅ Server is running!"
    echo ""
    curl -s http://localhost:8080/status
    echo ""
else
    echo "❌ Server not running, checking logs..."
    tail -30 server.log
    exit 1
fi

echo ""
echo "→ Verifying UI..."
if grep -q "Аналитика" /var/www/html/index.html 2>/dev/null; then
    echo "✅ Analytics tab found in UI!"
else
    echo "⚠️  UI verification failed"
fi

echo ""
echo "Memory status:"
free -h | grep Mem
ENDSSH

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Deployment failed"
    exit 1
fi

echo ""
echo "╔════════════════════════════════════════╗"
echo "║         Deploy Complete! 🎉            ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "🌐 Test it:"
echo "  http://$SERVER_IP/"
echo ""
echo "Clear cache: Ctrl+Shift+R"
echo ""

# Проверка
curl -s http://$SERVER_IP/ | grep -q "Аналитика" && echo "✅ Analytics tab detected from outside!" || echo "⚠️  Analytics tab not detected yet"
echo ""
