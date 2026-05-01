# Provider DB credentials
resource "aws_secretsmanager_secret" "provider_db" {
  name        = "provider-db-credentials"
  description = "Credentials for ProviderDB database"
  
  kms_key_id  = var.kms_key_id
}

# Provider DB host
resource "aws_secretsmanager_secret" "provider_db_host" {
  name = "providerdb-host"
}

resource "aws_secretsmanager_secret_version" "provider_db_host_version" {
  secret_id     = aws_secretsmanager_secret.provider_db_host.id
  secret_string = "host.qida-provider.db"
}