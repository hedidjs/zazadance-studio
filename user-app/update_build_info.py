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
    
    token = jwt.encode(payload, private_key, algorithm='ES256', headers=headers)
    return token

def get_builds():
    token = generate_token()
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    
    url = f"https://api.appstoreconnect.apple.com/v1/apps/{APP_ID}/builds"
    response = requests.get(url, headers=headers)
    
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error: {response.status_code}")
        print(response.text)
        return None

def update_build_notes(build_id, notes):
    token = generate_token()
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    
    data = {
        "data": {
            "type": "builds",
            "id": build_id,
            "attributes": {
                "whatsNew": notes
            }
        }
    }
    
    url = f"https://api.appstoreconnect.apple.com/v1/builds/{build_id}"
    response = requests.patch(url, headers=headers, data=json.dumps(data))
    
    if response.status_code == 200:
        print("Build notes updated successfully!")
        return True
    else:
        print(f"Error updating build notes: {response.status_code}")
        print(response.text)
        return False

if __name__ == "__main__":
    builds = get_builds()
    if builds:
        # Find Build 30
        for build in builds['data']:
            if build['attributes']['version'] == '31':
                build_id = build['id']
                notes = """בילד 31 - תיקונים חשובים:
✅ תוקנה שגיאת התחברות Google (nonce error)
✅ נוסף כפתור מחיקת חשבון באיזור האישי  
✅ תוקנה שגיאת מסד הנתונים (profiles table)

כל הבעיות מהבילדים הקודמים נפתרו!"""
                
                update_build_notes(build_id, notes)
                break
        else:
            print("Build 31 not found")
    else:
        print("Failed to get builds")