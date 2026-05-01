output "secretsmanager_provider_db_creds_arn" {
  description = "provider_db credentials ARN"
  value       = aws_secretsmanager_secret.provider_db.arn
}

output "secretsmanager_provider_db_host_arn" {
  description = "provider_db host ARN"
  value       = aws_secretsmanager_secret.provider_db_host.arn
}