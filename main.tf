cat > main.tf << 'EOF'
# ECR Repository
resource "aws_ecr_repository" "decoryou" {
  name                 = "decoryou"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

# IAM роль
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

# IAM Policy Attachment
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# EKS Cluster
resource "aws_eks_cluster" "decoryou" {
  name                      = "decoryou-cluster"
  role_arn                  = aws_iam_role.eks_cluster.arn
  version                   = "1.30"
  vpc_config {
    subnet_ids              = ["subnet-01234567", "subnet-01234568"]
    endpoint_private_access = false
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }
  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}
EOF
