#!/bin/bash

# Быстрый деплой - настройте переменные под свой сервер
SERVER_USER="root"
SERVER_IP="45.144.30.160"
SERVER_PATH="/llm-chat-server"

# Один деплой одной командой
rsync -avz --exclude 'build/' --exclude '.gradle/' . $SERVER_USER@$SERVER_IP:$SERVER_PATH/ && \
ssh $SERVER_USER@$SERVER_IP "cd $SERVER_PATH && lsof -ti :8080 | xargs kill -9 2>/dev/null; sleep 2 && ./gradlew build -q && nohup ./run-local.sh > server.log 2>&1 & sleep 5 && curl http://localhost:8080/status"
