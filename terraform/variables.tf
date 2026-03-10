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
  default     = "ami-0c94855ba95c574c8"
}

variable "key_pair_name" {
  description = "EC2 Key Pair name"
  type        = string
  default     = "decoryou-keypair"
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
  type    = bool
  default = true
}

variable "common_tags" {
  type = map(string)
  default = {
    Terraform = "true"
    Project   = "decoryou"
  }
}