# Core Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

# DNS Variables
variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support"
  type        = bool
  default     = true
}

# Batch
variable "max_vcpus" {
  type = number
}

# ECS
variable "visit_processor_fargate_cpu_request" {
  type = number
}

variable "visit_processor_fargate_memory_request" {
  type = number
}

variable "django_api_url" {
  type = string
}

variable "email_service_fargate_cpu_request" {
  type = number
}

variable "email_service_fargate_memory_request" {
  type = number
}

variable "visit_processor_min_replicas" {
  type = number
}

variable "visit_processor_max_replicas" {
  type = number
}

variable "email_service_min_replicas" {
  type = number
}

variable "email_service_max_replicas" {
  type = number
}

variable "ecr_producer_image" {
  type = string
}

variable "ecr_producer_image_tag" {
  type = string
}

# ECS
variable "ecr_visit_processor_image" {
  type = string
}

variable "ecr_visit_processor_image_tag" {
  type = string
}

variable "ecr_email_service_image" {
  type = string
}

variable "ecr_email_service_image_tag" {
  type = string
}

variable "kms_key_alias" {
  description = "Alias of KMS Key"
  type        = string
}

# HSM
#variable "hsm_mode" {
#    type = string
#}

# SES 
variable "ses_domain_identity" {
  type        = string
}

variable "ses_email_identity" {
  type        = string
}

# CloudWatch
variable "qida_alert_email" {
  type = string
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
