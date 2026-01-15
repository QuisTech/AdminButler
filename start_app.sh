#!/bin/bash

# ---------------- CONFIG ---------------- #
PROJECT_ROOT="$HOME/Projects/AdminButler"
FLUTTER_DIR="$PROJECT_ROOT/admin_butler_flutter"
SERVER_DIR="$PROJECT_ROOT/admin_butler_server"
FLUTTER_PORT=8088
# Secrets must be provided via environment variables:
#   GEMINI_API_KEY
#   DB_PASSWORD
#   REDIS_PASSWORD
# ---------------------------------------- #

set -e

echo "🟢 Starting AdminButler App..."

# ---------------- Step 0: Validate secrets ---------------- #
for VAR in GEMINI_API_KEY DB_PASSWORD REDIS_PASSWORD; do
  if [ -z "${!VAR}" ]; then
    echo "❌ $VAR is not set. Exiting."
    exit 1
  fi
done

# ---------------- Step 1: Docker ---------------- #
echo "🚀 Starting Docker containers..."
cd "$SERVER_DIR" || { echo "❌ Server directory not found!"; exit 1; }

mkdir -p config

# Write Serverpod passwords (gitignored)
cat > config/passwords.yaml <<EOF
development:
  database: "$DB_PASSWORD"
  redis: "$REDIS_PASSWORD"
EOF

# Export Redis password for docker-compose
export REDIS_PASSWORD

docker-compose up --build --detach

# ---------------- Step 2: Gemini API key ---------------- #
ENV_FILE="$SERVER_DIR/config/.env"

cat > "$ENV_FILE" <<EOF
GEMINI_API_KEY="$GEMINI_API_KEY"
EOF

# ---------------- Step 3: Start Serverpod backend ---------------- #
echo "🔧 Starting Serverpod backend..."
nohup dart bin/main.dart > server.log 2>&1 &

# ---------------- Step 4: Wait for backend ---------------- #
echo "⏳ Waiting for backend to be ready..."
while true; do
  powershell.exe -Command "
    try {
      \$c = New-Object System.Net.Sockets.TcpClient('localhost', 8085)
      \$c.Close()
      exit 0
    } catch { exit 1 }
  " && break
  sleep 2
done
echo "✅ Backend ready!"

# ---------------- Step 5: Flutter ---------------- #
echo "📱 Starting Flutter frontend on port $FLUTTER_PORT..."
cd "$FLUTTER_DIR" || { echo "❌ Flutter directory not found!"; exit 1; }

flutter pub get

# Kill stale Chrome debug sessions (Windows fix)
taskkill /IM chrome.exe /F > /dev/null 2>&1 || true

flutter run -d chrome --web-port "$FLUTTER_PORT"
