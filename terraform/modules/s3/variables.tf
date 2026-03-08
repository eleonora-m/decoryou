######################################################################
# S3 MODULE - Variables
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

variable "create_app_bucket" {
  description = "Create application S3 bucket"
  type        = bool
  default     = true
}

variable "create_terraform_state_bucket" {
  description = "Create Terraform state S3 bucket"
  type        = bool
  default     = true
}

variable "create_artifacts_bucket" {
  description = "Create artifacts S3 bucket"
  type        = bool
  default     = true
}

variable "enable_versioning" {
  description = "Enable versioning on buckets"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable encryption on buckets"
  type        = bool
  default     = true
}

variable "enable_mfa_delete" {
  description = "Enable MFA delete on buckets"
  type        = bool
  default     = false
}

variable "enable_public_access_block" {
  description = "Enable public access block"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
