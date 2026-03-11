#!/bin/bash
# ============================================================
# app_health_check.sh — Check application HTTP status
# ============================================================

set -u

# Default endpoint if none provided
URL="${1:-http://localhost:4499}"
APP_NAME="Wisecow App"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🏥 App Health Checker - $TIMESTAMP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Target URL: $URL"
echo ""

# Send HTTP request and get status code
# -s: silent, -o /dev/null: discard body, -w: write-out status code, --connect-timeout: 5s
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$URL" || echo "000")

if [ "$STATUS_CODE" -eq 200 ]; then
    echo -e "Status: ${GREEN}UP${NC} (HTTP $STATUS_CODE)"
    echo "[$TIMESTAMP] SUCCESS: $APP_NAME is UP ($STATUS_CODE)" >> /tmp/app_health.log
else
    echo -e "Status: ${RED}DOWN${NC} (HTTP $STATUS_CODE)"
    echo "[$TIMESTAMP] FAILURE: $APP_NAME is DOWN ($STATUS_CODE)" >> /tmp/app_health.log
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
