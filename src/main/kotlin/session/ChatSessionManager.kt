package session

import client.OllamaClient
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

class ChatSessionManager {
    private val sessions = ConcurrentHashMap<String, OllamaClient>()

    fun getOrCreateSession(sessionId: String?): Pair<String, OllamaClient> {
        val id = sessionId ?: UUID.randomUUID().toString()
        val client = sessions.getOrPut(id) { OllamaClient() }
        return Pair(id, client)
    }

    fun clearSession(sessionId: String): Boolean {
        val client = sessions.remove(sessionId)
        client?.close()
        return client != null
    }

    fun getAllSessionIds(): List<String> {
        return sessions.keys.toList()
    }

    fun closeAll() {
        sessions.values.forEach { it.close() }
        sessions.clear()
    }
}
