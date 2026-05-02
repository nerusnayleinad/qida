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
  type  = string
}

# ECS
variable "ecs_cluster_id" {
  type  = string
}

variable "ecs_cluster_name" {
  type  = string
}

variable "visit_processor_fargate_cpu_request" {
  type = number
}

variable "visit_processor_fargate_memory_request" {
  type = number
}

variable "django_api_url" {
  type = string
}

variable "visit_processor_min_replicas" {
  type = number
}

variable "visit_processor_max_replicas" {
  type = number
}

variable "ecr_repository_visit_processor" {
  type = string
}

variable "ecr_visit_processor_image" {
  type = string
}

variable "ecr_visit_processor_image_tag" {
  type = string
}

# SQS
variable "sqs_queue_visits_url" {
  type = string
}

# SNS
variable "sns_topic_emails_arn" {
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

