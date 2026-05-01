# Provider DB credentials
resource "aws_secretsmanager_secret" "provider_db" {
  name        = "provider-db-credentials"
  description = "Credentials for ProviderDB database"
  
  kms_key_id  = var.kms_key_id
}

