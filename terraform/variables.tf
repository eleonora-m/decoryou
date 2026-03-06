variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "decoryou-cluster"
}
variable "docker_image_tag" {
  description = "Tag of the Docker image from Jenkins"
  type        = string
}