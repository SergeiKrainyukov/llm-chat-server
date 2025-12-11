#!/bin/bash

# Скрипт для запуска на удалённом сервере

# Настройки (измени под свой сервер)
export SERVER_PORT="${SERVER_PORT:-8080}"
export SERVER_HOST="${SERVER_HOST:-0.0.0.0}"
export OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
export OLLAMA_MODEL="${OLLAMA_MODEL:-tinyllama}"
export SYSTEM_PROMPT="${SYSTEM_PROMPT:-You are a helpful assistant.}"

echo "=== LLM Chat Server ==="
echo "Server: http://$SERVER_HOST:$SERVER_PORT"
echo "Ollama Host: $OLLAMA_HOST"
echo "Model: $OLLAMA_MODEL"
echo ""

# Запуск JAR
java -jar build/libs/llm-chat-server-1.0.0.jar
