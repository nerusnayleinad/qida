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

# SES 
variable "ses_domain_identity" {
  type        = string
}

variable "ses_email_identity" {
  type        = string
}
