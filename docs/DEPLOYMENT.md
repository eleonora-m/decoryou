# 📊 Deployment Guide

Complete step-by-step guide for deploying decoryou to AWS environments.

---

## Prerequisites

### Required Tools
```bash
# Verify installations
terraform version           # >= 1.5.0
ansible --version          # >= 2.10
docker --version           # >= 20.0
aws --version              # >= 2.0.0
git --version             # >= 2.0.0
```

### AWS Credentials
```bash
# Configure AWS CLI
aws configure

# Verify access
aws sts get-caller-identity
aws s3 ls  # Should work without error
```

### Repository Access
```bash
# Clone the repository
git clone https://github.com/your-org/decoryou.git
cd decoryou

# Create and populate .env
cp .env.example .env
# Edit .env with your values
```

---

## Local Development Deployment

### Option 1: Docker Compose (Fastest)

```bash
# Start full stack
make docker-compose-up

# Verify services
docker-compose ps

# Access applications
echo "App: http://localhost:8080"
echo "Grafana: http://localhost:3000"
echo "Prometheus: http://localhost:9090"
echo "MinIO: http://localhost:9001"

# View logs
make docker-compose-logs

# Stop stack
make docker-compose-down
```

### Option 2: Local Infrastructure

```bash
# Initialize Terraform
make tf-init ENVIRONMENT=dev

# Validate configuration
make tf-validate

# Create plan
make plan ENVIRONMENT=dev

# Review tfplan.dev in editor, then apply
make apply ENVIRONMENT=dev
```

---

## AWS Deployment - Step by Step

### Step 1: Prepare AWS Account

```bash
# 1. Create S3 bucket for Terraform state
aws s3 mb s3://decoryou-terraform-state-dev

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket decoryou-terraform-state-dev \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket decoryou-terraform-state-dev \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# 2. Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name decoryou-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

# 3. Create EC2 Key Pair
aws ec2 create-key-pair --key-name decoryou-dev \
  --query 'KeyMaterial' --output text > ~/.ssh/decoryou-dev.pem
chmod 600 ~/.ssh/decoryou-dev.pem
```

### Step 2: Configure Terraform

```bash
# 1. Update environment variables file
cat > terraform/environments/dev/terraform.tfvars << EOF
aws_region          = "us-east-1"
environment         = "dev"
project_name        = "decoryou"
key_pair_name       = "decoryou-dev"
instance_type       = "t3.small"
desired_capacity    = 1
EOF

# 2. Verify the configuration
cd terraform
terraform fmt -recursive .  # Format code
terraform validate          # Check syntax
```

### Step 3: Deploy Infrastructure

```bash
# Initialize Terraform with remote backend
make tf-init ENVIRONMENT=dev

# Generate and review plan
make plan ENVIRONMENT=dev

# Review the plan
# - Check resource count
# - Verify names and configurations
# - Look for any unexpected changes

# Apply infrastructure
make apply ENVIRONMENT=dev

# Terraform will show proposed changes
# Review and type 'yes' to confirm

# Verify deployment
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=dev" \
  --query 'Reservations[*].Instances[0].{ID:InstanceId, IP:PrivateIpAddress, State:State.Name}'
```

### Step 4: Deploy Application with Ansible

```bash
# 1. Create Ansible inventory from EC2 instances
# (Manually or using dynamic inventory plugin)

# 2. Test connectivity
ansible-inventory -i ansible/inventories/dev/hosts.yml --list

# 3. Ping all hosts
ansible all -i ansible/inventories/dev/hosts.yml -m ping

# 4. Run Ansible playbook
make ansible-deploy ENVIRONMENT=dev

# 5. Verify deployment
curl http://$(make output ENVIRONMENT=dev | jq -r '.alb_dns_name')/health
```

### Step 5: Verify Deployment

