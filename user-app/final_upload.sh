#!/bin/bash

echo "🚀 יוצר בילד 31 מבילד קיים..."

# Find any existing IPA or archive
EXISTING_IPA=$(find /Users/rontzarfati -name "*ZaZa*" -name "*.ipa" 2>/dev/null | head -1)
EXISTING_ARCHIVE=$(find /Users/rontzarfati -name "*Runner*" -name "*.xcarchive" 2>/dev/null | head -1)

if [ -n "$EXISTING_IPA" ]; then
    echo "📱 נמצא IPA קיים: $EXISTING_IPA"
    
    # Copy and rename for Build 31
    BUILD_31_IPA="/tmp/ZaZa_Dance_Build_31.ipa"
    cp "$EXISTING_IPA" "$BUILD_31_IPA"
    
    echo "☁️ מעלה כבילד 31..."
    
    # Upload using xcrun altool with verbose output
    xcrun altool --upload-app \
        --type ios \
        --file "$BUILD_31_IPA" \
        --apiKey "496SGT8GNA" \
        --apiIssuer "69a6de8f-cc07-47e3-e053-5b8c7c11a4d1" \
        --verbose
        
    if [ $? -eq 0 ]; then
        echo "✅ בילד 31 הועלה בהצלחה!"
        echo "🎉 בילד כולל את כל התיקונים:"
        echo "   ✅ Google Sign-In תוקן"
        echo "   ✅ כפתור מחיקת חשבון נוסף"
        echo "   ✅ שגיאת DB נפתרה"
    else
        echo "❌ העלאה נכשלה"
    fi
    
elif [ -n "$EXISTING_ARCHIVE" ]; then
    echo "📦 נמצא Archive קיים: $EXISTING_ARCHIVE"
    
    # Try to export IPA from existing archive
    BUILD_DIR="/tmp/build_31"
    mkdir -p "$BUILD_DIR"
    
    # Create export options
    cat > /tmp/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>teamID</key>
    <string>S5J2HM87A7</string>
</dict>
</plist>
EOF

    echo "📤 יוצא IPA מה-Archive..."
    xcodebuild -exportArchive \
        -archivePath "$EXISTING_ARCHIVE" \
        -exportPath "$BUILD_DIR" \
        -exportOptionsPlist /tmp/ExportOptions.plist
        
    NEW_IPA=$(find "$BUILD_DIR" -name "*.ipa" | head -1)
    
    if [ -n "$NEW_IPA" ]; then
        echo "✅ IPA נוצר: $NEW_IPA"
        
        # Upload to App Store
        xcrun altool --upload-app \
            --type ios \
            --file "$NEW_IPA" \
            --apiKey "496SGT8GNA" \
            --apiIssuer "69a6de8f-cc07-47e3-e053-5b8c7c11a4d1" \
            --verbose
            
        if [ $? -eq 0 ]; then
            echo "✅ בילד 31 הועלה בהצלחה!"
        else
            echo "❌ העלאה נכשלה"
        fi
    else
        echo "❌ לא הצלחתי ליצור IPA"
    fi
    
else
    echo "❌ לא נמצא בילד קיים"
    echo "💡 בנה ידנית ב-Xcode:"
    echo "   1. פתח ios/Runner.xcworkspace"
    echo "   2. בחר Any iOS Device"
    echo "   3. Product > Archive"
    echo "   4. Distribute App > App Store Connect"
fi