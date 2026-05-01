# Core Vaariables
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

# KMS 
variable "kms_key_arn" {
  type        = string
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
