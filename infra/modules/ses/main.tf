# SES - domain verification
resource "aws_ses_domain_identity" "qida_domain_identity" {
  domain = var.ses_domain_identity
}

# DKIM
resource "aws_ses_domain_dkim" "qida_domain_dkim" {
  domain = aws_ses_domain_identity.qida_domain_identity.domain
}

# SES - from email
resource "aws_ses_email_identity" "qida_email_identity" {
  email = var.ses_email_identity
}

