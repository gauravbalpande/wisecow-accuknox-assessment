#!/usr/bin/env python3
"""
Simple Application Health Checker
Checks if applications are responding
"""

import requests
import time
from datetime import datetime

def check_app_health(url, name):
    """Check if an application is healthy"""
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            print(f"✅ {name}: UP (Status: {response.status_code})")
            return True
        else:
            print(f"❌ {name}: DOWN (Status: {response.status_code})")
            return False
    except Exception as e:
        print(f"❌ {name}: DOWN (Error: {str(e)})")
        return False

def main():
    """Main health check function"""
    print("="*50)
    print("APPLICATION HEALTH CHECK")
    print("="*50)
    print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # List of applications to check
    apps = [
        {"name": "Google", "url": "https://www.google.com"},
        {"name": "JSONPlaceholder", "url": "https://jsonplaceholder.typicode.com/posts/1"},
        {"name": "Wisecow Local", "url": "http://localhost:4499"}
    ]
    
    healthy_count = 0
    total_count = len(apps)
    
    for app in apps:
        if check_app_health(app["url"], app["name"]):
            healthy_count += 1
        time.sleep(1)  # Small delay between checks
    
    print()
    print(f"Summary: {healthy_count}/{total_count} applications are healthy")
    print("="*50)
    
    return healthy_count == total_count

if __name__ == "__main__":
    main()
