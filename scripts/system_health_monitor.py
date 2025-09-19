#!/usr/bin/env python3
"""
Simple System Health Monitor
Checks CPU, memory, and disk usage
"""

import psutil
import time
from datetime import datetime

def check_system_health():
    """Check system health and print report"""
    print("="*50)
    print("SYSTEM HEALTH REPORT")
    print("="*50)
    print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # CPU Usage
    cpu_percent = psutil.cpu_percent(interval=1)
    print(f"CPU Usage: {cpu_percent}%")
    if cpu_percent > 80:
        print("⚠️  HIGH CPU USAGE!")
    
    # Memory Usage
    memory = psutil.virtual_memory()
    memory_percent = memory.percent
    print(f"Memory Usage: {memory_percent}% ({memory.used // (1024**3)} GB / {memory.total // (1024**3)} GB)")
    if memory_percent > 85:
        print("⚠️  HIGH MEMORY USAGE!")
    
    # Disk Usage
    disk = psutil.disk_usage('/')
    disk_percent = (disk.used / disk.total) * 100
    print(f"Disk Usage: {disk_percent:.1f}% ({disk.used // (1024**3)} GB / {disk.total // (1024**3)} GB)")
    if disk_percent > 90:
        print("⚠️  HIGH DISK USAGE!")
    
    # System Load
    load = psutil.getloadavg()
    print(f"Load Average: {load[0]:.2f}, {load[1]:.2f}, {load[2]:.2f}")
    
    print()
    print("Health check completed!")
    print("="*50)

if __name__ == "__main__":
    check_system_health()
