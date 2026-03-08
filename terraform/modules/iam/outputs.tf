######################################################################
# IAM MODULE - Outputs
######################################################################

output "ec2_instance_role_arn" {
  description = "ARN of EC2 instance role"
  value       = aws_iam_role.ec2_instance.arn
}

output "ec2_instance_role_name" {
  description = "Name of EC2 instance role"
  value       = aws_iam_role.ec2_instance.name
}

output "ec2_instance_profile_name" {
  description = "Name of EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_instance.name
}

output "eks_cluster_role_arn" {
  description = "ARN of EKS cluster role"
  value       = var.create_eks_role ? aws_iam_role.eks_cluster[0].arn : null
}

output "eks_irsa_role_arn" {
  description = "ARN of EKS IRSA role"
  value       = var.create_irsa_role ? aws_iam_role.eks_irsa[0].arn : null
}
