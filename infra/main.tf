provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      BuiltWith   = "Terraform"
      Project     = var.project_name
    }
  }
}

locals {
  name_suffix = "${var.project_name}-${var.environment}-${var.aws_region}"
}

module "vpc" {
  source = "./modules/vpc/"
  name = "vpc-${local.name_suffix}"
  
  environment     = var.environment
  region          = var.aws_region
  
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs

  # DNS configuration
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  name_suffix = local.name_suffix
}

module "kms" {
  source = "./modules/kms/"
  
  kms_key_alias = var.kms_key_alias
  
  environment     = var.environment
  region          = var.aws_region

  name_suffix = local.name_suffix
}

module "ecr" {
  source = "./modules/ecr/"
  
  environment     = var.environment
  region          = var.aws_region
  
  kms_key_arn = module.kms.kms_key_arn
  
  name_suffix = local.name_suffix
}

module "batch" {
  source = "./modules/batch/"
  
  environment     = var.environment
  region          = var.aws_region
  
  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
 
  max_vcpus = var.max_vcpus
  
  ecr_repository_producer = module.ecr.ecr_repository_producer
  ecr_producer_image = var.ecr_producer_image
  ecr_producer_image_tag = var.ecr_producer_image_tag
  
  secretsmanager_provider_db_host_arn = module.secrets-manager.secretsmanager_provider_db_host_arn
  secretsmanager_provider_db_creds_arn = module.secrets-manager.secretsmanager_provider_db_creds_arn
  kms_key_id = module.kms.kms_key_id
  kms_key_arn = module.kms.kms_key_arn
  dynamodb_table_name = module.dynamodb.dynamodb_table_name
  sns_topic_visits_arn = module.sns-vp.sns_topic_visits_arn
  
  qida_alert_email = var.qida_alert_email
  
  name_suffix = local.name_suffix
}

module "ecs-cluster" {
  source = "./modules/ecs-cluster/"
  
  environment     = var.environment
  region          = var.aws_region
  
  name_suffix = local.name_suffix
}

module "ecs-service-vp" {
  source = "./modules/ecs-services/visit-processor/"
  
  environment     = var.environment
  region          = var.aws_region
  
  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  
  kms_key_id = module.kms.kms_key_id
  
  ecs_cluster_id = module.ecs-cluster.ecs_cluster_id
  ecs_cluster_name = module.ecs-cluster.ecs_cluster_name
  visit_processor_fargate_cpu_request = var.visit_processor_fargate_cpu_request
  visit_processor_fargate_memory_request = var.visit_processor_fargate_memory_request
  visit_processor_min_replicas = var.visit_processor_min_replicas
  visit_processor_max_replicas = var.visit_processor_max_replicas
  django_api_url = var.django_api_url
  
  ecr_repository_visit_processor = module.ecr.ecr_repository_visit_processor
  ecr_visit_processor_image = var.ecr_visit_processor_image
  ecr_visit_processor_image_tag = var.ecr_visit_processor_image_tag
  
  sqs_queue_visits_url = module.sqs-vp.sqs_queue_visits_url
  sns_topic_emails_arn = module.sns-es.sns_topic_emails_arn
  
  qida_alert_email = var.qida_alert_email
  
  name_suffix = local.name_suffix
}

module "ecs-service-es" {
  source = "./modules/ecs-services/email-service/"
  
  environment     = var.environment
  region          = var.aws_region
  
  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  
  kms_key_id = module.kms.kms_key_id
  
  ecs_cluster_id = module.ecs-cluster.ecs_cluster_id
  ecs_cluster_name = module.ecs-cluster.ecs_cluster_name
  email_service_fargate_cpu_request = var.email_service_fargate_cpu_request
  email_service_fargate_memory_request = var.email_service_fargate_memory_request
  email_service_min_replicas = var.email_service_min_replicas
  email_service_max_replicas = var.email_service_max_replicas
  
  ecr_repository_email_service = module.ecr.ecr_repository_email_service
  ecr_email_service_image = var.ecr_email_service_image
  ecr_email_service_image_tag = var.ecr_email_service_image_tag
  
  sqs_queue_emails_url = module.sqs-es.sqs_queue_emails_url
  
  ses_email_identity = var.ses_email_identity
  
  qida_alert_email = var.qida_alert_email
  
  name_suffix = local.name_suffix
}

module "dynamodb" {
  source = "./modules/dynamodb/"
  
  environment     = var.environment
  region          = var.aws_region
  
  kms_key_arn = module.kms.kms_key_arn
  
  name_suffix = local.name_suffix
}

module "sns-vp" {
  source = "./modules/sns/visit-processor/"
  
  environment     = var.environment
  region          = var.aws_region
  
  kms_key_id = module.kms.kms_key_id
  
  sqs_visits_arn = module.sqs-vp.sqs_queue_visits_arn
  
  name_suffix = local.name_suffix
}

module "sns-es" {
  source = "./modules/sns/email-service/"
  
  environment     = var.environment
  region          = var.aws_region
  
  kms_key_id = module.kms.kms_key_id
  
  sqs_emails_arn = module.sqs-es.sqs_queue_emails_arn
  
  name_suffix = local.name_suffix
}

module "sqs-vp" {
  source = "./modules/sqs/visit-processor/"
  
  environment     = var.environment
  region          = var.aws_region
  
  kms_key_id = module.kms.kms_key_id
  
  qida_alert_email = var.qida_alert_email
  
  name_suffix = local.name_suffix
}

module "sqs-es" {
  source = "./modules/sqs/email-service/"
  
  environment     = var.environment
  region          = var.aws_region
  
  kms_key_id = module.kms.kms_key_id
  
  qida_alert_email = var.qida_alert_email
  
  name_suffix = local.name_suffix
}

module "ses" {
  source = "./modules/ses/"
  
  environment     = var.environment
  region          = var.aws_region
  
  ses_domain_identity = var.ses_domain_identity
  ses_email_identity = var.ses_email_identity
  
  name_suffix = local.name_suffix
}

module "secrets-manager" {
  source = "./modules/secrets-manager/"
  
  environment     = var.environment
  region          = var.aws_region
  
  kms_key_id = module.kms.kms_key_id

  name_suffix = local.name_suffix
}

# deberían ser dos buckets
module "s3" {
  source = "./modules/s3/"
  bucket_name = "bucket-qidaes-st-${local.name_suffix}"
  
  environment     = var.environment
  region          = var.aws_region
  
  kms_key_id = module.kms.kms_key_id
  kms_key_arn = module.kms.kms_key_arn

  name_suffix = local.name_suffix
}
