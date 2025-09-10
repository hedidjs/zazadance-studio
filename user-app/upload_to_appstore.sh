#!/bin/bash

# Configuration
API_KEY_ID="496SGT8GNA"
API_ISSUER_ID="69a6de8f-cc07-47e3-e053-5b8c7c11a4d1"
API_KEY_PATH="/Users/rontzarfati/.private_keys/AuthKey_496SGT8GNA.p8"
BUNDLE_ID="com.sharonstudio.app.danceStudioApp"

echo "🚀 Starting iOS build and upload process..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
rm -rf build/

# Get dependencies
echo "📦 Installing dependencies..."
flutter pub get

# Build iOS archive
echo "🏗️ Building iOS archive..."
flutter build ipa --release

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# Find the built IPA
IPA_PATH=$(find build/ios/ipa -name "*.ipa" | head -1)

if [ -z "$IPA_PATH" ]; then
    echo "❌ IPA file not found!"
    exit 1
fi

echo "📱 IPA found at: $IPA_PATH"

# Upload to App Store Connect
echo "☁️ Uploading to App Store Connect..."
xcrun altool --upload-app \
    --type ios \
    --file "$IPA_PATH" \
    --apiKey "$API_KEY_ID" \
    --apiIssuer "$API_ISSUER_ID"

if [ $? -eq 0 ]; then
    echo "✅ Upload completed successfully!"
    echo "🎉 Check App Store Connect for the new build"
else
    echo "❌ Upload failed!"
    exit 1
fi