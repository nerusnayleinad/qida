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

# Batch
variable "max_vcpus" {
    type = number
}

variable "ecr_repository_producer" {
    type = string
}

variable "ecr_producer_image" {
    type = string
}

variable "ecr_producer_image_tag" {
    type = string
}

# SM
variable "secretsmanager_provider_db_host_arn" {
    type = string
}

variable "secretsmanager_provider_db_creds_arn" {
    type = string
}

# KMS 
variable "kms_key_id" {
  type        = string
}

variable "kms_key_arn" {
  type        = string
}

# DynamoDB
variable "dynamodb_table_name" {
    type = string
}

# SNS
variable "sns_topic_visits_arn" {
    type = string
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

