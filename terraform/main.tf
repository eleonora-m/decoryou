# Main Terraform configuration for decoryou project
# Orchestrates all modules and resources

# VPC Module - Creates VPC, subnets, route tables, NAT gateways
module "vpc" {
  source = "./modules/vpc"

  aws_region             = var.aws_region
  environment            = var.environment
  project_name           = var.project_name
  vpc_cidr               = var.vpc_cidr
  availability_zones     = var.availability_zones
  private_subnet_cidrs   = var.private_subnet_cidrs
  public_subnet_cidrs    = var.public_subnet_cidrs
  enable_nat_gateway     = var.enable_nat_gateway
  enable_vpn_gateway     = var.enable_vpn_gateway
  enable_flow_logs       = var.enable_flow_logs

  tags = {
    Name = "${var.project_name}-vpc-${var.environment}"
  }
}

# IAM Module - Creates roles, policies, and service accounts
module "iam" {
  source = "./modules/iam"

  environment  = var.environment
  project_name = var.project_name
  aws_region   = var.aws_region
  aws_account_id = data.aws_caller_identity.current.account_id

  # EKS cluster name for IRSA (IAM Roles for Service Accounts)
  eks_cluster_name       = var.eks_cluster_name
  eks_oidc_provider_arn  = var.eks_oidc_provider_arn
}

# S3 Module - Creates S3 buckets for application storage and artifacts
module "s3" {
  source = "./modules/s3"

  environment  = var.environment
  project_name = var.project_name
  aws_region   = var.aws_region

  # Bucket configuration
  create_app_bucket              = var.create_s3_app_bucket
  create_terraform_state_bucket  = var.create_terraform_state_bucket
  create_artifacts_bucket        = var.create_artifacts_bucket
  
  # Security settings
  enable_versioning    = var.s3_enable_versioning
  enable_encryption    = var.s3_enable_encryption
  enable_mfa_delete    = var.s3_enable_mfa_delete
  enable_public_access_block = true

  tags = {
    Name = "${var.project_name}-s3-${var.environment}"
  }
}

# EC2 Module - Creates launch templates and autoscaling groups
module "ec2" {
  source = "./modules/ec2"

  environment            = var.environment
  project_name           = var.project_name
  aws_region             = var.aws_region
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnet_ids
  
  # Instance configuration
  instance_type          = var.instance_type
  desired_capacity       = var.desired_capacity
  min_size               = var.min_size
  max_size               = var.max_size
  ami_id                 = var.ami_id
  key_pair_name          = var.key_pair_name
  
  # Security
  security_group_ids     = [aws_security_group.app.id]
  iam_instance_profile   = module.iam.ec2_instance_profile_name
  
  # Docker image and app configuration
  docker_image           = var.docker_image
  app_port               = var.app_port
  
  # Monitoring
  enable_monitoring      = var.enable_detailed_monitoring
  
  tags = {
    Name = "${var.project_name}-asg-${var.environment}"
  }

  depends_on = [
    module.iam,
    module.vpc
  ]
}

# Application Load Balancer
resource "aws_lb" "app" {
  name               = "${var.project_name}-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnet_ids

  enable_deletion_protection = var.enable_alb_deletion_protection
  enable_http2              = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.project_name}-alb-${var.environment}"
  }
}

# Target Group for ALB
resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-tg-${var.environment}"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-tg-${var.environment}"
  }
}

# ALB Listener
resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Attach ASG to target group
resource "aws_autoscaling_attachment" "app" {
  autoscaling_group_name = module.ec2.autoscaling_group_name
  lb_target_group_arn    = aws_lb_target_group.app.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/${var.project_name}/${var.environment}/app"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-logs-${var.environment}"
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Security Groups
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg-${var.environment}"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg-${var.environment}"
  }
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg-${var.environment}"
  description = "Security group for application servers"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-sg-${var.environment}"
  }
}
