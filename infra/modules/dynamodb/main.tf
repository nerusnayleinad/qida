# DynamoDB
resource "aws_dynamodb_table" "qida_producer_pipeline_state" {
  name         = "producer-pipeline-state-${var.name_suffix}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "job_id"
  range_key    = "status"

  attribute {
    name = "job_id"
    type = "S"
  }
  
  attribute {
    name = "status"
    type = "S"
  }

  ttl {
    attribute_name = "lock_expiry"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }
  
  tags =  merge(var.tags, {
      Name = "dynamodb-producer-pipeline-state-${var.name_suffix}"
  })
}