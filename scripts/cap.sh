#!/usr/bin/env bash
set -eo pipefail

file="${1:-/tmp/sim_cap.png}"
echo "📸 Capturing iOS simulator screenshot to $file..."

# 1. Verify a booted simulator exists
if ! xcrun simctl list devices booted | grep -q "Booted"; then
  echo "❌ Error: No booted iOS simulator found! Boot one first with 'boot_ios_sim.sh'."
  exit 1
fi

# 2. Wake Simulator app so it renders an active frame (prevents CoreSimulator display hang)
open -a Simulator 2>/dev/null || true
osascript -e 'tell application "Simulator" to activate' 2>/dev/null || true

# 3. Take screenshot with --mask=ignored and 10s watchdog timeout
rm -f "$file"
( xcrun simctl io booted screenshot --mask=ignored --type=png "$file" ) &
pid=$!

for i in {1..10}; do
  if ! kill -0 $pid 2>/dev/null; then
    break
  fi
  sleep 1
done

if kill -0 $pid 2>/dev/null; then
  echo "⚠️ 'xcrun simctl io screenshot' timed out after 10s. Forcing kill..."
  kill -9 $pid 2>/dev/null || true
  exit 1
fi

if [ ! -s "$file" ]; then
  echo "❌ Screenshot failed: $file is empty or was not created."
  exit 1
fi

filesize=$(du -h "$file" | cut -f1)
echo "✅ Screenshot captured ($file, $filesize)."
echo "🚀 Generating instant web preview URL..."

# Upload to temp.sh for instant browser viewing (bypasses browser WebSocket download blocks)
preview_url=$(curl -s -F "file=@$file" https://temp.sh/upload || true)

echo "=========================================================="
if [ -n "$preview_url" ]; then
  echo "🔗 VIEW SCREENSHOT HERE:"
  echo "$preview_url"
else
  echo "⚠️ Cloud upload failed. File saved locally at: $file"
fi
echo "=========================================================="
