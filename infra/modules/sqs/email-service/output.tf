output "sqs_queue_emails_arn" {
  description = "ARN of the SQS Queue Emails"
  value       = aws_sqs_queue.qida_emails_sqs_queue.arn
}

output "sqs_queue_emails_url" {
  description = "URL of the SQS Queue Emails"
  value       = aws_sqs_queue.qida_emails_sqs_queue.url
}