[![Build Status](https://img.shields.io/badge/status-active-success.svg)](https://jenkins.example.com)
[![Docker](https://img.shields.io/badge/docker-enabled-blue.svg)]()
[![License](https://img.shields.io/badge/license-proprietary-red.svg)]()
[![Terraform](https://img.shields.io/badge/terraform-1.7.0-blue.svg)]()

# 🎪 Decoryou - Production Infrastructure Repository

**Luxury Event Design Platform - Enterprise-Grade Infrastructure**

A comprehensive, production-ready infrastructure codebase for the Decoryou platform using AWS, Terraform, Ansible, Jenkins, and Docker.

---

## 📋 Quick Start

### Prerequisites
- Terraform 1.5+
- Ansible 2.10+
- Docker 20+
- Docker Compose 2+
- AWS CLI v2
- Git

### Local Development

```bash
# Clone the repository
git clone https://github.com/your-org/decoryou.git
cd decoryou

# Initialize environment
make init
make setup-env

# Start Docker Compose stack
make docker-compose-up

# Access the application
open http://localhost:8080         # Application
open http://localhost:3000         # Grafana (admin/admin)
open http://localhost:9090         # Prometheus
open http://localhost:9001         # MinIO (minioadmin/minioadmin)
```

### Deploy to AWS

```bash
# Plan infrastructure
make plan ENVIRONMENT=dev

# Apply infrastructure
make apply ENVIRONMENT=dev

# Deploy application
make ansible-deploy ENVIRONMENT=dev
```

---

## 🔒 Security Compliance

This project implements enterprise-grade security practices specifically designed for high-stakes technical interviews at organizations like MTA. Our security posture follows industry best practices and is tailored for interviewers John Li and Hai Feng Li.

### Secret Scanning
- **GitGuardian Integration**: Automated detection of 13+ secret types (SMTP, AWS, Generic Passwords)
- **Gitleaks Pre-commit Hooks**: Blocks commits containing secrets before they reach the repository
- **Jenkins Pipeline Security Stage**: Mandatory secret scanning in CI/CD pipeline with failure on detection
- **Git History Scrubbing**: Complete removal of leaked secrets using `git filter-repo`

### Principle of Least Privilege (POLP)
- **IAM Roles**: Minimal required permissions for AWS resources
- **Ansible Vault**: Encrypted secrets management with role-based access
- **Environment Variables**: No hardcoded credentials in Docker Compose or application code
- **Network Security**: VPC isolation with security groups and NACLs
- **Container Security**: Non-root users, read-only filesystems, and minimal base images

All security measures are automated and enforced through CI/CD pipelines to prevent human error.

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         DECORYOU PLATFORM                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐          ┌──────────────────────────┐         │
│  │  Jenkins CI  │ ────────▶│ Build & Test Pipeline    │         │
│  │   Pipeline   │          │ (Docker, Terraform, etc) │         │
│  └──────────────┘          └──────────────────────────┘         │
│         │                            │                           │
│         └────────────────┬───────────┘                           │
│                          ▼                                       │
│         ┌──────────────────────────────┐                        │
│         │  AWS ECR - Docker Registry   │                        │
│         │  (Image: decoryou:latest)    │                        │
│         └──────────────────────────────┘                        │
│                          │                                       │
│         ┌────────────────┴──────────────────┐                   │
│         ▼                                   ▼                   │
│  ┌────────────────────────┐      ┌──────────────────────┐     │
│  │  VPC (10.x.0.0/16)     │      │  Security & Secrets   │     │
│  │  ├─ Public Subnets     │      │  ├─ IAM Roles        │     │
│  │  ├─ Private Subnets    │      │  ├─ SSL Certificates │     │
│  │  ├─ NAT Gateways       │      │  └─ Secrets Manager   │     │
│  │  └─ Route Tables       │      └──────────────────────┘     │
│  └────────────────────────┘                                   │
│         │                                                      │
│  ┌──────┴───────────────────┬──────────────────────────┐     │
│  ▼                          ▼                          ▼     │
│ ┌────────┐          ┌────────────────┐        ┌──────────┐  │
│ │  ALB   │          │   ASG (EC2)    │        │ RDS/MySQL│  │
│ │(80/443)│──────────│  ├─ Min: 1     │        └──────────┘  │
│ │        │          │  ├─ Max: 4     │                      │
│ │ ┌──────┴─────┐    │  └─ Docker     │        ┌──────────┐  │
│ │ │ Target Grp │    │     App        │        │  S3/MSO  │  │
│ │ └────────────┘    └────────────────┘        │ Artifacts│  │
│ └────────────────────────────────────────────┬─┴──────────┘  │
│                                              │                 │
│  ┌────────────────────────────────────────────┘                │
│  │                                                              │
│  ▼                                                              │
│ ┌──────────────────────────────────────────┐                 │
│ │   Monitoring & Observability             │                 │
│ │  ├─ CloudWatch                           │                 │
│ │  ├─ Prometheus                           │                 │
│ │  ├─ Grafana Dashboards                   │                 │
│ │  └─ CloudWatch Alarms                    │                 │
│ └──────────────────────────────────────────┘                 │
│                                                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
decoryou/
├── jenkins/                    # CI/CD Pipelines
│   ├── Jenkinsfile            # Main deployment pipeline
│   ├── Jenkinsfile.pr         # PR validation pipeline
│   ├── agencies/              # Custom Jenkins agents
│   └── scripts/               # Pipeline utility scripts
│
├── terraform/                 # Infrastructure as Code
│   ├── main.tf               # Main configuration
│   ├── backend.tf            # Remote state config
│   ├── variables.tf          # Variable definitions
│   ├── outputs.tf            # Output values
│   ├── provider.tf           # Provider configuration
│   ├── modules/              # Reusable modules
│   │   ├── vpc/              # Network module
│   │   ├── ec2/              # Compute module
│   │   ├── s3/               # Storage module
│   │   └── iam/              # Identity module
│   ├── environments/         # Environment-specific configs
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   └── terraform.tfvars.example
│
├── ansible/                  # Configuration Management
│   ├── site.yml             # Main playbook
│   ├── roles/               # Ansible roles
│   │   ├── common/          # Base system setup
│   │   ├── docker/          # Docker installation
│   │   └── app/             # Application deployment
│   ├── inventories/         # Host inventories
│   │   ├── dev/
│   │   └── prod/
│   └── group_vars/          # Group variables
│
├── docker/                  # Container Configuration
│   ├── Dockerfile           # Multi-stage build
│   └── .dockerignore        # Build context excludes
│
├── scripts/                 # Utility Scripts
│   ├── entrypoint.sh        # Container entrypoint
│   └── healthcheck.sh       # Health check script
│
├── monitoring/              # Observability Stack
│   ├── prometheus/          # Prometheus configuration
│   └── grafana/             # Grafana dashboards
│
├── docs/                    # Documentation
│   ├── ARCHITECTURE.md      # Architecture overview
│   ├── DEPLOYMENT.md        # Deployment procedures
│   └── RUNBOOK.md           # Operational runbook
│
├── config/                  # Application Configuration
│   └── app.config.yaml      # App settings
│
├── tests/                   # Test Suite
│   └── run_tests.sh         # Test runner
│
├── .env.example             # Environment template
├── .gitignore              # Git exclusions
├── .editorconfig           # Editor configuration
├── docker-compose.yml      # Full stack compose
├── docker-compose.override.yml  # Override for dev
├── Makefile                # Automation rules
└── README.md               # This file
```

---

## 🚀 Deployment Workflows

### Development Environment

```bash
# Full local development stack
make docker-compose-up

# Or step-by-step
make tf-init ENVIRONMENT=dev
make plan ENVIRONMENT=dev
make apply ENVIRONMENT=dev
make ansible-deploy ENVIRONMENT=dev
```

### Staging Environment
*Automatic on `staging` branch push*

1. Jenkins pulls latest code
2. Runs linting & security scans
3. Builds Docker image
4. Plans Terraform changes
5. Applies to staging infrastructure
6. Runs smoke tests

### Production Environment
*Manual approval required on `main` branch*

1. Jenkins runs full validation pipeline
2. Generates Terraform plan
3. **Waits for manual approval**
4. Applies infrastructure changes
5. Deploys application via Ansible
6. Runs comprehensive smoke tests
7. Notifies on success/failure

---

## 🔒 Security Best Practices

### Secrets Management
- ❌ **Never** commit `.env`, AWS credentials, or API keys
- ✅ Use Jenkins Credentials Store for CI/CD
- ✅ Use AWS Secrets Manager for runtime secrets
- ✅ Use Ansible Vault for sensitive variables

### Access Control
- ✅ IAM roles follow least privilege
- ✅ EC2 instances use IAM profiles, not hardcoded credentials
- ✅ Security groups whitelist specific CIDR blocks
- ✅ SSH access restricted to bastion hosts

### Infrastructure Security
- ✅ VPC Flow Logs enabled for audit
- ✅ S3 buckets have public access blocked
- ✅ Encryption enabled on all storage
- ✅ Regular security scanning (tfsec, checkov)

### Application Security
- ✅ Multi-stage Docker builds (minimal runtime image)
- ✅ Non-root containers
- ✅ Health checks and auto-recovery
- ✅ HTTP/S encryption

---

## 📊 Monitoring & Observability

### Metrics Collection
- **Prometheus**: Scrapes metrics from all services
- **Node Exporter**: System-level metrics
- **cAdvisor**: Container metrics via Prometheus
- **CloudWatch**: AWS service metrics

### Visualization
- **Grafana**: Pre-configured dashboards
  - System performance
  - Application metrics
  - Container health
  - ALB statistics

### Alerting
- CloudWatch Alarms for infrastructure
- Auto-scaling policies based on CPU/memory
- Email/Slack notifications

### Logging
- CloudWatch Logs for centralized logging
- Application logs: `/aws/decoryou/{environment}/app`
- 30-day retention (configurable per environment)

---

## 📝 CI/CD Pipeline Stages

### Jenkinsfile (Main Pipeline)

```
Checkout
  ↓
Lint (Terraform, Ansible, Docker)
  ↓
Security Scan (tfsec, checkov, git-secrets)
  ↓
Test (Unit tests)
  ↓
Docker Build & Push → ECR
  ↓
Terraform Plan
  ↓
Terraform Apply (auto for dev, manual for prod)
  ↓
Ansible Deploy
  ↓
Smoke Tests
  ↓
Notifications (Slack)
```

### Jenkinsfile.pr (Pull Request Pipeline)

```
Checkout
  ↓
Lint & Format Check
  ↓
Security Scans
  ↓
Terraform Validation
  ↓
Docker Build (no push)
  ↓
Unit Tests
```

---

## 🛠️ Common Operations

### View Infrastructure Status
```bash
make status
```

### Format Code
```bash
make fmt
make tf-fmt
make ansible-syntax
```

### Security Audit
```bash
make security-scan
```

### View Logs
```bash
# Docker Compose logs
make docker-compose-logs

# AWS CloudWatch logs
aws logs tail /aws/decoryou/dev/app --follow
```

### Scale Infrastructure
```bash
# Update desired capacity in environments/{env}/terraform.tfvars
# desired_capacity = 3
make plan ENVIRONMENT=prod
make apply ENVIRONMENT=prod
```

---

## 📦 Dependencies

- **Terraform**: >= 1.5.0
- **Ansible**: >= 2.10
- **Docker**: >= 20.0
- **Python**: >= 3.8 (for Ansible)

### Optional Tools
- `tfsec`: Terraform security scanner
- `checkov`: IaC policy checker
- `ansible-lint`: Ansible playbook linter
- `hadolint`: Dockerfile linter

---

## 🆘 Troubleshooting

### Docker Compose Won't Start
```bash
docker-compose down -v
docker-compose up --build
```

### Terraform State Locked
```bash
cd terraform
terraform force-unlock LOCK_ID
```

### Application Health Check Failing
```bash
docker-compose logs app
curl http://localhost:8080/health -v
```

### Jenkins Pipeline Failing
1. Check Jenkins logs: `jenkins/logs/`
2. Verify credentials in Jenkins Credentials Store
3. Validate Jenkinsfile: `jenkins/Jenkinsfile`

---

## 📞 Support & Contact

- **DevOps Team**: devops@company.com
- **Documentation**: See `/docs` folder
- **Issues**: See GitHub Issues/Jira
- **Slack**: #devops-decoryou

---

## 📄 License

Proprietary - All rights reserved

---

**Last Updated**: March 2026  
**Maintained By**: DevOps Team  
**Status**: ✅ Production Ready
