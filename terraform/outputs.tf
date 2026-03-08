######################################################################
# TERRAFORM OUTPUTS - Exported values from infrastructure
######################################################################

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.app.dns_name
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.app.arn
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.app.arn
}

# ASG Outputs
output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.ec2.autoscaling_group_name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = module.ec2.autoscaling_group_arn
}

# S3 Outputs
output "app_bucket_name" {
  description = "Name of application S3 bucket"
  value       = module.s3.app_bucket_id
}

output "terraform_state_bucket" {
  description = "Name of Terraform state bucket"
  value       = module.s3.terraform_state_bucket_id
}

output "artifacts_bucket" {
  description = "Name of artifacts bucket"
  value       = module.s3.artifacts_bucket_id
}

# IAM Outputs
output "ec2_instance_role_arn" {
  description = "ARN of EC2 instance role"
  value       = module.iam.ec2_instance_role_arn
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "Security group ID for ALB"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Security group ID for application servers"
  value       = aws_security_group.app.id
}

# CloudWatch Outputs
output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.app.name
}

# Connection String for Application
output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_lb.app.dns_name}"
}

# Terraform State Information
output "state_bucket_name" {
  description = "S3 bucket for Terraform state"
  value       = module.s3.terraform_state_bucket_id
}

output "state_lock_table" {
  description = "DynamoDB table for Terraform state locking"
  value       = "decoryou-terraform-locks"
}

output "deployment_summary" {
  description = "Deployment summary"
  value = {
    environment         = var.environment
    region              = var.aws_region
    vpc_id              = module.vpc.vpc_id
    alb_dns             = aws_lb.app.dns_name
    asg_name            = module.ec2.autoscaling_group_name
    app_url             = "http://${aws_lb.app.dns_name}"
  }
}
