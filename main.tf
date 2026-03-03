# ECR Repository для Docker образов
resource "aws_ecr_repository" "decoryou" {
  name                 = "decoryou"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
}

# IAM роль для EKS кластера
resource "aws_iam_role" "eks_cluster" {
  name = "decoryou-eks-cluster"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

# Прикрепляем политику AmazonEKSClusterPolicy к роли
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# EKS Cluster (упрощённый для демонстрации)
resource "aws_eks_cluster" "decoryou" {
  name     = "decoryou-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.30"

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]
}