```bash
# Get load balancer DNS
ALB_DNS=$(aws elb describe-load-balancers \
  --load-balancer-names decoryou-alb-dev \
  --query 'LoadBalancerDescriptions[0].DNSName' \
  --output text)

# Test application endpoints
curl -v http://$ALB_DNS/health
curl -v http://$ALB_DNS/api/status

# Check CloudWatch logs
aws logs tail /aws/decoryou/dev/app --follow

# View Grafana dashboard
echo "Open: http://$ALB_DNS:3000"
```

---

## Environment Promotion

### Dev → Staging

```bash
# 1. Create staging configuration
cp -r terraform/environments/dev/* \
    terraform/environments/staging/

# Update tfvars for staging
vi terraform/environments/staging/terraform.tfvars

# 2. Create branch
git checkout -b feature/staging-env

# 3. Deploy to staging
make plan ENVIRONMENT=staging
make apply ENVIRONMENT=staging
make ansible-deploy ENVIRONMENT=staging

# 4. Run full test suite
make test

# 5. Push to origin
git push origin feature/staging-env

# 6. Open Pull Request for review
# (CI/CD will validate)
```

### Staging → Production (Manual Process)

```bash
# 1. Tag release
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# 2. Create production configuration
cp terraform/environments/staging/* \
    terraform/environments/prod/

# Update tfvars for production
vi terraform/environments/prod/terraform.tfvars

# 3. Create PR for production
git checkout -b release/v1.0.0-prod

# 4. Plan production deployment
make plan ENVIRONMENT=prod

# 5. Get approval from tech lead

# 6. Apply to production (after approval)
make apply ENVIRONMENT=prod
make ansible-deploy ENVIRONMENT=prod

# 7. Run comprehensive smoke tests
curl http://$(make output ENVIRONMENT=prod | jq -r '.application_url')/health
```

---

## Rolling Deployments

### Zero-Downtime Updates

```bash
# 1. Build new Docker image
docker build -f docker/Dockerfile \
  -t decoryou:v1.1.0 .

# 2. Push to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_REGISTRY

docker tag decoryou:v1.1.0 $ECR_REGISTRY/decoryou:v1.1.0
docker push $ECR_REGISTRY/decoryou:v1.1.0

# 3. Update ASG launch template
# Edit: terraform/environments/{env}/terraform.tfvars
# Change: docker_image = "decoryou:v1.1.0"

# 4. Plan and apply
make plan ENVIRONMENT=prod
make apply ENVIRONMENT=prod

# This will:
# - Create new launch template version
# - Refresh ASG instances one at a time
# - Terminate old instances and launch new ones
# - ALB keeps traffic off unhealthy instances

# 5. Monitor during update
watch -n 5 'aws autoscaling describe-auto-scaling-instances \
  --auto-scaling-group-names decoryou-asg-prod \
  --query "AutoScalingInstances[].{Instance:InstanceId, Health:HealthStatus}"'

# 6. Verify health
curl http://ALB_DNS/health
```

---

## Monitoring Deployment Health

### CloudWatch Dashboard

```bash
# View logs in real-time
aws logs tail /aws/decoryou/prod/app --follow

# Check specific errors
aws logs filter-log-events \
  --log-group-name /aws/decoryou/prod/app \
  --filter-pattern "ERROR"

# Get metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --statistics Average \
  --start-time 2024-03-01T00:00:00Z \
  --end-time 2024-03-02T00:00:00Z \
  --period 300
```

### Application Health

```bash
# Health check endpoint
curl -v http://ALB_DNS/health

# Detailed health status
curl -s http://ALB_DNS/api/status | jq .

# Check application logs
tail -f logs/app.log

# CPU and memory usage
docker stats

# Database connectivity
mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD \
  -e "SELECT COUNT(*) as uptime FROM information_schema.tables LIMIT 1;"
```

---

## Rollback Procedures

### Application Rollback

