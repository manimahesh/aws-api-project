variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "insecure-api-demo"
}

variable "github_repo" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
}

variable "use_existing_oidc_provider" {
  description = "Set to true if GitHub OIDC provider already exists in your AWS account"
  type        = bool
  default     = false
}

variable "existing_oidc_provider_arn" {
  description = "ARN of existing GitHub OIDC provider (required if use_existing_oidc_provider is true)"
  type        = string
  default     = ""
}
