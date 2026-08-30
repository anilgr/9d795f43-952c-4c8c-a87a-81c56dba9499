#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Starting ZMODEM transfer. Please send '.env' and 'app_store_key.p8' now..."
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

mv app_store_key.p8 fastlane/app_store_key.p8

echo "Uploads complete. Detaching build process to the background..."
echo "You can safely close this terminal now. Monitor progress with: tail -f /tmp/ios_build.log"

{
  echo "Installing JS dependencies and Pods..."
  yarn install
  npx expo prebuild -p ios
  npx pod-install ios

  echo "Copying fastlane folder into ios directory..."
  mkdir -p ios/fastlane
  cp -R fastlane/. ios/fastlane/

  echo "Navigating into ios..."
  cd ios

  echo "Starting iOS build process..."

  # Fix Windows CRLF line endings in the .env file just in case
  tr '\r' '\n' < fastlane/.env > fastlane/.env.tmp
  mv fastlane/.env.tmp fastlane/.env

  # Explicitly source the .env file to guarantee Fastlane sees the variables
  set -a
  source fastlane/.env
  set +a


  # Build the IPA
  bundle exec fastlane build_ipa auth_key:"fastlane/app_store_key.p8" output_directory:"./build" output_name:"app.ipa"

  echo "Build complete. Starting upload..."

  # Upload the IPA to App Store Connect
  bundle exec fastlane upload_ipa auth_key:"fastlane/app_store_key.p8" ipa:"./build/app.ipa"

  echo "Upload complete!"
} > /tmp/ios_build.log 2>&1 &

disown