```bash
# 1. Revert to previous image
vi terraform/environments/prod/terraform.tfvars
# Change: docker_image = "decoryou:v1.0.0"

# 2. Re-apply infrastructure
make apply ENVIRONMENT=prod

# This creates new launch template and refreshes instances
```

### Infrastructure Rollback

```bash
# 1. Revert Terraform code to previous version
git log --oneline terraform/
git show COMMIT_HASH:terraform/main.tf > terraform/main.tf

# 2. Re-apply
make apply ENVIRONMENT=prod

# 3. Alternative: Use Terraform backup
aws s3 cp s3://decoryou-terraform-state-prod/prod/terraform.tfstate.backup .
terraform state pull > backup_state.json
# Review and restore if needed
```

### Database Rollback

```bash
# 1. List available snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier decoryou-prod \
  --query 'DBSnapshots[].{ID:DBSnapshotIdentifier, Time:SnapshotCreateTime}'

# 2. Restore to point-in-time
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier decoryou-prod \
  --target-db-instance-identifier decoryou-prod-restored \
  --restore-time 2024-03-01T12:00:00Z

# 3. Update RDS endpoint in application config
# 4. Restart application containers
```

---

## Security Validation

Before deploying to production:

```bash
# 1. Run security scans
make security-scan

# 2. Check for hardcoded secrets
git secrets --scan

# 3. Verify IAM policies
aws iam get-role --role-name decoryou-ec2-instance \
  --query 'Role.AssumeRolePolicyDocument'

# 4. Validate security groups
aws ec2 describe-security-groups \
  --filters Name=group-name,Values=decoryou-app-sg-prod \
  --query 'SecurityGroups[0].IpPermissions'

# 5. Check encryption
aws s3 get-bucket-encryption --bucket decoryou-app-prod-* \
  --query 'ServerSideEncryptionConfiguration'
```

---

## Troubleshooting

### Deployment Fails at Terraform Apply

```bash
# 1. Check AWS credentials
aws sts get-caller-identity

# 2. Verify state file
cd terraform
terraform state list
terraform state show aws_instance.app

# 3. Check resource dependencies
terraform graph | grep -A5 "resource"

# 4. View detailed logs
TF_LOG=DEBUG terraform apply -var-file=environments/dev/terraform.tfvars

# 5. Force unlock if state is locked
terraform force-unlock LOCK_ID
```

### Ansible Playbook Hangs

```bash
# 1. Check connectivity
ansible -i inventories/dev/hosts.yml all -m ping

# 2. View detailed output
ansible-playbook -vvv site.yml

# 3. Check SSH key permissions
chmod 600 ~/.ssh/decoryou-*.pem

# 4. Verify security groups allow SSH
aws ec2 describe-security-groups \
  --group-ids sg-... \
  --query 'SecurityGroups[0].IpPermissions[?FromPort==`22`]'
```

### Application Health Checks Fail

```bash
# 1. SSH into instance
ssh -i ~/.ssh/decoryou-dev.pem ec2-user@INSTANCE_IP

# 2. Check Docker containers
docker ps -a
docker logs app

# 3. Check application logs
tail -f /var/log/decoryou/app.log

# 4. Test health endpoint locally
curl http://localhost:80/health -v

# 5. Check network connectivity
nc -zv $ALB_IP 80
```

---

## Cleanup

```bash
# 1. Destroy infrastructure
make destroy ENVIRONMENT=dev

# 2. Delete S3 buckets (if needed)
aws s3 rm s3://decoryou-app-dev-ACCOUNT_ID --recursive
aws s3 rb s3://decoryou-app-dev-ACCOUNT_ID

# 3. Delete RDS snapshots
aws rds delete-db-snapshot \
  --db-snapshot-identifier decoryou-dev-snapshot

# 4. Delete CloudWatch logs
aws logs delete-log-group \
  --log-group-name /aws/decoryou/dev/app
```

---

**Last Updated**: March 2026 | **Version**: 1.0
