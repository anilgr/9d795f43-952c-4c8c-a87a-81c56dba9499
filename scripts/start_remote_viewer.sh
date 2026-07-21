#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$DIR/.." && pwd)"
LOG_DIR="/tmp/maestro_viewer_logs"
mkdir -p "$LOG_DIR"

# Read viewer port from mcp_config.json, fallback to 8081
MCP_CONFIG="$REPO_DIR/.agents/mcp_config.json"
if [ -f "$MCP_CONFIG" ] && command -v python3 > /dev/null 2>&1; then
  VIEWER_PORT=$(python3 -c "import json,sys;c=json.load(open(sys.argv[1]));args=c.get('mcpServers',{}).get('maestro',{}).get('args',[]);print(next((a.split('=')[1] for a in args if a.startswith('--viewer-port')), '8081'))" "$MCP_CONFIG" 2>/dev/null)
else
  VIEWER_PORT="8081"
fi

RESTART_MCP=false
for arg in "$@"; do
  case "$arg" in
    --restart-mcp) RESTART_MCP=true ;;
    --viewer-port=*) VIEWER_PORT="${arg#*=}" ;;
  esac
done

echo "📋 Using viewer port: $VIEWER_PORT"

# --- Cleanup proxy and tunnel (always) ---
echo "🛑 Cleaning up old proxy and cloudflared processes..."
lsof -ti :8082 | xargs kill -9 2>/dev/null || true
pkill -f "cloudflared tunnel --url http://localhost:8082" || true

# --- MCP Server ---
if [ "$RESTART_MCP" = true ]; then
  echo "🔄 Restarting maestro mcp..."
  pkill -f "maestro mcp" || true
  pkill -f "sleep 999999" || true
  lsof -ti :$VIEWER_PORT | xargs kill -9 2>/dev/null || true
  sleep 1
fi

if lsof -ti :$VIEWER_PORT > /dev/null 2>&1; then
  echo "✅ Maestro Viewer already running on port $VIEWER_PORT (reusing)"
else
  echo "🚀 Launching maestro mcp (Viewer Port $VIEWER_PORT)..."
  nohup bash -c "sleep 999999 | exec maestro mcp --viewer-port=$VIEWER_PORT" > "$LOG_DIR/mcp.log" 2>&1 &

  echo "⏳ Waiting for Maestro Viewer on port $VIEWER_PORT..."
  VIEWER_UP=false
  for i in {1..30}; do
    if lsof -ti :$VIEWER_PORT > /dev/null 2>&1; then
      VIEWER_UP=true
      echo "✅ Viewer is up on port $VIEWER_PORT"
      break
    fi
    sleep 1
  done

  if [ "$VIEWER_UP" = false ]; then
    echo "❌ Maestro Viewer failed to start. Log:"
    cat "$LOG_DIR/mcp.log"
    exit 1
  fi
fi

# --- Proxy ---
echo "🔄 Starting Unified Proxy Server on port 8082..."
VIEWER_PORT="$VIEWER_PORT" PROXY_PORT="8082" nohup node "$DIR/viewer_proxy.js" > "$LOG_DIR/proxy.log" 2>&1 &
sleep 2

# --- Cloudflare Tunnel ---
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
echo "💡 Use --restart-mcp to force restart the MCP server"
