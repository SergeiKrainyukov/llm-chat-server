#!/bin/bash

SERVER_USER="root"
SERVER_IP="45.144.30.160"
SERVER_PATH="/llm-chat-server"

echo "=== LLM Chat Server Deploy (Debug Mode) ==="
echo ""

echo "Step 1: Stopping Apache..."
ssh $SERVER_USER@$SERVER_IP "systemctl stop apache2 2>/dev/null; systemctl disable apache2 2>/dev/null; lsof -ti :8080 | xargs kill -9 2>/dev/null; sleep 2"
echo "✓ Apache stopped"
echo ""

echo "Step 2: Syncing files..."
rsync -avz --exclude 'build/' --exclude '.gradle/' --exclude 'server.log' . $SERVER_USER@$SERVER_IP:$SERVER_PATH/
echo "✓ Files synced"
echo ""

echo "Step 3: Building project (this may take a minute)..."
ssh $SERVER_USER@$SERVER_IP "cd $SERVER_PATH && ./gradlew build --no-daemon 2>&1 | tail -20"
echo "✓ Build completed"
echo ""

echo "Step 4: Starting server..."
ssh $SERVER_USER@$SERVER_IP "cd $SERVER_PATH && nohup ./run-local.sh > server.log 2>&1 &"
echo "✓ Server starting..."
echo ""

echo "Step 5: Waiting 10 seconds for server to start..."
sleep 10
echo ""

echo "Step 6: Checking if server is running..."
ssh $SERVER_USER@$SERVER_IP "lsof -i :8080"
echo ""

echo "Step 7: Testing server status..."
ssh $SERVER_USER@$SERVER_IP "curl -s http://localhost:8080/status || echo 'Server not responding'"
echo ""

echo "Step 8: Showing recent logs..."
ssh $SERVER_USER@$SERVER_IP "tail -30 $SERVER_PATH/server.log"
echo ""

echo "=== Deploy Complete ==="
echo "Server URL: http://$SERVER_IP:8080"
