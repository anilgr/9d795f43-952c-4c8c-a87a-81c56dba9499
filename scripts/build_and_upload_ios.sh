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

echo "Copying fastlane folder into ios directory..."
mkdir -p ios/fastlane
cp -R fastlane/* ios/fastlane/

echo "Navigating into ios..."
cd ios

echo "Starting iOS build process..."

# Build the IPA
bundle exec fastlane build_ipa auth_key:"fastlane/app_store_key.p8" output_directory:"./build" output_name:"app.ipa"

echo "Build complete. Starting upload..."

# Upload the IPA to App Store Connect
bundle exec fastlane upload_ipa auth_key:"fastlane/app_store_key.p8" ipa:"./build/app.ipa"

echo "Upload complete!"
