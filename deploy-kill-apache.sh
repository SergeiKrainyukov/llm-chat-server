#!/bin/bash

SERVER_USER="root"
SERVER_IP="45.144.30.160"
SERVER_PATH="/llm-chat-server"

echo "🛑 Stopping Apache completely..."
ssh $SERVER_USER@$SERVER_IP "sudo systemctl stop apache2 2>/dev/null || true; sudo systemctl disable apache2 2>/dev/null || true; lsof -ti :8080 | xargs kill -9 2>/dev/null || true; sleep 2"

echo "📦 Syncing files..."
rsync -avz --exclude 'build/' --exclude '.gradle/' . $SERVER_USER@$SERVER_IP:$SERVER_PATH/

echo "🔧 Building and starting server..."
ssh $SERVER_USER@$SERVER_IP "cd $SERVER_PATH && ./gradlew build -q && nohup ./run-local.sh > server.log 2>&1 &"

echo "⏳ Waiting for server to start..."
sleep 8

echo "✅ Checking server status..."
ssh $SERVER_USER@$SERVER_IP "curl -s http://localhost:8080/status || tail -20 /llm-chat-server/server.log"

echo ""
echo "🌐 Server should be available at: http://$SERVER_IP:8080"
