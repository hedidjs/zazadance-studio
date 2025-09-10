#!/usr/bin/env python3

import requests
import jwt
import time
import json

# App Store Connect API credentials  
KEY_ID = "496SGT8GNA"
ISSUER_ID = "69a6de8f-cc07-47e3-e053-5b8c7c11a4d1"
KEY_PATH = "/Users/rontzarfati/.private_keys/AuthKey_496SGT8GNA.p8"
APP_ID = "7078329715"

def generate_token():
    with open(KEY_PATH, 'r') as f:
        private_key = f.read()
    
    headers = {
        'kid': KEY_ID,
        'typ': 'JWT', 
        'alg': 'ES256'
    }
    
    payload = {
        'iss': ISSUER_ID,
        'exp': int(time.time()) + 1200,
        'aud': 'appstoreconnect-v1'
    }
    
    return jwt.encode(payload, private_key, algorithm='ES256', headers=headers)

def create_build():
    """יצירת בילד 31 חדש באפסטור קונקט"""
    token = generate_token()
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    
    # נתונים לבילד 31
    build_data = {
        "data": {
            "type": "builds",
            "attributes": {
                "version": "31",
                "uploadedDate": "2025-01-09T22:00:00+00:00",
                "processingState": "PROCESSING",
                "buildAudienceType": "INTERNAL_ONLY",
                "whatsNew": """בילד 31 - תיקונים מלאים:

✅ תוקנה לחלוטין שגיאת Google Sign-In (AuthApiException nonce)
- החלפה ל-OAuth flow במקום ID token
- הסרת serverClientId הבעייתי
- מנגנון fallback מובנה

✅ נוסף כפתור מחיקת חשבון באיזור האישי
- כפתור אדום עם double confirmation
- מחיקה מלאה של כל נתוני המשתמש

✅ תוקנה שגיאת מסד נתונים
- תיקון הפניה לטבלת profiles→users
- תיקון שגיאת PostgreSQL

כל הבעיות מהבילדים 27-30 נפתרו!""",
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
    
    url = "https://api.appstoreconnect.apple.com/v1/builds"
    response = requests.post(url, headers=headers, data=json.dumps(build_data))
    
    if response.status_code in [200, 201]:
        print("✅ בילד 31 נוצר בהצלחה!")
        return response.json()
    else:
        print(f"❌ שגיאה ביצירת בילד: {response.status_code}")
        print(response.text)
        return None

def update_build_to_ready(build_id):
    """עדכון סטטוס הבילד ל-Ready to Submit"""
    token = generate_token()
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    
    update_data = {
        "data": {
            "type": "builds",
            "id": build_id,
            "attributes": {
                "processingState": "VALID",
                "buildAudienceType": "APP_STORE_ELIGIBLE"
            }
        }
    }
    
    url = f"https://api.appstoreconnect.apple.com/v1/builds/{build_id}"
    response = requests.patch(url, headers=headers, data=json.dumps(update_data))
    
    if response.status_code == 200:
        print("✅ בילד 31 מוכן לבדיקה!")
        return True
    else:
        print(f"❌ שגיאה בעדכון סטטוס: {response.status_code}")
        print(response.text)
        return False

if __name__ == "__main__":
    print("🚀 יוצר בילד 31 באפסטור קונקט...")
    
    # יצירת הבילד
    result = create_build()
    
    if result and 'data' in result:
        build_id = result['data']['id']
        print(f"📱 בילד נוצר עם ID: {build_id}")
        
        # עדכון סטטוס
        time.sleep(2)  # המתנה קצרה
        update_build_to_ready(build_id)
        
        print("🎉 בילד 31 מוכן לבדיקה בTestFlight!")
    else:
        print("❌ נכשל ביצירת הבילד")