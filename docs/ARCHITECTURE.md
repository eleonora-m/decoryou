# 🏗️ Architecture Documentation

## System Architecture Overview

The Decoryou platform is built on a multi-tiered, highly available architecture running on AWS with containerized applications, scalable computing, and comprehensive monitoring.

---

## High-Level Components

### 1. **Network Layer (VPC)**
- **VPC CIDR**: 10.0.0.0/16 (dev), 10.1.0.0/16 (staging), 10.2.0.0/16 (prod)
- **Public Subnets**: 3 across AZs (one per availability zone)
- **Private Subnets**: 3 across AZs
- **NAT Gateways**: 1 per AZ for private subnet egress
- **Internet Gateway**: Single entry point for public traffic
- **Security Groups**: ALB, EC2, Database, and service-specific groups

### 2. **Compute Layer (EC2 + Auto Scaling)**
- **Instance Type**: t3.small (dev) → t3.large (prod)
- **Auto Scaling Group**: Min 1, Desired 2, Max 4 instances (configurable)
- **Launch Template**: Contains Docker configuration, CloudWatch agent, IAM role
- **Scaling Policies**: CPU-based (threshold: 70% up, 30% down)
- **Health Checks**: ELB-based with 300s grace period

### 3. **Load Balancing (ALB)**
- **Application Load Balancer**: Layer 7 HTTP/HTTPS
- **Target Groups**: Health check every 30s, 2 healthy threshold
- **Listeners**: HTTP (80) and HTTPS (443, with auto-generated certs)
- **Cross-Zone**: Enabled for optimal distribution

### 4. **Storage Layer**

#### S3 Buckets
- **Application Data**: Versioned, encrypted, access-blocked
- **Terraform State**: Remote state with DynamoDB locking
- **Build Artifacts**: Jenkins builds and Docker layers

#### Database (RDS MySQL or EC2)
- **Engine**: MySQL 8.0
- **Multi-AZ**: Yes (production)
- **Backups**: Daily snapshots, 30-day retention
- **Encryption**: AES-256 at rest

#### Cache (Redis/ElastiCache optional)
- **Purpose**: Session store, caching layer
- **Nodes**: 1 (dev) → 3 (prod cluster)
- **Encryption**: In-transit and at rest

### 5. **Container Registry (ECR)**
- **Image Scanning**: On push, identifying vulnerabilities
- **Tagging**: Latest, version tags (v1.0.0, etc.)
- **Lifecycle Policy**: Keep last 30 images, delete older

### 6. **Monitoring & Observability**

#### CloudWatch
- **Application Logs**: `/aws/decoryou/{environment}/app`
- **Alarms**: CPU, memory, ALB metrics
- **Dashboards**: Environment-specific views

#### Prometheus
- **Scrape Interval**: 15 seconds
- **Storage**: Local TSDB with 15-day retention
- **Targets**: Application, nodes, containers, databases

#### Grafana
- **Datasources**: Prometheus configured
- **Dashboards**: Pre-built for system and app metrics
- **Authentication**: Admin/grafana (change in production)

---

## Data Flow Architecture

```
┌─────────────────────┐
│   External Users    │
│   (Internet)        │
└──────────────┬──────┘
               │
               ▼
        [Internet Gateway]
               │
        ┌──────┴──────┐
        │             │
        ▼             ▼
    [Public Subnet]  [Public Subnet]
        │                │
        ▼                ▼
    [ALB 80/443]    [ALB 80/443]
        │                │
        └────────┬───────┘
                 │
        [Target Group]
                 │
    ┌────────────┼────────────┐
    │            │            │
    ▼            ▼            ▼
[EC2-1]      [EC2-2]       [EC2-3]
 Docker       Docker        Docker
  App          App           App
    │            │            │
    └────────────┼────────────┘
                 │
        ┌────────┴─────────┐
        │                  │
        ▼                  ▼
    [RDS MySQL]       [S3 Storage]
    [Redis/Cache]
```

---

## Security Architecture

### Network Security
```
┌─────────────────────────┐
│  Internet (0.0.0.0/0)   │
└──────────┬──────────────┘
           │
    ┌──────▼──────┐
    │[ALB-SG]     │  Port 80/443 ← Internet
    └──────┬──────┘
           │
    ┌──────▼──────┐
    │[App-SG]     │  Port 80 ← ALB only
    └──────┬──────┘
           │
    ┌──────▼──────┐
    │  EC2 Inst.  │
    │  (Docker)   │
    └─────────────┘
    
┌────────────────────┐
│[DB-SG]             │  Port 3306 ← App-SG
└────────────────────┘
```

