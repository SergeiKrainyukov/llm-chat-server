FROM gradle:8.5-jdk17 AS builder
WORKDIR /app
COPY . .
RUN gradle jar --no-daemon

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /app/build/libs/llm-chat-server-1.0.0.jar app.jar

# Expose default server port
EXPOSE 8080

CMD ["java", "-jar", "app.jar"]
