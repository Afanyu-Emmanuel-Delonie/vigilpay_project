# test_auth.py

import requests
import json

base_url = "http://127.0.0.1:8000/api"

def test_register():
    """Test user registration"""
    url = f"{base_url}/auth/register/"
    data = {
        "email": "test@example.com",
        "username": "testuser",
        "first_name": "Test",
        "last_name": "User",
        "password": "Test@123456",
        "password2": "Test@123456",
        "phone_number": "+1234567890",
        "company_name": "Test Company",
        "job_title": "Developer"
    }
    
    print("\n=== Testing Registration ===")
    print(f"POST {url}")
    print(f"Data: {json.dumps(data, indent=2)}")
    
    response = requests.post(url, json=data)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    
    return response.json()

def test_login():
    """Test user login"""
    url = f"{base_url}/auth/login/"
    data = {
        "email": "test@example.com",
        "password": "Test@123456"
    }
    
    print("\n=== Testing Login ===")
    print(f"POST {url}")
    print(f"Data: {json.dumps(data, indent=2)}")
    
    response = requests.post(url, json=data)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    
    return response.json()

def test_profile(token):
    """Test getting user profile"""
    url = f"{base_url}/auth/profile/"
    headers = {"Authorization": f"Bearer {token}"}
    
    print("\n=== Testing Profile ===")
    print(f"GET {url}")
    print(f"Headers: {json.dumps(headers, indent=2)}")
    
    response = requests.get(url, headers=headers)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    
    return response.json()

def test_refresh_token(refresh_token):
    """Test refreshing access token"""
    url = f"{base_url}/auth/refresh-token/"
    data = {"refresh": refresh_token}
    
    print("\n=== Testing Token Refresh ===")
    print(f"POST {url}")
    print(f"Data: {json.dumps(data, indent=2)}")
    
    response = requests.post(url, json=data)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    
    return response.json()

def test_logout(refresh_token, access_token):
    """Test logout"""
    url = f"{base_url}/auth/logout/"
    headers = {"Authorization": f"Bearer {access_token}"}
    data = {"refresh": refresh_token}
    
    print("\n=== Testing Logout ===")
    print(f"POST {url}")
    print(f"Headers: {json.dumps(headers, indent=2)}")
    print(f"Data: {json.dumps(data, indent=2)}")
    
    response = requests.post(url, json=data, headers=headers)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    
    return response.json()

if __name__ == "__main__":
    print("Starting JWT Authentication Tests...")
    print("=" * 50)
    
    # Run tests in sequence
    register_result = test_register()
    
    if register_result.get('access'):
        print("\n✅ Registration successful!")
        access_token = register_result['access']
        refresh_token = register_result['refresh']
        
        # Test profile with access token
        profile_result = test_profile(access_token)
        
        # Test refresh token
        refresh_result = test_refresh_token(refresh_token)
        
        # Test logout
        logout_result = test_logout(refresh_token, access_token)
    else:
        print("\n⚠️  Registration might have failed, trying login...")
        login_result = test_login()
        
        if login_result.get('access'):
            access_token = login_result['access']
            refresh_token = login_result['refresh']
            
            # Test profile with access token
            profile_result = test_profile(access_token)
            
            # Test refresh token
            refresh_result = test_refresh_token(refresh_token)
            
            # Test logout
            logout_result = test_logout(refresh_token, access_token)
    
    print("\n" + "=" * 50)
    print("Tests completed!")