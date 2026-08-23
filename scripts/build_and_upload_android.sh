#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Starting ZMODEM transfer."
echo "Please send '.env', 'padaku.jks', and your Play Store JSON key (e.g. 'play_store_key.json') now..."
rz

echo "Moving received files to the Padaku/fastlane folder..."
mkdir -p Padaku/fastlane

# Handle cases where the terminal strips the dot and uploads it as 'env'
if [ -f "env" ]; then
  mv env Padaku/fastlane/.env
elif [ -f ".env" ]; then
  mv .env Padaku/fastlane/.env
else
  echo "Error: Could not find env or .env file!"
  exit 1
fi

mv padaku.jks Padaku/fastlane/padaku.jks

# Find the JSON key dynamically in case it's named something slightly different
JSON_FILE=$(ls *.json 2>/dev/null | head -n 1)
if [ -n "$JSON_FILE" ]; then
  mv "$JSON_FILE" Padaku/fastlane/play_store_key.json
else
  echo "Warning: No JSON key file found! Upload step will fail."
fi

echo "Navigating into Padaku..."
cd Padaku

echo "Copying fastlane folder into android directory..."
mkdir -p android/fastlane
cp -R fastlane/* android/fastlane/

echo "Navigating into android..."
cd android

echo "Starting Android build process..."

# Build the AAB
bundle exec fastlane android build_aab keystore_path:"fastlane/padaku.jks"

echo "Build complete. Starting upload..."

# Upload the AAB to Google Play Console
bundle exec fastlane android upload_aab json_key:"fastlane/play_store_key.json"

echo "Upload complete!"
