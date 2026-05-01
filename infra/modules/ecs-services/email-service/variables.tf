# Core Variables
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "name_suffix" {
  description = "project_name + environment + aws_region"
  type        = string
}

# VPC
variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

# KMS 
variable "kms_key_id" {
  type        = string
}

# ECS
variable "ecs_cluster_id" {
  type  = string
}

variable "ecs_cluster_name" {
  type  = string
}

variable "ecr_repository_email_service" {
    type = string
}

variable "ecr_email_service_image" {
    type = string
}

variable "ecr_email_service_image_tag" {
    type = string
}

# SQS
variable "sqs_queue_emails_url" {
  type = string
}

# SES
variable "ses_email_identity" {
  type = string
}

# CloudWatch
variable "qida_alert_email" {
  type = string
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type = map(string)
  default = {}
}

