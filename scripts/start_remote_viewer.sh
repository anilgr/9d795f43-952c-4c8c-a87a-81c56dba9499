#!/usr/bin/env bash


DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/tmp/maestro_viewer_logs"
mkdir -p "$LOG_DIR"

echo "🛑 Cleaning up old viewer, proxy, and cloudflared processes..."
pkill -f "maestro mcp" || true
pkill -f "sleep infinity" || true
lsof -ti :8081 | xargs kill -9 2>/dev/null || true
lsof -ti :8082 | xargs kill -9 2>/dev/null || true
pkill -f "cloudflared tunnel --url http://localhost:8082" || true

echo "🚀 Launching maestro mcp (Viewer Port 8081)..."
nohup bash -c 'sleep 999999 | exec maestro mcp --viewer-port=8081' > "$LOG_DIR/mcp.log" 2>&1 &
MCP_PID=$!

echo "⏳ Waiting for Maestro Viewer on port 8081..."
VIEWER_UP=false
for i in {1..30}; do
  if lsof -ti :8081 > /dev/null 2>&1; then
    VIEWER_UP=true
    echo "✅ Viewer is up on port 8081"
    break
  fi
  sleep 1
done

if [ "$VIEWER_UP" = false ]; then
  echo "❌ Maestro Viewer failed to start. Log:"
  cat "$LOG_DIR/mcp.log"
  exit 1
fi

echo "🔄 Starting Unified Proxy Server on port 8082..."
VIEWER_PORT="8081" PROXY_PORT="8082" nohup node "$DIR/viewer_proxy.js" > "$LOG_DIR/proxy.log" 2>&1 &
sleep 2

echo "🌐 Starting Cloudflare Tunnel on port 8082..."
nohup npx -y cloudflared tunnel --url http://localhost:8082 > "$LOG_DIR/cf.log" 2>&1 &

echo "⏳ Waiting for public Cloudflare URL (up to 60s)..."
PUBLIC_URL=""
for i in {1..60}; do
  PUBLIC_URL=$(grep -oE 'https://[a-zA-Z0-9_-]+\.trycloudflare\.com' "$LOG_DIR/cf.log" 2>/dev/null | tail -n 1)
  if [ -n "$PUBLIC_URL" ]; then
    echo ""
    break
  fi
  printf "."
  sleep 1
done

echo "=========================================================="
if [ -n "$PUBLIC_URL" ]; then
  echo "✅ MAESTRO REMOTE VIEWER READY:"
  echo "$PUBLIC_URL"
else
  echo "⚠️ Could not auto-detect Cloudflare URL in time. Check $LOG_DIR/cf.log:"
  tail -n 5 "$LOG_DIR/cf.log"
fi
echo "=========================================================="
echo "📝 Logs directory: $LOG_DIR"
