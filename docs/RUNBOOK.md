# 🔧 Operational Runbook

Incident response, troubleshooting, and operational procedures for the Decoryou platform.

---

## Table of Contents

1. [Incident Response](#incident-response)
2. [Health Checks](#health-checks)
3. [Scaling Operations](#scaling-operations)
4. [Backup & Recovery](#backup--recovery)
5. [Maintenance](#maintenance)
6. [Common Issues](#common-issues)

---

## Incident Response

### Response Workflow

```
ALERT → INVESTIGATE → MITIGATE → FIX → VERIFY → POST-MORTEM
```

### 1. Service Down (Critical)

**Detection**: Health checks fail for > 2 minutes

**Initial Assessment (2 min)**

```bash
# Check ALB status
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:... \
  --query 'TargetHealthDescriptions[?TargetHealth.State!=`healthy`]'

# Check ASG status
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names decoryou-asg-prod \
  --query 'AutoScalingGroups[0].[MinSize,MaxSize,DesiredCapacity,Instances[].{ID:InstanceId,State:LifecycleState}]'

# Check application logs
aws logs filter-log-events \
  --log-group-name /aws/decoryou/prod/app \
  --filter-pattern "ERROR" \
  --start-time $(date -d '5 minutes ago' +%s)000
```

**Investigation (5-10 min)**

1. **Check Application Status**
   ```bash
   # SSH into instance
   ssh -i ~/.ssh/decoryou-prod.pem ec2-user@INSTANCE_IP
   
   # Check Docker containers
   docker ps -a
   
   # Check application logs
   docker logs decoryou-app --tail 100
   
   # Check resource usage
   docker stats
   free -h
   df -h
   ```

2. **Check AWS Services**
   ```bash
   # RDS status
   aws rds describe-db-instances \
     --db-instance-identifier decoryou-prod \
     --query 'DBInstances[0].DBInstanceStatus'
   
   # Network ACLs
   aws ec2 describe-network-acls \
     --filters Name=vpc-id,Values=vpc-...
   
   # Security groups
   aws ec2 describe-security-groups \
     --group-ids sg-...
   ```

3. **Check Metrics**
   ```bash
   # CPU usage
   aws cloudwatch get-metric-statistics \
     --namespace AWS/EC2 \
     --metric-name CPUUtilization \
     --statistics Average \
     --start-time $(date -u -d '10 minutes ago' +'%Y-%m-%dT%H:%M:%S') \
     --end-time $(date -u +'%Y-%m-%dT%H:%M:%S') \
     --period 60
   
   # Network throughput
   aws cloudwatch get-metric-statistics \
     --namespace AWS/ApplicationELB \
     --metric-name requests \
     --statistics Sum
   ```

**Mitigation (Immediate)**

```bash
# Option 1: Restart single instance
aws ec2 reboot-instances --instance-ids i-...

# Option 2: Restart application container
ssh -i ~/.ssh/decoryou-prod.pem ec2-user@INSTANCE_IP
docker restart decoryou-app

# Option 3: Force instance replacement (nuclear option)
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name decoryou-asg-prod \
  --desired-capacity 1

aws ec2 terminate-instances --instance-ids i-...
# ASG will launch replacement

# Option 4: Roll back deployment
# See DEPLOYMENT.md Rollback Procedures section
```

**Verification**

```bash
# Wait for health checks
watch -n 5 'aws elbv2 describe-target-health --target-group-arn ... --query "TargetHealthDescriptions[]"'

# Test endpoint
curl -v http://ALB_DNS/health

# Check metrics return to normal
aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name TargetResponseTime ...
```

**Post-Incident**

- [ ] Document timeline
- [ ] Identify root cause
- [ ] Implement fix
- [ ] Add monitoring alert if needed
- [ ] Schedule post-mortem <2 hours after resolution

---

### 2. High CPU Usage (Warning)

**Auto-Scaling Trigger**: CPU > 70% for 2 minutes

```bash
# Check scaling history
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name decoryou-asg-prod \
  --max-records 10

# Check application performance
curl -s http://ALB_DNS/api/status | jq '.performance'

# Review application logs for slow queries
aws logs filter-log-events \
  --log-group-name /aws/decoryou/prod/app \
  --filter-pattern "duration > 5000"

# Check database performance
aws rds describe-db-instances \
  --db-instance-identifier decoryou-prod \
  --query 'DBInstances[0].PendingModifiedValues'

# Monitor CPU manually
watch -n 5 'aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --stat Average --period 60 \
  --start-time $(date -u -d "5 minutes ago" +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S)'
```

**Actions**

1. Check if scaling is happening automatically
2. If not, trigger manual scaling:
   ```bash
   aws autoscaling set-desired-capacity \
     --auto-scaling-group-name decoryou-asg-prod \
     --desired-capacity 5
   ```
3. Identify and optimize slow operations
4. Consider vertical scaling (instance type upgrade)

---

### 3. Database Connection Errors

```bash
# Check RDS status
aws rds describe-db-instances \
  --db-instance-identifier decoryou-prod

# Check security group allows app
aws ec2 describe-security-groups \
  --group-ids sg-RDS \
  --query 'SecurityGroups[0].IpIngressRules'

# Test connection from EC2
ssh -i ~/.ssh/decoryou-prod.pem ec2-user@INSTANCE_IP
mysql -h ENDPOINT -u admin -p -e "SELECT 1;"

# Check RDS connections
aws rds describe-db-instances \
  --db-instance-identifier decoryou-prod \
  --query 'DBInstances[0].EngineDefaults'

# Reboot RDS
aws rds reboot-db-instance \
  --db-instance-identifier decoryou-prod
```

---

## Health Checks

### Daily Health Check (Strategic)

Run this daily to ensure system health:

```bash
#!/bin/bash

echo "🏥 Daily Health Check"
echo "======================"

# 1. ALB status
echo -n "ALB Status: "
aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `decoryou`)].LoadBalancerArn' | xargs -I {} \
  aws elbv2 describe-target-health --target-group-arn {} --query 'length(TargetHealthDescriptions[?TargetHealth.State==`healthy`])'

# 2. ASG instances
echo -n "Running Instances: "
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names decoryou-asg-prod \
  --query 'AutoScalingGroups[0].Instances[?LifecycleState==`InService`] | length(@)'

# 3. RDS status
echo -n "RDS Database: "
aws rds describe-db-instances \
  --filters Name=db-instance-id,Values=decoryou-prod \
  --query 'DBInstances[0].DBInstanceStatus'

# 4. CloudWatch alarms
echo -n "Active Alarms: "
aws cloudwatch describe-alarms \
  --state-value ALARM --query 'length(MetricAlarms)'

# 5. Disk usage
echo "Disk Usage on Instances:"
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=prod" \
  --query 'Reservations[].Instances[].[InstanceId, PrivateIpAddress]' | \
  while read -r instance_id ip; do
    echo "  $instance_id: $(ssh -i ~/.ssh/decoryou-prod.pem ec2-user@$ip 'df -h / | tail -1' 2>/dev/null)"
  done

# 6. Application endpoint
echo -n "Application Endpoint: "
curl -s -o /dev/null -w "%{http_code}\n" http://ALB_DNS/health

echo "✅ Daily health check complete"
```

---

## Scaling Operations

### Manual Horizontal Scaling

```bash
# Increase capacity
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name decoryou-asg-prod \
  --desired-capacity 5 \
  --honor-cooldown

# Monitor scaling progress
watch -n 5 'aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names decoryou-asg-prod \
  --query "AutoScalingGroups[0].{Desired:DesiredCapacity, Running:Instances[?LifecycleState==\`InService\`]|length(@)}"'

# Wait for health checks
watch -n 5 'aws elbv2 describe-target-health --target-group-arn arn:aws:...'
```

### Vertical Scaling (Instance Type Upgrade)

```bash
# 1. Update launch template
# Edit: terraform/environments/prod/terraform.tfvars
# Change: instance_type = "t3.xlarge"

# 2. Apply changes
make apply ENVIRONMENT=prod

# 3. Monitor instance replacement
watch -n 10 'aws autoscaling describe-auto-scaling-instances \
  --auto-scaling-group-names decoryou-asg-prod \
  --query "AutoScalingInstances[].{Instance:InstanceId, InstanceType:InstanceType, State:HealthStatus}"'

# 4. Verify new instances are healthy
# (ALB will keep traffic off unhealthy instances)
```

---

## Backup & Recovery

### Backup Status Check

```bash
# RDS backups
aws rds describe-db-snapshots \
  --db-instance-identifier decoryou-prod \
  --query 'DBSnapshots | sort_by(@, &SnapshotCreateTime) | [-1]'

# S3 replication status
aws s3api get-bucket-replication \
  --bucket decoryou-app-prod-123456789

# Latest backup timestamp
aws rds describe-db-snapshots \
  --db-instance-identifier decoryou-prod \
  --query 'DBSnapshots | sort_by(@, &SnapshotCreateTime) | [-1].SnapshotCreateTime'
```

### Point-in-Time Recovery

```bash
# List available backup windows (last 30 days)
aws rds describe-db-instances \
  --db-instance-identifier decoryou-prod \
  --query 'DBInstances[0].[LatestRestorableTime, EarliestRestorableTime]'

# Restore to point-in-time
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier decoryou-prod \
  --target-db-instance-identifier decoryou-prod-restored-$(date +%s) \
  --restore-time 2024-03-01T12:00:00Z \
  --no-copy-tags-to-snapshot

# Update application to use restored database
# Test thoroughly before switching traffic
```

### S3 Object Recovery

```bash
# List deleted/old versions
aws s3api list-object-versions \
  --bucket decoryou-app-prod-123456789 \
  --prefix "data/" \
  --query 'Versions | sort_by(@, &LastModified) | [-5:]'

# Restore specific object version
aws s3api get-object \
  --bucket decoryou-app-prod-123456789 \
  --key "data/file.txt" \
  --version-id "ABC123" \
  recovered-file.txt
```

---

## Maintenance

### Monthly Tasks

- [ ] Review CloudWatch metrics and trends
- [ ] Analyze logs for errors and warnings
- [ ] Update OS patches (if using custom AMI)
- [ ] Review and optimize costs
- [ ] Risk assessment and compliance check
- [ ] Capacity planning review

### Quarterly Tasks

- [ ] Database optimization and index review
- [ ] Security audit (IAM, security groups, encryption)
- [ ] Disaster recovery test
- [ ] Upgrade Docker base images
- [ ] Review and update runbooks

### Annual Tasks

- [ ] Architecture review
- [ ] Infrastructure upgrade evaluation
- [ ] Team training and certifications
- [ ] Compliance and audit preparation

### Scheduled Maintenance Window

**Every Sunday 2:00 AM UTC**

```bash
# 1. Notify users (in-app banner)
# 2. Set maintenance mode in application
# 3. Perform necessary updates
# 4. Run health checks
# 5. Monitor for 30 minutes
# 6. Disable maintenance mode
```

---

## Common Issues

### Issue: "TargetNotFoundException" in ALB

**Cause**: Target group has no healthy targets

```bash
# Debug
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:... \
  --query 'TargetHealthDescriptions[*].[Target.Id, TargetHealth]'

# Solutions
# 1. Check security group allows ALB → EC2
# 2. Check health check path is correct
# 3. Manually test: curl http://INSTANCE_IP:80/health
# 4. Check application is running: docker ps
# 5. Reboot instance: aws ec2 reboot-instances --instance-ids i-...
```

### Issue: "Unable to assume role" in Ansible

**Cause**: Missing or incorrect AWS credentials

```bash
# Verify credentials
aws sts get-caller-identity

# Check role
aws iam get-role --role-name decoryou-ec2-instance

# Verify IAM policy
aws iam get-role-policy \
  --role-name decoryou-ec2-instance \
  --policy-name decoryou-ecr-access
```

### Issue: "State lock aquired" in Terraform

**Cause**: Another process is modifying state

```bash
# Check lock
terraform state list
terraform force-unlock LOCK_ID

# Always use remote state backend to prevent locks:
cd terraform && terraform init
```

### Issue: Ansible "Timeout waiting for privileged prompt"

**Cause**: become/sudo issues

```bash
# Verify SSH access works
ssh -i ~/.ssh/decoryou-prod.pem ec2-user@INSTANCE_IP "sudo whoami"

# Check sudoers
ansible all -become -m shell -a "visudo -c"

# Verify ansible become settings
grep "become" ansible/site.yml
```

### Issue: Docker container exits immediately

**Cause**: Application crash or misconfiguration

```bash
# Check startup logs
docker logs CONTAINER_ID

# Check resource constraints
docker inspect CONTAINER_ID | grep -A 5 "Memory"

# Check environment variables
docker exec CONTAINER_ID env

# Manually start to see error
docker run -it IMAGE_ID /bin/bash
# Then manually run app command
```

---

## Escalation Matrix

| Issue | Resolution Time | Owner | Escalation |
|-------|-----------------|-------|-----------|
| Service Down | 15 min | On-call Eng | VP Engineering |
| Degraded Performance | 1 hr | DevOps | CTO |
| Data Loss Risk | 30 min | DBA | CEO |
| Security Issue | 1 hour | SecOps | CISO |
| Deployment Failure | 2 hrs | DevOps Lead | VP Eng |

---

## Contact Information

- **On-Call**: See PagerDuty rotation
- **Slack**: #decoryou-alerts
- **Email**: devops@company.com
- **War Room**: conference room 3

---

**Last Updated**: March 2026 | **Version**: 1.0
