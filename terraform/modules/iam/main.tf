######################################################################
# IAM MODULE - Main Configuration
######################################################################

# EC2 Instance Role
resource "aws_iam_role" "ec2_instance" {
  name_prefix = "${var.project_name}-ec2-instance-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "ec2_instance" {
  name_prefix = "${var.project_name}-ec2-"
  role        = aws_iam_role.ec2_instance.name
}

# Policy for EC2 to pull Docker images from ECR
resource "aws_iam_role_policy" "ec2_ecr_access" {
  name_prefix = "${var.project_name}-ecr-"
  role        = aws_iam_role.ec2_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy for CloudWatch Logs and Monitoring
resource "aws_iam_role_policy" "ec2_cloudwatch" {
  name_prefix = "${var.project_name}-cloudwatch-"
  role        = aws_iam_role.ec2_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/ec2/${var.project_name}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy for S3 access (if needed)
resource "aws_iam_role_policy" "ec2_s3_access" {
  name_prefix = "${var.project_name}-s3-"
  role        = aws_iam_role.ec2_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:List*"
        ]
        Resource = "arn:aws:s3:::${var.project_name}-*"
      }
    ]
  })
}

# Policy for Systems Manager access (for Session Manager)
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EKS Service Role (if using EKS)
resource "aws_iam_role" "eks_cluster" {
  count = var.create_eks_role ? 1 : 0
  name_prefix = "${var.project_name}-eks-cluster-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count      = var.create_eks_role ? 1 : 0
  role       = aws_iam_role.eks_cluster[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM Role for IRSA (IAM Roles for Service Accounts)
resource "aws_iam_role" "eks_irsa" {
  count = var.create_irsa_role ? 1 : 0
  name_prefix = "${var.project_name}-eks-irsa-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/oidc.eks.${var.aws_region}.amazonaws.com/id/${var.eks_oidc_provider_id}"
        }
        Condition = {
          StringEquals = {
            "oidc.eks.${var.aws_region}.amazonaws.com/id/${var.eks_oidc_provider_id}:sub" = "system:serviceaccount:default:${var.project_name}-sa"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# ECR push/pull policy
resource "aws_iam_role_policy" "ecr_push_pull" {
  count = var.create_ecr_policy ? 1 : 0
  name_prefix = "${var.project_name}-ecr-push-pull-"
  role        = aws_iam_role.eks_irsa[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "arn:aws:ecr:${var.aws_region}:${var.aws_account_id}:repository/${var.project_name}*"
      }
    ]
  })
}
