#!/usr/bin/env python3
"""
Script to update App Store Connect metadata using App Store Connect API
"""

import json
import base64
import time
import jwt
import requests
from pathlib import Path

# Configuration
API_KEY_ID = "496SGT8GNA"
ISSUER_ID = "7b6d482e-ed19-4762-8b9a-417273b2e760"
PRIVATE_KEY_PATH = Path.home() / ".private_keys" / f"AuthKey_{API_KEY_ID}.p8"
APP_ID = "6739164395"  # ZaZa Dance! app ID from App Store Connect

def create_jwt_token():
    """Create JWT token for App Store Connect API authentication"""
    with open(PRIVATE_KEY_PATH, 'r') as key_file:
        private_key = key_file.read()
    
    headers = {
        'alg': 'ES256',
        'kid': API_KEY_ID,
        'typ': 'JWT'
    }
    
    payload = {
        'iss': ISSUER_ID,
        'exp': int(time.time()) + 20 * 60,  # 20 minutes
        'aud': 'appstoreconnect-v1'
    }
    
    return jwt.encode(payload, private_key, algorithm='ES256', headers=headers)

def make_api_request(endpoint, method='GET', data=None):
    """Make authenticated request to App Store Connect API"""
    token = create_jwt_token()
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    
    url = f"https://api.appstoreconnect.apple.com/v1/{endpoint}"
    
    if method == 'GET':
        response = requests.get(url, headers=headers)
    elif method == 'PATCH':
        response = requests.patch(url, headers=headers, json=data)
    elif method == 'POST':
        response = requests.post(url, headers=headers, json=data)
    
    return response

def get_app_info():
    """Get current app information"""
    response = make_api_request(f'apps/{APP_ID}/appInfos')
    return response.json()

def get_app_info_localizations():
    """Get app info localizations"""
    app_info = get_app_info()
    if app_info['data']:
        app_info_id = app_info['data'][0]['id']
        response = make_api_request(f'appInfos/{app_info_id}/appInfoLocalizations')
        return response.json(), app_info_id
    return None, None

def update_hebrew_localization():
    """Update Hebrew localization with our app info"""
    
    # Load Hebrew app info
    with open('/Users/rontzarfati/Desktop/zaza/zazadance-studio/app-store-assets/hebrew-app-info.json', 'r', encoding='utf-8') as f:
        hebrew_info = json.load(f)
    
    localizations, app_info_id = get_app_info_localizations()
    
    if not localizations:
        print("❌ Could not get app info localizations")
        return False
    
    # Find Hebrew localization
    hebrew_loc = None
    for loc in localizations['data']:
        if loc['attributes']['locale'] == 'he':
            hebrew_loc = loc
            break
    
    if not hebrew_loc:
        # Create Hebrew localization
        data = {
            'data': {
                'type': 'appInfoLocalizations',
                'attributes': {
                    'locale': 'he',
                    'name': 'ZaZa Dance Studio',
                    'subtitle': 'Your Ultimate Dance Learning Companion',
                    'privacyPolicyUrl': hebrew_info['privacy_policy_url'],
                    'privacyChoicesUrl': hebrew_info['privacy_policy_url']
                },
                'relationships': {
                    'appInfo': {
                        'data': {
                            'type': 'appInfos',
                            'id': app_info_id
                        }
                    }
                }
            }
        }
        
        response = make_api_request('appInfoLocalizations', 'POST', data)
        if response.status_code == 201:
            print("✅ Created Hebrew localization")
            hebrew_loc = response.json()['data']
        else:
            print(f"❌ Failed to create Hebrew localization: {response.status_code}")
            print(response.text)
            return False
    
    # Update Hebrew localization
    loc_id = hebrew_loc['id']
    
    update_data = {
        'data': {
            'type': 'appInfoLocalizations',
            'id': loc_id,
            'attributes': {
                'name': 'ZaZa Dance Studio',
                'subtitle': 'Your Ultimate Dance Learning Companion',
                'privacyPolicyUrl': hebrew_info['privacy_policy_url'],
                'privacyChoicesUrl': hebrew_info['privacy_policy_url']
            }
        }
    }
    
    response = make_api_request(f'appInfoLocalizations/{loc_id}', 'PATCH', update_data)
    
    if response.status_code == 200:
        print("✅ Updated Hebrew app info localization")
        return True
    else:
        print(f"❌ Failed to update Hebrew localization: {response.status_code}")
        print(response.text)
        return False

def main():
    """Main function to update App Store Connect"""
    print("🚀 Starting App Store Connect metadata update...")
    
    try:
        # Update Hebrew localization
        if update_hebrew_localization():
            print("✅ Successfully updated App Store Connect metadata!")
        else:
            print("❌ Failed to update metadata")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()