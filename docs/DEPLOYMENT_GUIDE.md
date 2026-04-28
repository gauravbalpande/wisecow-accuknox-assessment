# 🚀 Wisecow Deployment Guide

This guide provides step-by-step instructions on how to get the Wisecow application up and running on your machine or in a cluster.

---

## 💻 Option 1: Local Deployment (The Quickest Way)

If you just want to see the app running on your own computer without Kubernetes.

1.  **Make the script executable:**
    ```bash
    chmod +x wisecow.sh
    ```
2.  **Run the script:**
    ```bash
    ./wisecow.sh
    ```
3.  **Visit the app:**
    Open your browser and go to `http://localhost:4499`

---

## 🐳 Option 2: Docker Deployment

Run the app inside a container to ensure all dependencies (fortune, cowsay) are included.

1.  **Build the image:**
    ```bash
    docker build -t wisecow:latest .
    ```
2.  **Run the container:**
    ```bash
    docker run -p 4499:4499 wisecow:latest
    ```
3.  **Visit the app:**
    Open your browser to `http://localhost:4499`

---

## ☸️ Option 3: Automated Kubernetes Deployment (Recommended)

This is the professional way. It uses a script to set up a local cluster (Kind or Minikube), install everything, and configure security.

1.  **Run the deployment script:**
    ```bash
    bash scripts/deploy.sh
    ```
2.  **What the script does for you:**
    -   Creates a local Kubernetes cluster named `wisecow-cluster`.
    -   Builds the Docker image and loads it into the cluster.
    -   Generates a secure TLS certificate for HTTPS.
    -   Creates a namespace named `wisecow`.
    -   Deploys the application with 2 replicas (for reliability).
3.  **Access the app:**
    The script will tell you how to access it. Typically, you will run:
    ```bash
    kubectl port-forward svc/wisecow-service 4499:80 -n wisecow
    ```
    Then visit: `http://localhost:4499`

---

## 🧪 Verifying the Deployment

After deploying to Kubernetes, run our automated health check:

```bash
bash scripts/health-check.sh
```

If everything is green (✅), your deployment is successful!

---

## 🛠️ Troubleshooting

-   **Port 4499 already in use?**
    Change the port by running `PORT=5000 ./wisecow.sh`.
-   **Kubectl commands not working?**
    Ensure you are in the correct namespace: `kubectl get pods -n wisecow`.
-   **Image not found?**
    If using Kind, ensure you ran `kind load docker-image wisecow:local`.
