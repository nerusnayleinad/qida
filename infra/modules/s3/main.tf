# S3 bucket holding sensitive data
resource "aws_s3_bucket" "qida_bucket" {
  bucket = var.bucket_name
  
  tags = {
    Name = var.bucket_name
  }
}

resource "aws_s3_bucket_versioning" "qida_bucket_versioning" {
  bucket = aws_s3_bucket.qida_bucket.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# server-side encryption using KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "qida_s3_server_side_encryption" {
  bucket = aws_s3_bucket.qida_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# blocking all public access to the bucket
resource "aws_s3_bucket_public_access_block" "qida_block_public_access" {
  bucket = aws_s3_bucket.qida_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM policy document for the S3 bucket
data "aws_iam_policy_document" "bucket_policy" {
  # Deny uploads that aren't encrypted with KMS
  statement {
    sid    = "DenyIncorrectEncryptionHeader"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.qida_bucket.arn}/*",
    ]
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }

  # Deny uploads without encryption header
  statement {
    sid    = "DenyUnencryptedObjectUploads"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.qida_bucket.arn}/*",
    ]
    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }
  }

  # Require specific KMS key for encryption
  statement {
    sid    = "DenyWrongKMSKey"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.qida_bucket.arn}/*",
    ]
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [var.kms_key_arn]
    }
  }

  # Allow only TLS/SSL requests
  statement {
    sid    = "DenyInsecureConnections"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.qida_bucket.arn,
      "${aws_s3_bucket.qida_bucket.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# policy binding
resource "aws_s3_bucket_policy" "qida_bucket_policy_binding" {
  bucket = aws_s3_bucket.qida_bucket.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}