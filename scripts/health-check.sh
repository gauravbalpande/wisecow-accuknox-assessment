#!/bin/bash
# ============================================================
# health-check.sh — Verify Wisecow Kubernetes deployment health
# ============================================================

set -euo pipefail

NAMESPACE="${1:-wisecow}"
DEPLOYMENT="wisecow-deployment"
SERVICE="wisecow-service"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS=0
FAIL=0

check() {
    local description="$1"
    local result="$2"
    if [ "$result" -eq 0 ]; then
        echo -e "  ${GREEN}✅ PASS${NC} — $description"
        ((PASS++))
    else
        echo -e "  ${RED}❌ FAIL${NC} — $description"
        ((FAIL++))
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🏥 Wisecow Health Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check 1: Namespace exists
kubectl get namespace "$NAMESPACE" &>/dev/null
check "Namespace '$NAMESPACE' exists" $?

# Check 2: Deployment exists and is available
AVAILABLE=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" \
    -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo "0")
DESIRED=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" \
    -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")

if [ "$AVAILABLE" = "$DESIRED" ] && [ "$DESIRED" != "0" ]; then
    check "Deployment '$DEPLOYMENT' — $AVAILABLE/$DESIRED replicas ready" 0
else
    check "Deployment '$DEPLOYMENT' — ${AVAILABLE:-0}/${DESIRED:-0} replicas ready" 1
fi

# Check 3: All pods are Running
NOT_RUNNING=$(kubectl get pods -n "$NAMESPACE" -l app=wisecow \
    --no-headers 2>/dev/null | grep -cv "Running" || true)
if [ "$NOT_RUNNING" -eq 0 ]; then
    check "All pods are in Running state" 0
else
    check "All pods are in Running state ($NOT_RUNNING not running)" 1
fi

# Check 4: Service has endpoints
ENDPOINTS=$(kubectl get endpoints "$SERVICE" -n "$NAMESPACE" \
    -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || echo "")
if [ -n "$ENDPOINTS" ]; then
    check "Service '$SERVICE' has active endpoints" 0
else
    check "Service '$SERVICE' has active endpoints" 1
fi

# Check 5: Ingress exists
kubectl get ingress wisecow-ingress -n "$NAMESPACE" &>/dev/null
check "Ingress 'wisecow-ingress' exists" $?

# Check 6: TLS secret exists
kubectl get secret wisecow-tls-secret -n "$NAMESPACE" &>/dev/null
check "TLS secret 'wisecow-tls-secret' exists" $?

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
TOTAL=$((PASS + FAIL))
echo -e "  Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC} / $TOTAL total"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
