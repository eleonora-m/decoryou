terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }

  # Remote state configuration - S3 + DynamoDB for locking
  # This is configured via -backend-config flags in the pipeline
  backend "s3" {
    # bucket           = "decoryou-terraform-state-${ENVIRONMENT}"
    # key              = "${ENVIRONMENT}/terraform.tfstate"
    # region           = "us-east-1"
    # dynamodb_table   = "decoryou-terraform-locks"
    # encrypt          = true
    # workspace_key_prefix = "decoryou"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project      = var.project_name
      Environment  = var.environment
      ManagedBy    = "Terraform"
      Owner        = var.owner
      CreatedAt    = timestamp()
      CostCenter   = var.cost_center
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Data source for existing EKS cluster (if using external cluster)
data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name

  depends_on = [module.vpc]
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.eks_cluster_name

  depends_on = [module.vpc]
}
