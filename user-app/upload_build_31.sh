#!/bin/bash

# App Store Connect credentials
API_KEY_ID="496SGT8GNA"
API_ISSUER_ID="69a6de8f-cc07-47e3-e053-5b8c7c11a4d1"
BUNDLE_ID="com.sharonstudio.app.danceStudioApp"

echo "🚀 מעלה בילד 31 לאפסטור קונקט..."

# בדיקה אם יש IPA קיים מבילד 30
IPA_PATH_30=$(find . -name "*30*.ipa" -type f 2>/dev/null | head -1)

if [ -n "$IPA_PATH_30" ]; then
    echo "📱 נמצא IPA מבילד 30: $IPA_PATH_30"
    echo "🔄 מעלה כבילד 31..."
    
    # העלאה ישירות לאפסטור קונקט
    xcrun altool --upload-app \
        --type ios \
        --file "$IPA_PATH_30" \
        --apiKey "$API_KEY_ID" \
        --apiIssuer "$API_ISSUER_ID" \
        --verbose
        
    if [ $? -eq 0 ]; then
        echo "✅ בילד 31 הועלה בהצלחה!"
        echo "🎉 בדוק בTestFlight תוך כמה דקות"
    else
        echo "❌ העלאה נכשלה"
        exit 1
    fi
else
    echo "❌ לא נמצא קובץ IPA"
    echo "🔨 בונה IPA חדש..."
    
    # ניסוי לבנות IPA פשוט
    flutter clean
    flutter pub get
    
    # בנייה עם Xcode ישירות
    cd ios
    xcodebuild clean -workspace Runner.xcworkspace -scheme Runner
    xcodebuild archive \
        -workspace Runner.xcworkspace \
        -scheme Runner \
        -configuration Release \
        -archivePath ../build/Runner.xcarchive \
        CODE_SIGN_IDENTITY="iPhone Distribution" \
        PROVISIONING_PROFILE_SPECIFIER="ZaZa Dance Distribution"
        
    if [ $? -eq 0 ]; then
        echo "✅ Archive נוצר בהצלחה!"
        
        # יצוא IPA
        xcodebuild -exportArchive \
            -archivePath ../build/Runner.xcarchive \
            -exportPath ../build \
            -exportOptionsPlist ExportOptions.plist
            
        # חיפוש IPA שנוצר
        NEW_IPA=$(find ../build -name "*.ipa" -type f | head -1)
        
        if [ -n "$NEW_IPA" ]; then
            echo "📱 IPA נוצר: $NEW_IPA"
            
            # העלאה
            xcrun altool --upload-app \
                --type ios \
                --file "$NEW_IPA" \
                --apiKey "$API_KEY_ID" \
                --apiIssuer "$API_ISSUER_ID" \
                --verbose
                
            if [ $? -eq 0 ]; then
                echo "✅ בילד 31 הועלה בהצלחה!"
            else
                echo "❌ העלאה נכשלה"
                exit 1
            fi
        else
            echo "❌ לא נוצר IPA"
            exit 1
        fi
    else
        echo "❌ בנייה נכשלה"
        exit 1
    fi
fi