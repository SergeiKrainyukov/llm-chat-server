# LLM Chat Server

REST API сервер для взаимодействия с локальной LLM через Ollama. Поддерживает сессии и удобное управление через HTTP запросы.

## Требования

- JDK 17+
- [Ollama](https://ollama.ai/) установлен и запущен

## Быстрый старт (локально)

```bash
# 1. Запусти Ollama (если ещё не запущен)
ollama serve

# 2. Скачай модель (tinyllama - маленькая и быстрая)
ollama pull tinyllama

# 3. Запусти сервер
chmod +x run-local.sh
./run-local.sh
```

### Веб-интерфейс

Откройте файл `chat-ui.html` в браузере для удобного общения с моделью через графический интерфейс:

```bash
# Mac/Linux
open chat-ui.html

# Windows
start chat-ui.html

# Или просто откройте файл двойным кликом
```

Возможности UI:
- 💬 Красивый интерфейс чата
- 💾 Автоматическое сохранение истории диалога
- 🔄 Переключение между серверами
- 🗑 Очистка истории
- ⚡ Быстрый отклик

## API Endpoints

После запуска сервер доступен на `http://localhost:8080`

### Отправить сообщение
```bash
curl -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Привет!"}'
```

Ответ:
```json
{
  "response": "Привет! Чем могу помочь?",
  "sessionId": "abc-123-def"
}
```

### Продолжить диалог (с сохранением истории)
```bash
curl -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Расскажи анекдот", "sessionId": "abc-123-def"}'
```

### Проверить статус сервера
```bash
curl http://localhost:8080/status
```

### Список активных сессий
```bash
curl http://localhost:8080/sessions
```

### Очистить историю сессии
```bash
curl -X DELETE http://localhost:8080/session/abc-123-def
```

## Настройка

Через переменные окружения:

```bash
export SERVER_PORT="8080"                     # Порт сервера
export SERVER_HOST="0.0.0.0"                  # Хост сервера
export OLLAMA_HOST="http://localhost:11434"  # Адрес Ollama
export OLLAMA_MODEL="tinyllama"               # Модель (tinyllama, qwen3:4b, llama3.2, etc)
export SYSTEM_PROMPT="You are a helpful assistant."
```

### Рекомендуемые модели

| Модель | Размер | RAM | Качество | Описание |
|--------|--------|-----|----------|----------|
| `qwen2.5:3b` | ~2GB | ~3GB | ⭐⭐⭐⭐⭐ | **По умолчанию** - очень умная! |
| `phi3:mini` | ~2.3GB | ~3GB | ⭐⭐⭐⭐ | Microsoft, отличное качество |
| `gemma2:2b` | ~1.6GB | ~2.5GB | ⭐⭐⭐⭐ | Google, быстрая и умная |
| `llama3.2:3b` | ~2GB | ~3GB | ⭐⭐⭐⭐ | Meta, хороший баланс |
| `tinyllama` | ~600MB | ~1GB | ⭐⭐ | Самая быстрая, но простая |

### Смена модели

```bash
# Быстрая смена модели
./change-model.sh

# Или вручную на сервере
ssh root@server
ollama pull qwen2.5:3b
export OLLAMA_MODEL="qwen2.5:3b"
# Перезапустить сервер
```

## Деплой на сервер

### Быстрое обновление (Recommended)

1. **Настройте `quick-deploy.sh`:**
```bash
# Отредактируйте переменные в файле
SERVER_USER="your_user"
SERVER_IP="192.168.1.100"
SERVER_PATH="/home/your_user/llm-chat-server"
```

2. **Запустите деплой:**
```bash
./quick-deploy.sh
```

Скрипт автоматически:
- Синхронизирует файлы на сервер
- Останавливает старый процесс
- Пересобирает проект
- Запускает новую версию
- Проверяет статус

### Вариант 1: JAR файл

```bash
# Собрать JAR
./gradlew jar

# Скопировать на сервер
scp build/libs/llm-chat-server-1.0.0.jar user@server:~/

# На сервере
chmod +x run-server.sh
./run-server.sh
```

### Вариант 2: Ручной деплой

```bash
# Копирование файлов
rsync -avz --exclude 'build/' . user@server:/path/to/llm-chat-server/

# На сервере
ssh user@server
cd /path/to/llm-chat-server
lsof -ti :8080 | xargs kill -9
./gradlew build --no-daemon
nohup ./run-local.sh > server.log 2>&1 &
```

### Вариант 2: Docker Compose (рекомендуется)

```bash
# Запуск Ollama
docker-compose up -d ollama

# Подожди пока Ollama запустится (5-10 секунд), затем скачай модель
docker exec -it ollama ollama pull tinyllama

# Запуск сервера
docker-compose up -d chat-server

# Проверка статуса
curl http://localhost:8080/status

# Просмотр логов
docker-compose logs -f chat-server
```

## Примеры использования

### Простой запрос
```bash
curl -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Что такое Kotlin?"}'
```

### Диалог с сохранением контекста
```bash
# Первый запрос
SESSION=$(curl -s -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Привет! Меня зовут Иван"}' | jq -r '.sessionId')

# Второй запрос в той же сессии
curl -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d "{\"message\": \"Как меня зовут?\", \"sessionId\": \"$SESSION\"}"
```

## Структура проекта

```
llm-chat-server/
├── src/main/kotlin/
│   ├── Main.kt           # Ktor Server + REST API
│   ├── config/           # Конфигурация (порт, Ollama, модель)
│   ├── client/           # HTTP клиент для Ollama
│   ├── session/          # Менеджер сессий чата
│   └── models/           # Data классы (запросы/ответы)
├── build.gradle.kts
├── docker-compose.yml
├── Dockerfile
├── run-local.sh          # Локальный запуск
└── run-server.sh         # Серверный запуск
```

## Использование с удаленного сервера

После развертывания на сервере, вы можете отправлять запросы через curl или любой HTTP клиент:

```bash
# Замените YOUR_SERVER_IP на IP вашего сервера
SERVER_IP="192.168.1.100"

# Отправить сообщение
curl -X POST http://$SERVER_IP:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from remote!"}'

# Проверить статус
curl http://$SERVER_IP:8080/status
```

### Интеграция с Python

```python
import requests

SERVER_URL = "http://localhost:8080"

def chat(message, session_id=None):
    payload = {"message": message}
    if session_id:
        payload["sessionId"] = session_id

    response = requests.post(f"{SERVER_URL}/chat", json=payload)
    return response.json()

# Использование
result = chat("Привет!")
print(result["response"])

# Продолжить диалог
session_id = result["sessionId"]
result = chat("Расскажи шутку", session_id)
print(result["response"])
```

### Интеграция с JavaScript/Node.js

```javascript
const axios = require('axios');

const SERVER_URL = 'http://localhost:8080';

async function chat(message, sessionId = null) {
    const payload = { message };
    if (sessionId) payload.sessionId = sessionId;

    const response = await axios.post(`${SERVER_URL}/chat`, payload);
    return response.data;
}

// Использование
(async () => {
    const result = await chat('Привет!');
    console.log(result.response);

    const result2 = await chat('Расскажи анекдот', result.sessionId);
    console.log(result2.response);
})();
```

## Troubleshooting

**Ollama не отвечает:**
```bash
# Проверь статус
curl http://localhost:11434/api/tags

# Перезапусти
ollama serve
```

**Модель не найдена:**
```bash
ollama pull tinyllama
```

**Сервер не отвечает:**
```bash
# Проверь, что сервер запущен
curl http://localhost:8080/status

# Проверь логи (если Docker)
docker-compose logs chat-server

# Проверь, что порт не занят
lsof -i :8080
```
