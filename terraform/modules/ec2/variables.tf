######################################################################
# EC2 MODULE - Variables
######################################################################

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for ASG"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
}

variable "key_pair_name" {
  description = "EC2 Key Pair name"
  type        = string
}

variable "desired_capacity" {
  description = "Desired capacity for ASG"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum size for ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum size for ASG"
  type        = number
  default     = 4
}

variable "security_group_ids" {
  description = "Security group IDs"
  type        = list(string)
}

variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type        = string
}

variable "docker_image" {
  description = "Docker image URI"
  type        = string
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 80
}

variable "enable_monitoring" {
  description = "Enable CloudWatch detailed monitoring"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
