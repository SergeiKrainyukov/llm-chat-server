package config

object AppConfig {
    // Server settings
    val serverPort: Int = System.getenv("SERVER_PORT")?.toIntOrNull() ?: 8080
    val serverHost: String = System.getenv("SERVER_HOST") ?: "0.0.0.0"

    // Ollama настройки - легко менять для разных окружений
    val ollamaHost: String = System.getenv("OLLAMA_HOST") ?: "http://localhost:11434"
    val modelName: String = System.getenv("OLLAMA_MODEL") ?: "gemma2:2b"

    // Системный промпт (опционально)
    val systemPrompt: String = System.getenv("SYSTEM_PROMPT")
        ?: "You are a helpful assistant. Answer concisely."
}
