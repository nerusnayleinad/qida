output "sqs_queue_visits_arn" {
  description = "ARN of the SQS Queue Visits"
  value       = aws_sqs_queue.qida_visits_sqs_queue.arn
}

output "sqs_queue_visits_url" {
  description = "URL of the SQS Queue Visits"
  value       = aws_sqs_queue.qida_visits_sqs_queue.url
}