#!/bin/bash

# ---------------- CONFIG ---------------- #
PROJECT_ROOT="$HOME/Projects/AdminButler"
FLUTTER_DIR="$PROJECT_ROOT/admin_butler_flutter"
SERVER_DIR="$PROJECT_ROOT/admin_butler_server"
DB_PASSWORD="mysecretpassword"
REDIS_PASSWORD="mysecretpassword"
FLUTTER_PORT=8088
# GEMINI_API_KEY must be passed via environment variable
# ---------------------------------------- #

# Make sure GEMINI_API_KEY is set
if [ -z "$GEMINI_API_KEY" ]; then
  echo "❌ GEMINI_API_KEY environment variable not set. Exiting."
  exit 1
fi

echo "🟢 Starting AdminButler App..."

# ---------------- Step 1: Docker ---------------- #
echo "🚀 Starting Docker containers..."
cd "$SERVER_DIR" || { echo "❌ Server directory not found!"; exit 1; }

# Ensure config folder exists
mkdir -p config

# Update passwords.yaml
printf "development:\n  database: '$DB_PASSWORD'\n  redis: '$REDIS_PASSWORD'\n" > config/passwords.yaml

# Update docker-compose.yaml with Redis password if missing
if ! grep -q "requirepass" docker-compose.yaml; then
    echo "⚙️ Adding Redis password to docker-compose.yaml..."
    sed -i "/image: redis:/a\    command: redis-server --requirepass \"$REDIS_PASSWORD\"" docker-compose.yaml
fi

# Start containers
docker-compose up --build --detach

# ---------------- Step 2: Configure Gemini API key ---------------- #
ENV_FILE="$SERVER_DIR/config/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "🔑 Configuring Gemini API key..."
    printf "GEMINI_API_KEY=\"$GEMINI_API_KEY\"\n" > "$ENV_FILE"
fi

# ---------------- Step 3: Start Serverpod backend ---------------- #
echo "🔧 Starting Serverpod backend..."
nohup dart bin/main.dart > server.log 2>&1 &

# ---------------- Step 4: Wait for backend to be ready ---------------- #
echo "⏳ Waiting for backend to be ready..."
while :; do
  powershell.exe -Command "
    try {
      \$tcp = New-Object System.Net.Sockets.TcpClient('localhost', 8085);
      \$tcp.Close();
      exit 0
    } catch { exit 1 }
  "
  if [ $? -eq 0 ]; then
    break
  fi
  echo "⏳ Waiting for backend port 8085..."
  sleep 2
done
echo "✅ Backend ready!"

# ---------------- Step 5: Start Flutter frontend ---------------- #
echo "📱 Starting Flutter frontend on port $FLUTTER_PORT..."

cd "$FLUTTER_DIR" || { echo "❌ Flutter directory not found!"; exit 1; }

# Fetch dependencies
flutter pub get

# Kill old Chrome debug sessions to avoid WebSocket issues on Windows
echo "💀 Killing old Chrome debug sessions..."
taskkill /IM chrome.exe /F > /dev/null 2>&1 || true

# Launch Flutter frontend
flutter run -d chrome --web-port "$FLUTTER_PORT"
