######################################################################
# DECORYOU PROJECT - TERRAFORM VARIABLES
######################################################################

# ============================================================================
# GENERAL CONFIGURATION
# ============================================================================
variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-2"
  validation {
    condition     = can(regex("^us-|^eu-|^ap-", var.aws_region))
    error_message = "AWS region must be valid (e.g., us-east-2, eu-west-2)"
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "decoryou"
  validation {
    condition     = length(var.project_name) <= 32 && can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric with hyphens"
  }
}

variable "owner" {
  description = "Owner responsible for the infrastructure"
  type        = string
  default     = "Eleonora"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "engineering"
}

# ============================================================================
# VPC & NETWORKING
# ============================================================================
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "ssh_cidr_blocks" {
  description = "Allowed CIDR for SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ============================================================================
# EC2 CONFIGURATION
# ============================================================================
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ami_id" {
  description = "AMI ID for EC2"
  type        = string
  default     = "ami-05fb0b8c1424f266b" # Актуально для us-east-2
}

variable "key_pair_name" {
  description = "EC2 Key Pair name"
  type        = string
  default     = "decoryou-keypair"
}

# ============================================================================
# EC2 AUTO SCALING CONFIGURATION
# ============================================================================
variable "desired_capacity" {
  description = "Desired number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 4
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring for EC2 instances"
  type        = bool
  default     = false
}

# ============================================================================
# APP & S3 CONFIGURATION
# ============================================================================
variable "app_port" {
  description = "Application port"
  type        = number
  default     = 80
}

variable "docker_image" {
  description = "Docker image URI"
  type        = string
  default     = "nginx:latest"
}

variable "s3_enable_versioning" {
  description = "Enable versioning for S3 buckets"
  type        = bool
  default     = true
}

variable "create_s3_app_bucket" {
  description = "Whether to create the application S3 bucket"
  type        = bool
  default     = true
}

variable "create_terraform_state_bucket" {
  description = "Whether to create the Terraform state S3 bucket"
  type        = bool
  default     = false
}

variable "create_artifacts_bucket" {
  description = "Whether to create the artifacts S3 bucket"
  type        = bool
  default     = true
}

variable "s3_enable_encryption" {
  description = "Enable server-side encryption for S3 buckets"
  type        = bool
  default     = true
}

variable "s3_enable_mfa_delete" {
  description = "Enable MFA delete protection on S3 buckets"
  type        = bool
  default     = false
}

# ============================================================================
# ALB CONFIGURATION
# ============================================================================
variable "enable_alb_deletion_protection" {
  description = "Enable deletion protection on the Application Load Balancer"
  type        = bool
  default     = true
}

# ============================================================================
# EKS CONFIGURATION
# ============================================================================
variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "decoryou-eks"
}

variable "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider for IAM roles"
  type        = string
  default     = ""
}

# ============================================================================
# CLOUDWATCH / LOGGING
# ============================================================================
variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a valid CloudWatch retention period."
  }
}

# ============================================================================
# COMMON TAGS
# ============================================================================
variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Terraform = "true"
    Project   = "decoryou"
  }
}