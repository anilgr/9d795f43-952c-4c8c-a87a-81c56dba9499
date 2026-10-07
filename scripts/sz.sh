#!/usr/bin/env bash
set -eo pipefail

if [ -z "$1" ]; then
  echo "Usage: sz.sh <file_path>"
  echo "Example: sz.sh /tmp/android_build.log"
  echo "Uploads any file from the runner and generates an instant HTTPS download link."
  exit 1
fi

file="$1"

if [ ! -f "$file" ]; then
  echo "❌ Error: File '$file' does not exist!"
  exit 1
fi

filesize=$(du -h "$file" | cut -f1)
filename=$(basename "$file")

echo "📦 Preparing: $filename ($filesize)..."
echo "🚀 Generating secure web download link..."

# Upload to temp.sh for fast, direct download link (bypasses browser WebSocket download blocks)
download_url=$(curl -s -F "file=@$file" https://temp.sh/upload || true)

echo "=========================================================="
if [ -n "$download_url" ]; then
  echo "📥 DOWNLOAD LINK:"
  echo "$download_url"
else
  echo "⚠️ Cloud upload failed. File remains locally at: $file"
fi
echo "=========================================================="

# Also attempt Zmodem with a safe 5s timeout if the browser has it enabled
if command -v sz > /dev/null 2>&1; then
  echo "👉 Also attempting Zmodem download (timeout: 5s)..."
  sz -e -b -t 50 "$file" 2>/dev/null || true
fi
