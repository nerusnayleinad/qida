output "sns_topic_emails_arn" {
  description = "ARN of the SNS Topic emails"
  value       = aws_sns_topic.qida_emails_sns_topic.arn
}
