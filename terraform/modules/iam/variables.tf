######################################################################
# IAM MODULE - Variables
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

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = ""
}

variable "eks_oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  type        = string
  default     = ""
}

variable "eks_oidc_provider_id" {
  description = "EKS OIDC provider ID"
  type        = string
  default     = ""
}

variable "create_eks_role" {
  description = "Create EKS cluster role"
  type        = bool
  default     = false
}

variable "create_irsa_role" {
  description = "Create IRSA IAM role"
  type        = bool
  default     = false
}

variable "create_ecr_policy" {
  description = "Create ECR push/pull policy"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
