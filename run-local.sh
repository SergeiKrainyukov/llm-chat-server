#!/bin/bash

# Локальный запуск - использует дефолтные настройки
# Ollama должен быть запущен: ollama serve

echo "Starting LLM Chat Server (local mode)..."
echo ""

# Можно переопределить настройки:
export SERVER_PORT="${SERVER_PORT:-8080}"
export SERVER_HOST="${SERVER_HOST:-0.0.0.0}"
export OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
export OLLAMA_MODEL="${OLLAMA_MODEL:-qwen2.5:3b}"
export SYSTEM_PROMPT="${SYSTEM_PROMPT:-You are a helpful assistant.}"

echo "Configuration:"
echo "  Server: http://$SERVER_HOST:$SERVER_PORT"
echo "  Ollama: $OLLAMA_HOST"
echo "  Model: $OLLAMA_MODEL"
echo ""

./gradlew run --console=plain -q
