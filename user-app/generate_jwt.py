#!/usr/bin/env python3

import jwt
import time
from datetime import datetime, timedelta

# App Store Connect API credentials
KEY_ID = "496SGT8GNA"
ISSUER_ID = "69a6de8f-cc07-47e3-e053-5b8c7c11a4d1"
KEY_PATH = "/Users/rontzarfati/.private_keys/AuthKey_496SGT8GNA.p8"

def generate_token():
    # Read private key
    with open(KEY_PATH, 'r') as f:
        private_key = f.read()
    
    # JWT header
    headers = {
        'kid': KEY_ID,
        'typ': 'JWT',
        'alg': 'ES256'
    }
    
    # JWT payload
    payload = {
        'iss': ISSUER_ID,
        'exp': int(time.time()) + 1200,  # 20 minutes
        'aud': 'appstoreconnect-v1'
    }
    
    # Generate token
    token = jwt.encode(payload, private_key, algorithm='ES256', headers=headers)
    return token

if __name__ == "__main__":
    token = generate_token()
    print(token)