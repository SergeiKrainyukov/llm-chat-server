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
                    """.trimIndent(),
                    ContentType.Text.Plain
                )
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
