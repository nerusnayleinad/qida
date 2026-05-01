output "ecr_repository_producer" {
  description = "ECR repo producer"
  value       = aws_ecr_repository.producer.name
}

output "ecr_repository_visit_processor" {
  description = "ECR repo visit_processor"
  value       = aws_ecr_repository.visit_processor.name
}

output "ecr_repository_email_service" {
  description = "ECR repo email_service"
  value       = aws_ecr_repository.email_service.name
}

