# Quick Start Guide

## Запуск сервера локально

1. Убедитесь, что Ollama запущен:
```bash
ollama serve
```

2. Скачайте модель (если еще не скачали):
```bash
ollama pull tinyllama
```

3. Запустите сервер:
```bash
./run-local.sh
```

Сервер запустится на `http://localhost:8080`

## Примеры запросов

### Простой чат
```bash
curl -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Привет! Как дела?"}'
```

### Чат с сохранением контекста
```bash
# Первое сообщение - получите sessionId
curl -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Меня зовут Сергей"}'

# Ответ будет содержать sessionId, например:
# {"response":"Приятно познакомиться, Сергей!","sessionId":"abc-123"}

# Используйте sessionId для следующих сообщений
curl -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Как меня зовут?", "sessionId": "abc-123"}'
```

### Автоматическое тестирование
```bash
./test-api.sh
```

## Настройка

Переменные окружения:

```bash
export SERVER_PORT=8080                    # Порт сервера
export OLLAMA_MODEL=tinyllama              # Модель LLM
export OLLAMA_HOST=http://localhost:11434  # Адрес Ollama
```

## Docker

```bash
# Запустить Ollama
docker-compose up -d ollama

# Скачать модель
docker exec -it ollama ollama pull tinyllama

# Запустить сервер
docker-compose up -d chat-server

# Проверить
curl http://localhost:8080/status
```

## Управление сессиями

### Посмотреть все активные сессии
```bash
curl http://localhost:8080/sessions
```

### Очистить историю сессии
```bash
curl -X DELETE http://localhost:8080/session/YOUR-SESSION-ID
```

## Остановка сервера

Локальный режим: `Ctrl+C`

Docker: `docker-compose down`

## Troubleshooting

**Ошибка подключения к Ollama:**
- Проверьте, что Ollama запущен: `ollama serve`
- Проверьте доступность: `curl http://localhost:11434/api/tags`

**Порт уже занят:**
```bash
export SERVER_PORT=9090
./run-local.sh
```
