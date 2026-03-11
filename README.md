Wisecow DevOps Project 🐄
Project Overview

Wisecow is a simple web application that displays random quotes using fortune and cowsay.
This project demonstrates a complete DevOps workflow including containerization, CI/CD automation, and Kubernetes deployment.

The objective of this assignment is to implement a production-like DevOps pipeline for deploying the application automatically.

Architecture
Developer
   │
   ▼
GitHub Repository
   │
   ▼
GitHub Actions CI/CD Pipeline
   │
   ▼
Docker Image Build
   │
   ▼
GitHub Container Registry (GHCR)
   │
   ▼
Kubernetes Deployment
   │
   ▼
Wisecow Application
   │
   ▼
User Access
Technologies Used
Technology	Purpose
Docker	Containerization
Kubernetes	Container orchestration
GitHub Actions	CI/CD automation
GitHub Container Registry	Docker image storage
Bash	Application script
Python HTTP Server	Web server
Project Structure
wisecow
│
├── .github
│   └── workflows
│       └── wisecow-ci.yml
│
├── k8s
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
│
├── scripts
│   └── setup.sh
│
├── wisecow.sh
├── Dockerfile
├── assignment-response.md
└── README.md
CI/CD Pipeline

The CI/CD pipeline is implemented using GitHub Actions and runs automatically when code is pushed to the repository.

Pipeline Stages
1️⃣ Code Validation

Runs ShellCheck to validate bash scripts

Tests application script execution

Validates Kubernetes manifests

2️⃣ Build Docker Image

Builds the application container image

Uses Docker Buildx for efficient builds

3️⃣ Push Image to Registry

Pushes the built image to GitHub Container Registry

Example image:

ghcr.io/<github-username>/wisecow
4️⃣ Deploy to Kubernetes

Creates a Kind Kubernetes cluster

Deploys application using Kubernetes manifests

Verifies deployment rollout

Docker Containerization

The application is containerized using Docker.

Build Image
docker build -t wisecow .
Run Container
docker run -p 4499:4499 wisecow

Access application:

http://localhost:4499
Kubernetes Deployment

The application is deployed using Kubernetes manifests.

Apply manifests
kubectl apply -f k8s/
Check pods
kubectl get pods -n wisecow
Port Forward
kubectl port-forward svc/wisecow-service 8080:80 -n wisecow

Open browser:

http://localhost:8080
Sample Output

Example response from the application:

 ______________________
< Fortune favors the brave >
 ----------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
Security Best Practices Implemented

Non-root container user

Minimal base image

Health checks in Docker container

CI validation before deployment

Future Improvements

Possible improvements for production deployment:

Deploy application on AWS EKS

Use Helm charts for Kubernetes deployment

Add monitoring with Prometheus and Grafana

Add security scanning using Trivy

Implement GitOps with ArgoCD

Assignment Response

Detailed explanation of the implementation is available here:

assignment-response.md
Author

Gaurav Balpande

DevOps | Cloud | Kubernetes | CI/CD

GitHub:
https://github.com/gauravbalpande

Repository Link
https://github.com/gauravbalpande/wisecow