#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Starting ZMODEM transfer."
echo "Please send '.env', 'padaku.jks', and your Play Store JSON key (e.g. 'play_store_key.json') now..."
rz

echo "Moving received files to the fastlane folder..."
mkdir -p fastlane

# Handle cases where the terminal strips the dot and uploads it as 'env'
if [ -f "env" ]; then
  mv env fastlane/.env
elif [ -f ".env" ]; then
  mv .env fastlane/.env
else
  echo "Error: Could not find env or .env file!"
  exit 1
fi

mv padaku.jks fastlane/padaku.jks

# Find the JSON key dynamically in case it's named something slightly different
JSON_FILE=$(ls *.json 2>/dev/null | head -n 1)
if [ -n "$JSON_FILE" ]; then
  mv "$JSON_FILE" fastlane/play_store_key.json
else
  echo "Warning: No JSON key file found! Upload step will fail."
fi

echo "Copying fastlane folder into android directory..."
mkdir -p android/fastlane
cp -R fastlane/. android/fastlane/

echo "Navigating into android..."
cd android

echo "Starting Android build process..."

# Fix Windows CRLF line endings in the .env file just in case
tr '\r' '\n' < fastlane/.env > fastlane/.env.tmp
mv fastlane/.env.tmp fastlane/.env

# Explicitly source the .env file to guarantee Fastlane sees the variables
set -a
source fastlane/.env
set +a

echo "--- DEBUG INFO ---"
echo "Contents of fastlane/.env:"
cat fastlane/.env
echo "Environment Variables (grep ANDROID):"
env | grep ANDROID
echo "-------------------"

echo "Installing JS dependencies..."
cd ..
yarn install

echo "--- DEBUG NODE AUTOLINKING ---"
node -v
node --print "require.resolve('@react-native/gradle-plugin/package.json', { paths: [require.resolve('react-native/package.json')] })" || echo "NODE CMD 1 FAILED"
node --print "require.resolve('expo-modules-autolinking/package.json', { paths: [require.resolve('expo/package.json')] })" || echo "NODE CMD 2 FAILED"
echo "------------------------------"

cd android

echo "--- DEBUG GRADLE AUTOLINKING ---"
./gradlew check --info || echo "GRADLE CHECK FAILED"
echo "--------------------------------"

# Build the AAB
bundle exec fastlane android build_aab keystore_path:"fastlane/padaku.jks"

echo "Build complete. Starting upload..."

# Upload the AAB to Google Play Console
bundle exec fastlane android upload_aab json_key:"fastlane/play_store_key.json"

echo "Upload complete!"
