#!/bin/bash

# Конфигурация
SERVER_USER="root"
SERVER_IP="45.144.30.160"
SERVER_PATH="/llm-chat-server"

echo "╔════════════════════════════════════════╗"
echo "║   LLM Chat Server - Quick Deploy      ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Проверка что сборка прошла успешно
echo "Step 1/6: Building project locally..."
if ! ./gradlew build --no-daemon -q 2>&1 | grep -q "BUILD SUCCESSFUL\|BUILD FAILED"; then
    ./gradlew build --no-daemon
fi

if [ $? -ne 0 ]; then
    echo "❌ Build failed! Fix errors and try again."
    exit 1
fi
echo "✅ Build successful"
echo ""

# Синхронизация файлов
echo "Step 2/6: Syncing files to server..."
echo "Password for root@$SERVER_IP will be requested..."
rsync -avz --exclude 'build/' --exclude '.gradle/' --exclude '*.log' --exclude 'nohup.out' \
    . $SERVER_USER@$SERVER_IP:$SERVER_PATH/

if [ $? -ne 0 ]; then
    echo "❌ Failed to sync files. Check your connection and credentials."
    exit 1
fi
echo "✅ Files synced"
echo ""

# Остановка старого процесса
echo "Step 3/6: Stopping old server process..."
ssh $SERVER_USER@$SERVER_IP "lsof -ti :8080 | xargs kill -9 2>/dev/null || true"
sleep 2
echo "✅ Old process stopped"
echo ""

# Сборка на сервере
echo "Step 4/6: Building project on server..."
ssh $SERVER_USER@$SERVER_IP << 'EOF'
cd /llm-chat-server
./gradlew build --no-daemon -q
if [ $? -ne 0 ]; then
    echo "❌ Build failed on server"
    exit 1
fi
echo "✅ Build successful on server"
EOF

if [ $? -ne 0 ]; then
    echo "❌ Server build failed!"
    exit 1
fi
echo ""

# Запуск сервера
echo "Step 5/6: Starting server..."
ssh $SERVER_USER@$SERVER_IP << 'EOF'
cd /llm-chat-server
nohup ./run-local.sh > server.log 2>&1 &
sleep 8

# Проверка что процесс запустился
if lsof -ti :8080 > /dev/null 2>&1; then
    echo "✅ Server process started"
else
    echo "❌ Server failed to start"
    echo "Last 20 lines of log:"
    tail -20 server.log
    exit 1
fi
EOF

if [ $? -ne 0 ]; then
    echo "❌ Server start failed!"
    exit 1
fi
echo ""

# Проверка работоспособности
echo "Step 6/6: Testing server..."
sleep 2

# Тест локально на сервере
ssh $SERVER_USER@$SERVER_IP "curl -s http://localhost:8080/status" > /tmp/server_status.json

if [ $? -eq 0 ]; then
    echo "✅ Server is responding"
    echo ""
    echo "Server status:"
    cat /tmp/server_status.json | python3 -m json.tool 2>/dev/null || cat /tmp/server_status.json
    rm -f /tmp/server_status.json
else
    echo "⚠️  Server not responding yet"
    echo "Check logs with: ssh root@$SERVER_IP 'tail -50 /llm-chat-server/server.log'"
fi

echo ""
echo "╔════════════════════════════════════════╗"
echo "║          Deploy Complete!              ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "🌐 Server URL: http://$SERVER_IP:8080"
echo "📊 Status: http://$SERVER_IP:8080/status"
echo "💬 Chat API: http://$SERVER_IP:8080/chat"
echo ""
echo "📋 Useful commands:"
echo "  View logs:    ssh root@$SERVER_IP 'tail -f /llm-chat-server/server.log'"
echo "  Stop server:  ssh root@$SERVER_IP 'lsof -ti :8080 | xargs kill -9'"
echo "  Restart:      ./deploy.sh"
echo ""
