#!/bin/bash
# ============================================================
# deploy.sh — Automated deployment of Wisecow to a local
#              Kind/Minikube Kubernetes cluster
# ============================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NAMESPACE="wisecow"
CLUSTER_NAME="wisecow-cluster"
IMAGE_NAME="wisecow:local"
TLS_CERT="tls.crt"
TLS_KEY="tls.key"

# ── Helper Functions ──────────────────────────────────────────

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC}   $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERR]${NC}  $1"; }

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed. Please install it first."
        exit 1
    fi
}

# ── Pre-flight Checks ────────────────────────────────────────

log_info "Running pre-flight checks..."
check_command docker
check_command kubectl
check_command openssl
log_success "All required tools are installed."

# Detect cluster tool
if command -v kind &> /dev/null; then
    CLUSTER_TOOL="kind"
elif command -v minikube &> /dev/null; then
    CLUSTER_TOOL="minikube"
else
    log_error "Neither Kind nor Minikube is installed."
    log_info "Install Kind:     https://kind.sigs.k8s.io/docs/user/quick-start/"
    log_info "Install Minikube: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi
log_success "Using cluster tool: $CLUSTER_TOOL"

# ── Step 1: Create Cluster ───────────────────────────────────

log_info "Step 1/6 — Creating Kubernetes cluster..."

if [ "$CLUSTER_TOOL" = "kind" ]; then
    if kind get clusters 2>/dev/null | grep -q "$CLUSTER_NAME"; then
        log_warn "Cluster '$CLUSTER_NAME' already exists. Reusing it."
    else
        kind create cluster --name "$CLUSTER_NAME" --wait 60s
        log_success "Kind cluster '$CLUSTER_NAME' created."
    fi
elif [ "$CLUSTER_TOOL" = "minikube" ]; then
    if minikube status &>/dev/null; then
        log_warn "Minikube cluster already running. Reusing it."
    else
        minikube start --driver=docker
        log_success "Minikube cluster started."
    fi
fi

# Install/enable ingress controller depending on cluster tool
log_info "Installing/Enabling Ingress Controller..."
if [ "$CLUSTER_TOOL" = "kind" ]; then
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=180s
    log_success "NGINX Ingress installed (Kind)."
else
    # Minikube
    minikube addons enable ingress >/dev/null
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=180s || true
    log_success "Ingress enabled (Minikube)."
fi

# Admission webhook can take a bit longer than the controller pod.
log_info "Waiting for NGINX Ingress admission webhook..."
for i in $(seq 1 60); do
    if kubectl -n ingress-nginx get endpoints ingress-nginx-controller-admission >/dev/null 2>&1; then
        EP_ADDR="$(kubectl -n ingress-nginx get endpoints ingress-nginx-controller-admission -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null || true)"
        if [ -n "${EP_ADDR:-}" ]; then
            log_success "Ingress admission webhook is ready."
            break
        fi
    fi
    if [ "$i" -eq 60 ]; then
        log_warn "Ingress admission webhook not ready yet; continuing with retries."
    fi
    sleep 2
done

# ── Step 2: Build Docker Image ───────────────────────────────

log_info "Step 2/6 — Building Docker image..."
docker build -t "$IMAGE_NAME" .
log_success "Docker image '$IMAGE_NAME' built."

# Load image into cluster
if [ "$CLUSTER_TOOL" = "kind" ]; then
    kind load docker-image "$IMAGE_NAME" --name "$CLUSTER_NAME"
elif [ "$CLUSTER_TOOL" = "minikube" ]; then
    minikube image load "$IMAGE_NAME"
fi
log_success "Image loaded into $CLUSTER_TOOL cluster."

# ── Step 3: Generate TLS Certificate ─────────────────────────

log_info "Step 3/6 — Generating self-signed TLS certificate..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$TLS_KEY" -out "$TLS_CERT" \
    -subj "/CN=wisecow.local/O=Wisecow" 2>/dev/null
log_success "TLS certificate generated for wisecow.local"

# ── Step 4: Create Namespace & Secrets ────────────────────────

log_info "Step 4/6 — Setting up Kubernetes namespace and secrets..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/serviceaccount.yaml

kubectl create secret tls wisecow-tls-secret \
    --cert="$TLS_CERT" --key="$TLS_KEY" \
    -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

log_success "Namespace and TLS secret created."

# ── Step 5: Deploy Application ────────────────────────────────

log_info "Step 5/6 — Deploying Wisecow to Kubernetes..."

# Patch deployment to use local image
kubectl apply -f k8s/deployment.yaml
kubectl set image deployment/wisecow-deployment \
    wisecow="$IMAGE_NAME" -n "$NAMESPACE"
kubectl patch deployment wisecow-deployment -n "$NAMESPACE" \
    --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/imagePullPolicy", "value": "IfNotPresent"}]'

kubectl apply -f k8s/service.yaml
# Apply ingress with retry (webhook can be briefly unavailable)
for i in $(seq 1 10); do
    if kubectl apply -f k8s/ingress.yaml; then
        break
    fi
    log_warn "Ingress apply failed (attempt $i/10). Retrying in 3s..."
    sleep 3
done
kubectl apply -f k8s/pdb.yaml
kubectl apply -f k8s/networkpolicy.yaml

# HPA requires metrics-server; apply if available
if kubectl get apiservice v1beta1.metrics.k8s.io >/dev/null 2>&1 || kubectl get apiservice v1.metrics.k8s.io >/dev/null 2>&1; then
    kubectl apply -f k8s/hpa.yaml
    log_success "HPA applied (metrics API detected)."
else
    log_warn "Metrics API not detected; skipping HPA apply (k8s/hpa.yaml)."
fi

log_success "All manifests applied."

# ── Step 6: Verify Deployment ─────────────────────────────────

log_info "Step 6/6 — Verifying deployment..."

echo ""
log_info "Waiting for rollout to complete..."
kubectl rollout status deployment/wisecow-deployment -n "$NAMESPACE" --timeout=120s

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📊 Deployment Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Pods:"
kubectl get pods -n "$NAMESPACE" -o wide
echo ""
echo "Services:"
kubectl get svc -n "$NAMESPACE"
echo ""
echo "Ingress:"
kubectl get ingress -n "$NAMESPACE"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Port-forward for local access
log_success "Deployment complete!"
echo ""
log_info "To access the application locally, run:"
echo "  kubectl port-forward svc/wisecow-service 4499:80 -n $NAMESPACE"
echo "  Then open: http://localhost:4499"
echo ""
log_info "To access via Ingress (if NGINX Ingress is installed):"
echo "  Add '127.0.0.1 wisecow.local' to /etc/hosts"
echo "  Then open: https://wisecow.local"

# Cleanup temp TLS files
rm -f "$TLS_CERT" "$TLS_KEY"
