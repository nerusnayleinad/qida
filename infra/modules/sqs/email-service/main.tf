# SQS Queues + DLQ
resource "aws_sqs_queue" "qida_emails_sqs_queue" {
  name                       = "sqs-queue-emails-${var.name_suffix}"
  kms_master_key_id          = var.kms_key_id
  visibility_timeout_seconds = 300
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.qida_emails_sqs_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "qida_emails_sqs_dlq" {
  name              = "sqs-dlq-emails-${var.name_suffix}"
  kms_master_key_id = var.kms_key_id
}

# SNS
resource "aws_sns_topic" "sns_alerts_email_service_sqs_dlq_topic" {
  name = "sqs-dlq-email-service"
}

resource "aws_sns_topic_subscription" "sns_alerts_email_service_topic_subs" {
  topic_arn = aws_sns_topic.sns_alerts_email_service_sqs_dlq_topic.arn
  protocol  = "email"
  endpoint  = var.qida_alert_email
}

# CloudWatch
resource "aws_cloudwatch_metric_alarm" "emails_dlq_alarm" {
  alarm_name          = "email-service-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Sum"
  threshold           = 1

  dimensions = {
    QueueName = aws_sqs_queue.qida_emails_sqs_dlq.name
  }

  alarm_actions = [aws_sns_topic.sns_alerts_email_service_sqs_dlq_topic.arn]
}
