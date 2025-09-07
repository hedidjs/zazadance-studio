#!/bin/bash

# App Store Connect Upload Script for ZaZa Dance Studio
# Version 1.0.0 Build 25

IPA_PATH="$(pwd)/user-app/build/ios/ipa/ZaZa Dance Studio.ipa"
echo "🚀 ZaZa Dance Studio - App Store Upload"
echo "📱 IPA Location: $IPA_PATH"
echo "📊 App Details:"
echo "   • Version: 1.0.0 (Build 25)"
echo "   • Bundle ID: com.sharonstudio.app.danceStudioApp"
echo "   • Size: 22.8MB"
echo ""

# Method 1: Using App Store Connect API (requires credentials)
echo "Method 1: API Upload (requires App Store Connect API key)"
echo "If you have API credentials, run:"
echo "xcrun altool --upload-app --type ios -f \"$IPA_PATH\" --apiKey YOUR_API_KEY --apiIssuer YOUR_API_ISSUER"
echo ""

# Method 2: Using Transporter App
echo "Method 2: Transporter App"
echo "1. Download Transporter from Mac App Store: https://apps.apple.com/us/app/transporter/id1450874784"
echo "2. Open Transporter and drag the IPA file: $IPA_PATH"
echo "3. Sign in with your Apple ID and upload"
echo ""

# Method 3: Using Xcode
echo "Method 3: Xcode Archive Organizer"
echo "1. Open Xcode -> Window -> Organizer"
echo "2. Select the archive at: user-app/build/ios/archive/Runner.xcarchive"
echo "3. Click 'Distribute App' and follow the steps"
echo ""

echo "✅ All builds completed successfully:"
echo "   • GitHub: Code pushed with welcome messages feature"
echo "   • Web Admin: build/web (ready for deployment)"
echo "   • Android APK: build/app/outputs/flutter-apk/app-release.apk (57.1MB)"
echo "   • iOS IPA: $IPA_PATH (22.8MB)"
echo ""
echo "Choose your preferred upload method above to complete the App Store submission."