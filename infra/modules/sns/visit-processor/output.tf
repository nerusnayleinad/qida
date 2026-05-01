output "sns_topic_visits_arn" {
  description = "ARN of the SNS Topic visits"
  value       = aws_sns_topic.qida_visits_sns_topic.arn
}