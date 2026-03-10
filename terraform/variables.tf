######################################################################
# DECORYOU PROJECT - TERRAFORM VARIABLES
# Define all variables for infrastructure provisioning
######################################################################

# ============================================================================
# GENERAL CONFIGURATION
# ============================================================================

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^us-|^eu-|^ap-", var.aws_region))
    error_message = "AWS region must be valid (e.g., us-east-1, eu-west-1, ap-southeast-1)"
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"  # Добавь эту строку!

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
    error_message = "Project name must be lowercase alphanumeric with hyphens, max 32 characters"
  }
}

variable "owner" {
  description = "Owner/Team responsible for the infrastructure"
  type        = string
  default     = "DevOps Team"
}

variable "cost_center" {
  description = "Cost center for billing and resource tracking"
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

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block"
  }
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Must specify at least 2 availability zones"
  }
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
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway for VPN connections"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs for network monitoring"
  type        = bool
  default     = true
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this in production!
}

# ============================================================================
# EC2 CONFIGURATION
# ============================================================================

variable "instance_type" {
  description = "EC2 instance type for application servers"
  type        = string
  default     = "t3.medium"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances (Amazon Linux 2 with Docker)"
  type        = string
  default     = "ami-0c94855ba95c574c8"  # Example - use your own
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = "decoryou-keypair"
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances in ASG"
  type        = number
  default     = 2

  validation {
    condition     = var.desired_capacity >= 1 && var.desired_capacity <= 10
    error_message = "Desired capacity must be between 1 and 10"
  }
}

variable "min_size" {
  description = "Minimum number of EC2 instances in ASG"
  type        = number
  default     = 1

  validation {
    condition     = var.min_size >= 1
    error_message = "Min size must be at least 1"
  }
}

variable "max_size" {
  description = "Maximum number of EC2 instances in ASG"
  type        = number
  default     = 4

  validation {
    condition     = var.max_size <= 20
    error_message = "Max size must not exceed 20"
  }
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

# ============================================================================
# APPLICATION CONFIGURATION
# ============================================================================

variable "app_port" {
  description = "Port on which the application listens"
  type        = number
  default     = 80

  validation {
    condition     = var.app_port >= 1 && var.app_port <= 65535
    error_message = "App port must be between 1 and 65535"
  }
}

variable "docker_image" {
  description = "Docker image URI for the application"
  type        = string
  default     = "nginx:latest"
}

# ============================================================================
# LOAD BALANCER CONFIGURATION
# ============================================================================

variable "enable_alb_deletion_protection" {
  description = "Enable deletion protection on ALB"
  type        = bool
  default     = true
}

# ============================================================================
# S3 CONFIGURATION
# ============================================================================

variable "create_s3_app_bucket" {
  description = "Create S3 bucket for application storage"
  type        = bool
  default     = true
}

variable "create_terraform_state_bucket" {
  description = "Create S3 bucket for Terraform state"
  type        = bool
  default     = true
}

variable "create_artifacts_bucket" {
  description = "Create S3 bucket for build artifacts"
  type        = bool
  default     = true
}

variable "s3_enable_versioning" {
  description = "Enable versioning on S3 buckets"
  type        = bool
  default     = true
}

variable "s3_enable_encryption" {
  description = "Enable encryption on S3 buckets"
  type        = bool
  default     = true
}

variable "s3_enable_mfa_delete" {
  description = "Enable MFA delete on S3 buckets"
  type        = bool
  default     = false  # Set to true in production
}

# ============================================================================
# EKS CONFIGURATION (if using EKS)
# ============================================================================

variable "eks_cluster_name" {
  description = "Name of existing EKS cluster"
  type        = string
  default     = "decoryou-cluster"
}

variable "eks_oidc_provider_arn" {
  description = "ARN of EKS OIDC provider for IRSA"
  type        = string
  default     = ""
}

# ============================================================================
# LOGGING & MONITORING
# ============================================================================

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch value"
  }
}

variable "enable_enhanced_monitoring" {
  description = "Enable enhanced monitoring and logging"
  type        = bool
  default     = true
}

# ============================================================================
# TAGS
# ============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform = "true"
    Version   = "1.7.0"
  }
}