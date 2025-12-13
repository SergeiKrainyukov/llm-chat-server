package models

import kotlinx.serialization.Serializable

@Serializable
data class ChatMessage(
    val role: String,
    val content: String
)

@Serializable
data class ChatRequest(
    val model: String,
    val messages: List<ChatMessage>,
    val stream: Boolean = false
)

@Serializable
data class ChatResponse(
    val model: String = "",
    val message: ChatMessage = ChatMessage("assistant", ""),
    val done: Boolean = false
)

// API Models for REST endpoints
@Serializable
data class ApiChatRequest(
    val message: String,
    val sessionId: String? = null
)

@Serializable
data class ApiChatResponse(
    val response: String,
    val sessionId: String
)

@Serializable
data class ApiStatusResponse(
    val status: String,
    val ollamaHost: String,
    val model: String
)

@Serializable
data class ApiErrorResponse(
    val error: String
)
