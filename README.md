# Wisecow on Kubernetes (AccuKnox DevOps Trainee Assessment)

Containerisation and Kubernetes deployment of the **Wisecow** app (Fortune + Cowsay) with **CI/CD** and **TLS**.

## What this repository contains

- **Application**: `wisecow.sh` (Bash entrypoint, serves HTTP on port `4499`)
- **Containerisation**: `Dockerfile` (+ `.dockerignore`)
- **Kubernetes**: `k8s/` (Namespace, ServiceAccount, Deployment, Service, Ingress/TLS)
- **CI/CD**: `.github/workflows/deploy.yml` (lint → build/push to GHCR → deploy to a Kind cluster)
- **Problem Statement 2 scripts**: `scripts/` (system health monitor + application health checker)
- **Optional (extra points)**: `k8s/kubearmor-policy.yaml` (zero-trust policy for workload)
- **Docs**: `docs/DEPLOYMENT_GUIDE.md`, `docs/PROJECT_EXPLANATION.md`

## Architecture (high level)

1. Developer pushes code to GitHub  
2. GitHub Actions runs lint/tests and builds the container image  
3. Image is pushed to **GitHub Container Registry (GHCR)**  
4. Kubernetes manifests deploy the workload to a cluster (Kind/Minikube)  
5. App is exposed via **Ingress** with **TLS** (`https://wisecow.local`)

## Prerequisites

- Docker
- Kubernetes: **Kind** or **Minikube**
- `kubectl`
- `openssl`

## Run locally (Docker)

```bash
docker build -t wisecow:local .
docker run --rm -p 4499:4499 wisecow:local
curl -i http://localhost:4499/
```

## Deploy locally (Kind/Minikube + TLS)

This repo includes an automated deploy script that:
- creates/reuses a cluster
- installs/enables ingress controller
- builds and loads the image into the cluster
- generates a self-signed TLS cert and creates a Kubernetes TLS secret
- applies manifests and verifies rollout

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

Then add an `/etc/hosts` entry and open the app via TLS:

```bash
sudo sh -c 'echo "127.0.0.1 wisecow.local" >> /etc/hosts'
```

- **HTTPS**: `https://wisecow.local`
- **(Optional) Port-forward**:

```bash
kubectl -n wisecow port-forward svc/wisecow-service 4499:80
curl -i http://localhost:4499/
```

## CI/CD (GitHub Actions)

Workflow: `.github/workflows/deploy.yml`

- **Lint & Test**: `shellcheck` + Kubernetes dry-run apply + Dockerfile lint
- **Build & Push**: Buildx build and push to GHCR + Trivy scan
- **Deploy (challenge goal)**: Deploys to an ephemeral Kind cluster with Ingress + self-signed TLS

To use GHCR push, ensure the repository is **public** (assignment requirement) or configure package visibility accordingly.

## Problem Statement 2 scripts

Install dependencies (Python scripts):

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r scripts/requirements.txt
```

1) **System Health Monitoring**

```bash
python scripts/system_health_monitor.py
# or
bash scripts/system_monitor.sh
```

2) **Application Health Checker**

```bash
bash scripts/app_health_check.sh http://localhost:4499
# or
python scripts/app_health_checker.py
```

## Optional: KubeArmor (zero-trust) policy

If KubeArmor is installed in your cluster, apply:

```bash
kubectl apply -f k8s/kubearmor-policy.yaml
```

This policy uses a strict default-block posture and only allows the binaries required by Wisecow.

## Security notes (AccuKnox focus)

- Runs as **non-root** with hardened `securityContext`
- `readOnlyRootFilesystem: true` with explicit writable `/tmp`
- Disables service account token mount (`automountServiceAccountToken: false`)
- CI includes Dockerfile linting + vulnerability scan

## Folder structure

```
.
├── .github/workflows/deploy.yml
├── docs/
├── k8s/
│   ├── namespace.yaml
│   ├── serviceaccount.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── networkpolicy.yaml
│   ├── pdb.yaml
│   ├── hpa.yaml
│   ├── tls-secret.example.yaml
│   └── kubearmor-policy.yaml
├── scripts/
│   ├── deploy.sh
│   ├── health-check.sh
│   ├── system_monitor.sh
│   ├── app_health_check.sh
│   ├── system_health_monitor.py
│   ├── app_health_checker.py
│   └── requirements.txt
├── Dockerfile
├── .dockerignore
└── wisecow.sh
```