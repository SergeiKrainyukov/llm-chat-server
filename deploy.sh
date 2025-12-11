#!/bin/bash

# Конфигурация
REMOTE_USER="your_user"
REMOTE_HOST="your_server_ip"
REMOTE_PATH="/path/to/llm-chat-server"
LOCAL_PATH="/Users/sergeikrainyukov/Desktop/llm-chat-server"

echo "🚀 Deploying LLM Chat Server to $REMOTE_HOST..."

# 1. Синхронизация файлов
echo "📦 Syncing files..."
rsync -avz --exclude 'build/' --exclude '.gradle/' --exclude 'server.log' \
  "$LOCAL_PATH/" \
  "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/"

if [ $? -ne 0 ]; then
    echo "❌ Failed to sync files"
    exit 1
fi

# 2. Деплой на сервере
echo "🔧 Building and restarting on server..."
ssh "$REMOTE_USER@$REMOTE_HOST" << 'EOF'
cd /path/to/llm-chat-server

# Остановить старый процесс
echo "Stopping old server..."
lsof -ti :8080 | xargs kill -9 2>/dev/null || true
sleep 2

# Пересобрать проект
echo "Building project..."
./gradlew build --no-daemon -q

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

# Запустить сервер
echo "Starting server..."
nohup ./run-local.sh > server.log 2>&1 &
sleep 5

# Проверить статус
if lsof -ti :8080 > /dev/null; then
    echo "✅ Server started successfully"
    curl -s http://localhost:8080/status
else
    echo "❌ Server failed to start"
    tail -20 server.log
    exit 1
fi
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deployment successful!"
    echo "🌐 Server URL: http://$REMOTE_HOST:8080"
else
    echo "❌ Deployment failed"
    exit 1
fi
