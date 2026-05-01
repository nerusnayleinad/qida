output "dynamodb_table_name" {
  value       = aws_dynamodb_table.qida_producer_pipeline_state.name
}

output "dynamodb_table_id" {
  value       = aws_dynamodb_table.qida_producer_pipeline_state.id
}

output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.qida_producer_pipeline_state.arn
}
