######################################################################
# S3 MODULE - Outputs
######################################################################

output "app_bucket_id" {
  description = "ID of application S3 bucket"
  value       = var.create_app_bucket ? aws_s3_bucket.app[0].id : null
}

output "app_bucket_arn" {
  description = "ARN of application S3 bucket"
  value       = var.create_app_bucket ? aws_s3_bucket.app[0].arn : null
}

output "terraform_state_bucket_id" {
  description = "ID of Terraform state S3 bucket"
  value       = var.create_terraform_state_bucket ? aws_s3_bucket.terraform_state[0].id : null
}

output "terraform_state_bucket_arn" {
  description = "ARN of Terraform state S3 bucket"
  value       = var.create_terraform_state_bucket ? aws_s3_bucket.terraform_state[0].arn : null
}

output "artifacts_bucket_id" {
  description = "ID of artifacts S3 bucket"
  value       = var.create_artifacts_bucket ? aws_s3_bucket.artifacts[0].id : null
}

output "artifacts_bucket_arn" {
  description = "ARN of artifacts S3 bucket"
  value       = var.create_artifacts_bucket ? aws_s3_bucket.artifacts[0].arn : null
}
