#!/bin/bash

# Скрипт для тестирования API

BASE_URL="${BASE_URL:-http://localhost:8080}"

echo "=== LLM Chat Server API Tests ==="
echo "Base URL: $BASE_URL"
echo ""

# Test 1: Status check
echo "1. Checking server status..."
curl -s "$BASE_URL/status" | jq .
echo ""

# Test 2: Simple chat
echo "2. Sending a simple message..."
RESPONSE=$(curl -s -X POST "$BASE_URL/chat" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello! Tell me a short joke."}')
echo "$RESPONSE" | jq .
SESSION_ID=$(echo "$RESPONSE" | jq -r '.sessionId')
echo ""

# Test 3: Continue conversation
echo "3. Continuing conversation (session: $SESSION_ID)..."
curl -s -X POST "$BASE_URL/chat" \
  -H "Content-Type: application/json" \
  -d "{\"message\": \"Tell me another one\", \"sessionId\": \"$SESSION_ID\"}" | jq .
echo ""

# Test 4: List sessions
echo "4. Listing active sessions..."
curl -s "$BASE_URL/sessions" | jq .
echo ""

# Test 5: Clear session
echo "5. Clearing session $SESSION_ID..."
curl -s -X DELETE "$BASE_URL/session/$SESSION_ID" | jq .
echo ""

# Test 6: Verify session is cleared
echo "6. Verifying session was cleared..."
curl -s "$BASE_URL/sessions" | jq .
echo ""

echo "=== Tests completed ==="
