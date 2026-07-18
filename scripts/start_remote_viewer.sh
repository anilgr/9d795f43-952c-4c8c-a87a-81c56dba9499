#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/tmp/maestro_viewer_logs"
mkdir -p "$LOG_DIR"

echo "🛑 Cleaning up old viewer, proxy, and cloudflared processes..."
pkill -f "maestro mcp" || true
lsof -ti :8081 | xargs kill -9 2>/dev/null || true
lsof -ti :8082 | xargs kill -9 2>/dev/null || true
pkill -f "cloudflared tunnel --url http://localhost:8082" || true

echo "🚀 Launching maestro mcp (Viewer Port 8081)..."
nohup maestro mcp --viewer-port=8081 > "$LOG_DIR/mcp.log" 2>&1 &

echo "⏳ Waiting for Maestro Viewer and MJPEG stream port detection..."
STREAM_PORT="52402"
for i in {1..15}; do
  if grep -q "stream_ready" "$LOG_DIR/mcp.log" 2>/dev/null; then
    STREAM_PORT=$(grep -o 'stream_ready http://127.0.0.1:[0-9]*' "$LOG_DIR/mcp.log" | awk -F: '{print $3}' | tail -n 1)
    if [ -n "$STREAM_PORT" ]; then
      echo "🎯 Detected active MJPEG stream port: $STREAM_PORT"
      break
    fi
  fi
  sleep 1
done

echo "🔄 Starting Unified Proxy Server on port 8082..."
STREAM_PORT="$STREAM_PORT" VIEWER_PORT="8081" PROXY_PORT="8082" nohup node "$DIR/viewer_proxy.js" > "$LOG_DIR/proxy.log" 2>&1 &
sleep 2

echo "🌐 Starting Cloudflare Tunnel on port 8082..."
nohup npx -y cloudflared tunnel --url http://localhost:8082 > "$LOG_DIR/cf.log" 2>&1 &

echo "⏳ Waiting for public Cloudflare URL..."
PUBLIC_URL=""
for i in {1..15}; do
  PUBLIC_URL=$(grep -o 'https://[^"]*\.trycloudflare\.com' "$LOG_DIR/cf.log" 2>/dev/null | tail -n 1)
  if [ -n "$PUBLIC_URL" ]; then
    break
  fi
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
