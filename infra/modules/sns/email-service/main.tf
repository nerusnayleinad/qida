resource "aws_sns_topic" "qida_emails_sns_topic" {
  name            = "sns-topic-emails-${var.name_suffix}"
  kms_master_key_id = var.kms_key_id
}

resource "aws_sns_topic_subscription" "qida_emails_sns_topic_subs" {
  topic_arn = aws_sns_topic.qida_emails_sns_topic.arn
  protocol  = "sqs"
  endpoint  = var.sqs_emails_arn
}