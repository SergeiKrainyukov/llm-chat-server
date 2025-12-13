import config.AppConfig
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import io.ktor.server.application.*
import io.ktor.server.engine.*
import io.ktor.server.netty.*
import io.ktor.server.plugins.contentnegotiation.*
import io.ktor.server.plugins.cors.routing.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.json.Json
import models.*
import session.ChatSessionManager
import java.io.File

fun main() {
    val sessionManager = ChatSessionManager()

    embeddedServer(Netty, port = AppConfig.serverPort, host = AppConfig.serverHost) {
        install(ContentNegotiation) {
            json(Json {
                prettyPrint = true
                isLenient = true
                ignoreUnknownKeys = true
            })
        }

        install(CORS) {
            anyHost()
            allowMethod(HttpMethod.Options)
            allowMethod(HttpMethod.Post)
            allowMethod(HttpMethod.Get)
            allowMethod(HttpMethod.Delete)
            allowHeader(HttpHeaders.ContentType)
        }

        routing {
            get("/") {
                call.respondText(
                    """
                    LLM Chat Server

                    Endpoints:
                    - POST /chat - Send a message
                    - DELETE /session/{id} - Clear session history
                    - GET /sessions - List all active sessions
                    - GET /status - Server status
                    - GET /analytics/data - Get user analytics data
                    - POST /analytics/chat - Chat with analytics context
                    - GET /chat-ui.html - Web UI
                    """.trimIndent(),
                    ContentType.Text.Plain
                )
            }

            get("/chat-ui.html") {
                val file = File("chat-ui.html")
                if (file.exists()) {
                    call.respondFile(file)
                } else {
                    call.respond(HttpStatusCode.NotFound, "UI file not found")
                }
            }

            get("/status") {
                call.respond(
                    ApiStatusResponse(
                        status = "running",
                        ollamaHost = AppConfig.ollamaHost,
                        model = AppConfig.modelName
                    )
                )
            }

            post("/chat") {
                try {
                    val request = call.receive<ApiChatRequest>()
                    val (sessionId, client) = sessionManager.getOrCreateSession(request.sessionId)

                    val response = client.chat(request.message)

                    call.respond(
                        ApiChatResponse(
                            response = response,
                            sessionId = sessionId
                        )
                    )
                } catch (e: Exception) {
                    call.respond(
                        HttpStatusCode.InternalServerError,
                        ApiErrorResponse(error = e.message ?: "Unknown error")
                    )
                }
            }

            delete("/session/{id}") {
                val sessionId = call.parameters["id"]
                if (sessionId == null) {
                    call.respond(
                        HttpStatusCode.BadRequest,
                        ApiErrorResponse(error = "Session ID required")
                    )
                    return@delete
                }

                val removed = sessionManager.clearSession(sessionId)
                if (removed) {
                    call.respond(mapOf("status" to "Session cleared"))
                } else {
                    call.respond(
                        HttpStatusCode.NotFound,
                        ApiErrorResponse(error = "Session not found")
                    )
                }
            }

            get("/sessions") {
                call.respond(mapOf("sessions" to sessionManager.getAllSessionIds()))
            }

            // Analytics endpoints
            get("/analytics/data") {
                try {
                    val resourceStream = this::class.java.classLoader.getResourceAsStream("users_data.json")
                    if (resourceStream != null) {
                        val jsonData = resourceStream.bufferedReader().use { it.readText() }
                        call.respondText(jsonData, ContentType.Application.Json)
                    } else {
                        call.respond(
                            HttpStatusCode.NotFound,
                            ApiErrorResponse(error = "Users data file not found")
                        )
                    }
                } catch (e: Exception) {
                    call.respond(
                        HttpStatusCode.InternalServerError,
                        ApiErrorResponse(error = e.message ?: "Error reading analytics data")
                    )
                }
            }

            post("/analytics/chat") {
                try {
                    val request = call.receive<ApiChatRequest>()
                    val (sessionId, client) = sessionManager.getOrCreateSession(request.sessionId)

                    // Load user data
                    val resourceStream = this::class.java.classLoader.getResourceAsStream("users_data.json")
                    val userData = if (resourceStream != null) {
                        resourceStream.bufferedReader().use { it.readText() }
                    } else {
                        "{}"
                    }

                    // Create analytics context prompt
                    val contextMessage = """
                        Ты - аналитик данных. У тебя есть доступ к следующим данным о пользователях:

                        $userData

                        Пользователь задает вопрос: ${request.message}

                        Проанализируй данные и предоставь детальный ответ на русском языке.
                        Используй конкретные цифры и статистику из данных.
                    """.trimIndent()

                    val response = client.chat(contextMessage)

                    call.respond(
                        ApiChatResponse(
                            response = response,
                            sessionId = sessionId
                        )
                    )
                } catch (e: Exception) {
                    call.respond(
                        HttpStatusCode.InternalServerError,
                        ApiErrorResponse(error = e.message ?: "Unknown error")
                    )
                }
            }
        }

        println("╔════════════════════════════════════════╗")
        println("║       LLM Chat Server (Ollama)         ║")
        println("╚════════════════════════════════════════╝")
        println()
        println("Server: http://${AppConfig.serverHost}:${AppConfig.serverPort}")
        println("Model: ${AppConfig.modelName}")
        println("Ollama: ${AppConfig.ollamaHost}")
        println()
        println("Ready to accept requests...")
        println()

    }.start(wait = true)
}
