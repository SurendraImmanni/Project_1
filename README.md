# DevFlow Dashboard — Deployment Guide

A production-ready HTML web app containerized with Docker and deployed to AWS EC2
via a Jenkins CI/CD pipeline.

---

## Project Structure

```
myapp/
├── index.html                  ← The web app (edit this to customize)
├── nginx.conf                  ← Nginx server configuration
├── Dockerfile                  ← Container build instructions
├── .dockerignore               ← Files to exclude from Docker build
├── sonar-project.properties    ← SonarQube scan configuration
├── Jenkinsfile                 ← CI pipeline (build + push to Docker Hub)
├── Jenkinsfile-cd              ← CD pipeline (deploy to AWS EC2)
└── README.md                   ← This file
```

---

## What You Need to Change

Search for these placeholders and replace them with your actual values:

| Placeholder | Where | What to put |
|---|---|---|
| `yourdockerhubusername` | Jenkinsfile, Jenkinsfile-cd | Your Docker Hub username |
| `yourusername/your-repo.git` | Jenkinsfile | Your GitHub repo URL |
| `your-sonarqube-server:9000` | Jenkinsfile | Your SonarQube server URL |
| `ec2-xx-xx-xx-xx.compute.amazonaws.com` | Jenkinsfile-cd | Your EC2 public DNS |

---

## Step 1 — Set Up AWS EC2

1. Launch an EC2 instance (Ubuntu 22.04 recommended, t2.micro is free tier)
2. In **Security Group**, open inbound ports:
   - Port **22** (SSH) — for Jenkins to connect
   - Port **80** (HTTP) — for users to access the app
3. SSH into EC2 and install Docker:

```bash
sudo apt update
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu   # lets ubuntu user run docker without sudo
# Log out and log back in for this to take effect
```

---

## Step 2 — Set Up Jenkins Credentials

Go to **Jenkins → Manage Jenkins → Credentials → Global → Add Credential**

| Credential ID | Kind | Description |
|---|---|---|
| `dockerhub-creds` | Username with password | Your Docker Hub username + password |
| `sonarqube-token` | Secret text | SonarQube user token |
| `ec2-ssh-key` | SSH Username with private key | Paste your .pem file contents |

---

## Step 3 — Install Jenkins Plugins

Go to **Jenkins → Manage Jenkins → Plugins → Available**:
- Docker Pipeline
- SonarQube Scanner
- SSH Agent
- Pipeline Utility Steps (optional but useful)

---

## Step 4 — Configure SonarQube in Jenkins

Go to **Jenkins → Manage Jenkins → Configure System → SonarQube servers**:
- Name: `SonarQube` (must match exactly what's in the Jenkinsfile)
- URL: `http://your-sonarqube-server:9000`
- Server authentication token: select `sonarqube-token`

---

## Step 5 — Create Jenkins Pipeline Jobs

**CI Job:**
1. New Item → Pipeline → name it `devflow-ci-pipeline`
2. Pipeline Definition: "Pipeline script from SCM"
3. SCM: Git, URL: your GitHub repo, Script path: `Jenkinsfile`

**CD Job:**
1. New Item → Pipeline → name it `devflow-cd-pipeline`
2. Pipeline Definition: "Pipeline script from SCM"  
3. Script path: `Jenkinsfile-cd`
4. Check "This project is parameterized" → String parameter → Name: `IMAGE_TAG`

---

## Step 6 — Run It!

1. Go to your CI pipeline job → **Build Now**
2. Watch the stages: Checkout → SonarQube → Quality Gate → Docker Build → Push
3. If CI passes, it automatically triggers the CD pipeline
4. CD pipeline SSHs into EC2, pulls the image, and starts the container
5. Visit `http://your-ec2-public-ip` in a browser 🎉

---

## Manual Docker Commands (for testing locally)

```bash
# Build the image
docker build -t devflow:latest .

# Run the container
docker run -d --name devflow -p 8080:80 devflow:latest

# Visit: http://localhost:8080

# View logs
docker logs devflow

# Stop container
docker stop devflow && docker rm devflow
```

---

## Troubleshooting

**Container not starting?**
```bash
docker logs devflow-container
docker ps -a
```

**Port 80 not accessible?**
- Check EC2 Security Group has inbound rule for port 80
- Verify container is running: `docker ps`

**SSH permission denied in Jenkins?**
- Make sure the .pem key in Jenkins credentials is the PRIVATE key (not .pub)
- Make sure EC2 user is `ubuntu` (Ubuntu) or `ec2-user` (Amazon Linux)

**SonarQube quality gate failing?**
- Check sonar-project.properties has correct projectKey
- Review SonarQube dashboard at http://your-sonarqube-server:9000
