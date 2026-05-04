variable "region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project, used in resource naming and tagging"
  type        = string
  default     = "demo-site"
}

variable "environment" {
  description = "Deployment environment (e.g. production, staging)"
  type        = string
  default     = "production"
}

variable "domain_name" {
  description = "Optional custom domain name for the CloudFront distribution (leave empty to use default CloudFront domain)"
  type        = string
  default     = ""
}
