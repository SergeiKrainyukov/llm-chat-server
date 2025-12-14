package client

import config.AppConfig
import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.engine.cio.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.json.Json
import models.ChatMessage
import models.ChatRequest
import models.ChatResponse

class OllamaClient {
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    private val client = HttpClient(CIO) {
        install(ContentNegotiation) {
            json(json)
        }
        engine {
            requestTimeout = 300_000 // 5 минут на ответ
        }
    }

    private val chatHistory = mutableListOf<ChatMessage>()
    
    init {
        // Добавляем системный промпт если есть
        if (AppConfig.systemPrompt.isNotBlank()) {
            chatHistory.add(ChatMessage("system", AppConfig.systemPrompt))
        }
    }
    
    suspend fun chat(userMessage: String): String {
        chatHistory.add(ChatMessage("user", userMessage))

        val request = ChatRequest(
            model = AppConfig.modelName,
            messages = chatHistory.toList(),
            stream = false
        )

        return try {
            val httpResponse: HttpResponse = client.post("${AppConfig.ollamaHost}/api/chat") {
                contentType(ContentType.Application.Json)
                setBody(request)
            }

            // Ollama возвращает NDJSON даже с stream=false, читаем как текст
            val responseText = httpResponse.bodyAsText()

            if (responseText.isBlank()) {
                throw Exception("Empty response from Ollama")
            }

            // Парсим все строки и собираем контент
            val lines = responseText.trim().lines().filter { it.isNotBlank() }
            val fullContent = StringBuilder()

            for (line in lines) {
                try {
                    val response = json.decodeFromString<ChatResponse>(line)
                    if (response.message.content.isNotEmpty()) {
                        fullContent.append(response.message.content)
                    }
                } catch (parseError: Exception) {
                    // Пропускаем строки которые не парсятся
                    println("[WARN] Failed to parse line: ${line.take(100)}")
                    continue
                }
            }

            val content = fullContent.toString()
            if (content.isBlank()) {
                throw Exception("No content in Ollama response. Raw response: ${responseText.take(200)}")
            }

            val assistantMessage = ChatMessage("assistant", content)
            chatHistory.add(assistantMessage)
            content
        } catch (e: Exception) {
            chatHistory.removeLast() // Убираем неудачный запрос
            e.printStackTrace()
            "Error: ${e.message}"
        }
    }
    
    fun clearHistory() {
        chatHistory.clear()
        if (AppConfig.systemPrompt.isNotBlank()) {
            chatHistory.add(ChatMessage("system", AppConfig.systemPrompt))
        }
    }
    
    fun close() {
        client.close()
    }
}
