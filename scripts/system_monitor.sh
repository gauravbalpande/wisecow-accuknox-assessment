#!/bin/bash
# ============================================================
# system_monitor.sh — Monitor CPU, Memory, Disk, and Processes
# ============================================================

set -u # Error on undefined variables

# Threshold for alerts (80%)
THRESHOLD=80
LOG_FILE="/tmp/system_monitor.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Colors for console output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_alert() {
    local message="$1"
    echo -e "${RED}[ALERT] $message ${NC}"
    echo "[$TIMESTAMP] [ALERT] $message" >> "$LOG_FILE"
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🖥️  System Health Monitor - $TIMESTAMP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Check CPU Usage
# Using 'top' to get current CPU usage (works on macOS and Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then
    CPU_USAGE=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//' | cut -d. -f1)
else
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' | cut -d. -f1)
fi

echo -n "CPU Usage: $CPU_USAGE% "
if [ "$CPU_USAGE" -gt "$THRESHOLD" ]; then
    log_alert "High CPU usage detected: $CPU_USAGE%"
else
    echo -e "${GREEN}(OK)${NC}"
fi

# 2. Check Memory Usage
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Simple macOS memory check
    MEM_USAGE=$(memory_pressure | grep "System-wide memory free percentage" | awk '{print 100 - $5}')
else
    MEM_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}' | cut -d. -f1)
fi

echo -n "Memory Usage: $MEM_USAGE% "
if [ "$MEM_USAGE" -gt "$THRESHOLD" ]; then
    log_alert "High Memory usage detected: $MEM_USAGE%"
else
    echo -e "${GREEN}(OK)${NC}"
fi

# 3. Check Disk Usage (Root partition)
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

echo -n "Disk Usage: $DISK_USAGE% "
if [ "$DISK_USAGE" -gt "$THRESHOLD" ]; then
    log_alert "High Disk usage detected: $DISK_USAGE%"
else
    echo -e "${GREEN}(OK)${NC}"
fi

# 4. Check Top Running Processes (By CPU)
echo ""
echo "🔥 Top 5 Processes (by CPU):"
if [[ "$OSTYPE" == "darwin"* ]]; then
    ps -arcwwwxo %cpu,command | head -6
else
    ps -eo pcpu,comm --sort=-pcpu | head -6
fi

echo ""
echo "Log saved to: $LOG_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
