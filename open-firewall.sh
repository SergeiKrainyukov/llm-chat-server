#!/bin/bash

SERVER_USER="root"
SERVER_IP="45.144.30.160"
PORT="8080"

echo "🔓 Opening port $PORT on server..."

ssh $SERVER_USER@$SERVER_IP << EOF
# Открыть порт в UFW
ufw allow $PORT/tcp 2>/dev/null || true

# Открыть порт в iptables (на случай если UFW не установлен)
iptables -A INPUT -p tcp --dport $PORT -j ACCEPT 2>/dev/null || true

# Сохранить правила iptables
iptables-save > /etc/iptables/rules.v4 2>/dev/null || true

# Проверить статус
echo ""
echo "Firewall status:"
ufw status 2>/dev/null || iptables -L INPUT -n | grep $PORT || echo "Port should be open"
EOF

echo ""
echo "✅ Firewall configured!"
echo "Testing connection..."

sleep 2
curl -s http://$SERVER_IP:$PORT/status && echo "" && echo "🎉 Server is accessible!" || echo "❌ Still can't connect. Check cloud provider firewall settings."