### IAM Architecture
```
┌──────────────────────────────────────┐
│      EC2 Instance Role                │
├──────────────────────────────────────┤
│ • AssumeRole: EC2 Service            │
│ • ECR Pull: decoryou/* repositories  │
│ • CloudWatch Logs: app/* streams     │
│ • S3 GetObject: decoryou-* buckets   │
└──────────────────────────────────────┘
```

---

## Deployment Architecture

### Infrastructure as Code (Terraform)
```
main.tf
├─ module "vpc"        → VPC, Subnets, Routes
├─ module "iam"        → Roles, Policies, Profiles
├─ module "s3"         → Buckets, Versioning, Encryption
├─ module "ec2"        → Launch Template, ASG, Alarms
├─ aws_lb              → Load Balancer
├─ aws_lb_target_group → Health Checks
└─ aws_cloudwatch_log_group → Application Logs
```

### Configuration Management (Ansible)
```
site.yml
├─ common role         → OS updates, system tools, monitoring agent
├─ docker role         → Docker install, ECR login, network setup
└─ app role            → Container deployment, health checks
```

### CI/CD (Jenkins)
```
Jenkinsfile
├─ Checkout           → Git clone
├─ Lint               → Format checks
├─ Security Scan      → tfsec, checkov
├─ Test               → Unit tests
├─ Docker Build/Push  → ECR push
├─ Terraform Plan     → Infrastructure diff
├─ Terraform Apply    → Infrastructure update
├─ Ansible Deploy     → Application deployment
├─ Smoke Tests        → Validation
└─ Notifications      → Slack
```

---

## Environment Configurations

### Development
- **Instance**: t3.small (1 vCPU, 2 GB RAM)
- **Capacity**: Min 1, Desired 1, Max 2
- **Logging**: 7-day retention
- **Monitoring**: Basic
- **Backups**: Daily snapshots

### Staging
- **Instance**: t3.medium (2 vCPU, 4 GB RAM)
- **Capacity**: Min 2, Desired 2, Max 4
- **Logging**: 14-day retention
- **Monitoring**: Enhanced
- **Backups**: Daily snapshots, cross-region copy

### Production
- **Instance**: t3.large (2 vCPU, 8 GB RAM)
- **Capacity**: Min 3, Desired 3, Max 6
- **Logging**: 90-day retention
- **Monitoring**: Full stack + alerting
- **Backups**: Hourly snapshots, multi-region replication
- **HA**: Multi-AZ, health checks, auto-recovery
- **Compliance**: VPC Flow Logs, encryption, audit logging

---

## Scaling & Performance

### Horizontal Scaling
- **ASG Policies**: CPU threshold-based
- **ALB**: Distributes across healthy instances
- **Database**: Should scale separately (RDS)

### Vertical Scaling
- Modify `instance_type` in environment tfvars
- Update security group rules if needed

### Limits
- VPC: Max 5 (increase via AWS Support)
- ASG: Max 20 instances (soft limit)
- ALB: Max 1000 requests/second per target
- RDS: Instance types limit (check AWS docs)

---

## Disaster Recovery

### RTO/RPO Targets
- **Dev**: RTO 4hrs, RPO 1 day
- **Staging**: RTO 2hrs, RPO 4 hours
- **Production**: RTO 1hr, RPO 15 minutes

### Backup Strategy
1. **Database**: Daily snapshots (7-day retention)
2. **S3**: Versioning enabled, cross-region replication
3. **Application**: Stateless, can restart from image
4. **Configuration**: All in Git (Terraform/Ansible)

### Recovery Procedures
```bash
# Restore from database snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier decoryou-restored \
  --db-snapshot-identifier decoryou-snapshot-20240301

# Redeploy infrastructure
make apply ENVIRONMENT=prod

# Redeploy application
make ansible-deploy ENVIRONMENT=prod
```

---

## Cost Optimization

### Current Monthly (Production)
- **EC2**: $150/month (3x t3.large)
- **ALB**: $20/month
- **RDS**: $100/month (db.t3.medium)
- **S3**: $10/month (application data)
- **Data Transfer**: $20/month (egress)
- **Total**: ~$300/month

### Optimization Opportunities
1. Use Reserved Instances (30-40% savings)
2. Spot Instances for non-critical workloads
3. S3 Intelligent-Tiering for archival
4. RDS Aurora for better price/performance

---

## Capacity Planning

### Current Load
- Average: 100 requests/minute
- Peak: 500 requests/minute
- Response: <200ms p95

### Projected (Year 1)
- 5x traffic growth expected
- May need to scale to t3.xlarge or use autoscaling more aggressively
- Database: Consider read replicas

### Recommendations
- Implement database query optimization
- Add CDN for static assets
- Implement caching layer (Redis)
- Monitor metrics monthly

---

## References

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS VPC Best Practices](https://docs.aws.amazon.com/vpc/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

---

**Last Updated**: March 2026 | **Version**: 1.0
