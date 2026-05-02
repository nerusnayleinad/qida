# Core
project_name = "qida"
environment  = "dev"
aws_region   = "us-east-2"

# VPC
vpc_cidr = "10.10.0.0/16"
availability_zones = ["us-east-2a", "us-east-2b"]

private_subnet_cidrs = [
  "10.10.101.0/24",
  "10.10.102.0/24"
]

public_subnet_cidrs = [
  "10.10.201.0/24",
  "10.10.202.0/24"
]

# ECR
ecr_visit_processor_image = "visit_processor"
ecr_visit_processor_image_tag = "__VISIT_PROCESSOR_IMAGE_TAG__"

ecr_email_service_image = "email_service"
ecr_email_service_image_tag = "__EMAIL_SERVICE_IMAGE_TAG__"

# Batch
max_vcpus = 16
processor_batch_vcpu_request ="0.25"
processor_batch_memory_request = "512"
ecr_producer_image = "producer"
ecr_producer_image_tag = "__PRODUCER_IMAGE_TAG__"

# ECS
visit_processor_fargate_cpu_request=256
visit_processor_fargate_memory_request=512
django_api_url = "dev.djangoapi.qida.es"

email_service_fargate_cpu_request=256
email_service_fargate_memory_request=512

visit_processor_min_replicas=1
visit_processor_max_replicas=2

email_service_min_replicas=1
email_service_max_replicas=2

# SES
ses_domain_identity = "qida-dev.es"
ses_email_identity = "visita@qida-dev.es"   # from email

# KMS
kms_key_alias = "qida"

# CloudWatch
qida_alert_email = "alerts@qida.es"

# Tags
tags = {
  project = "qida"
  environment = "dev"
  region = "us-east-2"
  built-with = "Terraform"
}

# Enable SSM endpoints for dev
#enable_ssm_endpoint = true
#enable_ssmmessages_endpoint = true
#enable_ec2_endpoint = true
#enable_ec2messages_endpoint = true

# Enable flow logs in dev
#enable_flow_log = true