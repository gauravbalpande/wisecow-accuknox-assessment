# 🐄 Wisecow DevOps Project

## 📌 Project Overview

Wisecow is a simple web application that displays random quotes using `fortune` and `cowsay`.

This project demonstrates a complete DevOps workflow, including:

- **Docker containerization**
- **CI/CD automation using GitHub Actions**
- **Kubernetes deployment**
- **Container registry integration**

The goal of this project is to implement a production-grade CI/CD pipeline that automatically builds, tests, and deploys the application.

---

## 🏗 Architecture

```
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
```

---

## ⚙️ Technologies Used

| Technology              | Purpose                     |
|--------------------------|-----------------------------|
| **Docker**              | Containerization           |
| **Kubernetes**          | Container orchestration    |
| **GitHub Actions**      | CI/CD automation           |
| **GitHub Container Registry** | Docker image storage |
| **Bash**                | Application logic          |
| **Python HTTP Server**  | Web server                 |

---

## 📂 Project Structure

```
wisecow
│
├── .github/workflows/
│   └── wisecow-pipeline.yml
│
├── k8s/
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
│
├── wisecow.sh
├── Dockerfile
├── assignment-response.md
└── README.md
```

---

## 🚀 CI/CD Pipeline

The CI/CD pipeline is implemented using GitHub Actions and runs automatically when code is pushed to the repository.

### Pipeline Stages

1. **Code Validation**
   - Runs ShellCheck to validate Bash scripts.
   - Tests script execution.
   - Validates Kubernetes manifests.

2. **Build Docker Image**
   - Builds the container image using Docker Buildx.

3. **Push Image to Registry**
   - Pushes the image to GitHub Container Registry (GHCR).
   - Example image: `ghcr.io/gauravbalpande/wisecow`

4. **Deploy to Kubernetes**
   - Creates a Kind cluster.
   - Deploys Kubernetes manifests.
   - Verifies deployment rollout.

---

## 🐳 Docker Containerization

### Build Image
```bash
docker build -t wisecow .
```

### Run Container
```bash
docker run -p 4499:4499 wisecow
```

Access the application at: [http://localhost:4499](http://localhost:4499)

---

## ☸️ Kubernetes Deployment

### Apply Kubernetes Manifests
```bash
kubectl apply -f k8s/
```

### Check Running Pods
```bash
kubectl get pods -n wisecow
```

### Port Forward to Access the Application
```bash
kubectl port-forward svc/wisecow-service 8080:80 -n wisecow
```

Access the application at: [http://localhost:8080](http://localhost:8080)

---

## 🖥 Example Application Output

```
 ______________________
< Fortune favors the brave >
 ----------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

---

## 🔒 Security Best Practices

- Runs container as a non-root user.
- Uses a minimal base image.
- Implements Docker health checks.
- Validates code through CI before deployment.

---

## 📈 Future Improvements

Potential enhancements include:

- Deploying the application on AWS EKS.
- Using Helm charts for Kubernetes manifests.
- Adding Prometheus and Grafana for monitoring.
- Integrating Trivy for security scanning.
- Implementing GitOps with ArgoCD.

---

## 📄 Assignment Response

A detailed explanation of the assignment solution can be found in `assignment-response.md`.

---

## 👨‍💻 Author

**Gaurav Balpande**  
DevOps | Cloud | Kubernetes | CI/CD  

GitHub: [https://github.com/gauravbalpande](https://github.com/gauravbalpande)

---

## 🔗 Repository

[https://github.com/gauravbalpande/wisecow](https://github.com/gauravbalpande/wisecow)