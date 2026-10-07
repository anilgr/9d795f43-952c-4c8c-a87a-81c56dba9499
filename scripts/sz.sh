#!/usr/bin/env bash
set -eo pipefail

AUTO_DOWNLOAD=false
FILE=""

for arg in "$@"; do
  case "$arg" in
    --auto|-a|--zmodem|-z)
      AUTO_DOWNLOAD=true
      ;;
    -h|--help)
      echo "Usage: sz.sh [options] <file_path>"
      echo ""
      echo "Uploads any file from the runner and generates an instant HTTPS download link."
      echo ""
      echo "Options:"
      echo "  -a, --auto, -z, --zmodem   Attempt automatic Zmodem download into browser"
      echo "  -h, --help                 Show this help message"
      echo ""
      echo "Examples:"
      echo "  sz.sh /tmp/android_build.log            # Instant web download link"
      echo "  sz.sh --auto /tmp/android_build.log     # Web link + browser auto-download"
      exit 0
      ;;
    *)
      if [ -z "$FILE" ]; then
        FILE="$arg"
      fi
      ;;
  esac
done

if [ -z "$FILE" ]; then
  echo "Usage: sz.sh [--auto] <file_path>"
  echo "Example: sz.sh /tmp/android_build.log"
  echo "Run 'sz.sh --help' for options."
  exit 1
fi

if [ ! -f "$FILE" ]; then
  echo "❌ Error: File '$FILE' does not exist!"
  exit 1
fi

filesize=$(du -h "$FILE" | cut -f1)
filename=$(basename "$FILE")

echo "📦 Preparing: $filename ($filesize)..."
echo "🚀 Generating secure web download link..."

# Upload to temp.sh for fast, direct download link (bypasses browser WebSocket download blocks)
download_url=$(curl -s -F "file=@$FILE" https://temp.sh/upload || true)

echo "=========================================================="
if [ -n "$download_url" ]; then
  echo "📥 DOWNLOAD LINK:"
  echo "$download_url"
else
  echo "⚠️ Cloud upload failed. File remains locally at: $FILE"
fi
echo "=========================================================="

# If --auto / -a / -z flag is provided, trigger Zmodem transfer
if [ "$AUTO_DOWNLOAD" = true ]; then
  if command -v sz > /dev/null 2>&1; then
    echo "🚀 Triggering browser auto-download via Zmodem (timeout: 10s)..."
    sz -e -b -t 100 "$FILE" 2>/dev/null || {
      echo "⚠️ Zmodem auto-download timed out or was blocked by browser."
      echo "💡 You can still download using the link above."
    }
  else
    echo "⚠️ 'sz' (lrzsz) not installed. Use the download link above."
  fi
fi
