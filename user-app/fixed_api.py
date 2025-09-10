#!/usr/bin/env python3

import requests
import jwt
import time
import json

# Correct App Store Connect API credentials
KEY_ID = "496SGT8GNA"
ISSUER_ID = "69a6de8f-cc07-47e3-e053-5b8c7c11a4d1" 
KEY_PATH = "/Users/rontzarfati/.private_keys/AuthKey_496SGT8GNA.p8"
APP_ID = "7078329715"
BUNDLE_ID = "com.sharonstudio.app.danceStudioApp"

def generate_token():
    """Generate proper JWT token for App Store Connect API"""
    with open(KEY_PATH, 'r') as f:
        private_key = f.read()
    
    # Correct JWT headers
    headers = {
        'kid': KEY_ID,
        'alg': 'ES256',
        'typ': 'JWT'
    }
    
    # Correct payload with proper timing
    payload = {
        'iss': ISSUER_ID,
        'iat': int(time.time()),
        'exp': int(time.time()) + 1200,  # 20 minutes
        'aud': 'appstoreconnect-v1'
    }
    
    # Generate token
    token = jwt.encode(payload, private_key, algorithm='ES256', headers=headers)
    return token

def get_builds():
    """Get current builds from App Store Connect"""
    token = generate_token()
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
    
    url = f"https://api.appstoreconnect.apple.com/v1/apps/{APP_ID}/builds"
    
    try:
        response = requests.get(url, headers=headers, timeout=30)
        print(f"Response status: {response.status_code}")
        
        if response.status_code == 200:
            return response.json()
        else:
            print(f"Error response: {response.text}")
            return None
            
    except Exception as e:
        print(f"Request failed: {e}")
        return None

def duplicate_build_30_as_31():
    """Copy Build 30 and create Build 31 with our fixes"""
    
    print("🔍 מחפש את הבילדים הקיימים...")
    builds = get_builds()
    
    if not builds or 'data' not in builds:
        print("❌ לא הצלחתי לקבל את רשימת הבילדים")
        return False
        
    print(f"📱 נמצאו {len(builds['data'])} בילדים")
    
    # מצא בילד 30
    build_30 = None
    for build in builds['data']:
        if build['attributes']['version'] == '30':
            build_30 = build
            break
            
    if not build_30:
        print("❌ לא נמצא בילד 30")
        return False
        
    print(f"✅ נמצא בילד 30 - ID: {build_30['id']}")
    
    # יצור בילד 31 בהתבסס על בילד 30
    token = generate_token()
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
    
    # נתונים לבילד 31 החדש
    new_build_data = {
        "data": {
            "type": "builds",
            "attributes": {
                "version": "31",
                "whatsNew": """בילד 31 - תיקונים מלאים:

✅ תוקנה לחלוטין שגיאת Google Sign-In 
- החלפה מ-signInWithIdToken ל-signInWithOAuth
- הסרת serverClientId הבעייתי שגרם לnonce error
- מנגנון fallback מתקדם

✅ נוסף כפתור מחיקת חשבון באיזור האישי
- כפתור אדום בולט עם double confirmation
- מחיקה מלאה של כל נתוני המשתמש ותמונות

✅ תוקנה שגיאת מסד הנתונים PostgreSQL
- תיקון הפניה מטבלת profiles ל-users
- פתרון שגיאת "table not found"

כל הבעיות מבילדים 27-30 נפתרו במלואן!""",
                "minOsVersion": "12.0"
            },
            "relationships": {
                "app": {
                    "data": {
                        "type": "apps",
                        "id": APP_ID
                    }
                }
            }
        }
    }
    
    # POST ליצירת בילד חדש
    create_url = "https://api.appstoreconnect.apple.com/v1/builds"
    
    try:
        response = requests.post(create_url, headers=headers, data=json.dumps(new_build_data), timeout=30)
        print(f"Create response status: {response.status_code}")
        
        if response.status_code in [200, 201]:
            result = response.json()
            build_id = result['data']['id']
            print(f"✅ בילד 31 נוצר בהצלחה! ID: {build_id}")
            return True
        else:
            print(f"❌ שגיאה ביצירת בילד: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ יצירת בילד נכשלה: {e}")
        return False

if __name__ == "__main__":
    print("🚀 יוצר בילד 31 עם כל התיקונים...")
    
    success = duplicate_build_30_as_31()
    
    if success:
        print("🎉 בילד 31 הוכן בהצלחה!")
        print("📱 בדוק בApp Store Connect ו-TestFlight")
    else:
        print("❌ יצירת בילד נכשלה")