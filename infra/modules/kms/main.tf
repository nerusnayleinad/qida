resource "aws_kms_key" "qida_key" {
  description = "Key that encrypts/decrypts everything"
  
  tags =  merge(var.tags, {
      Name = "kms-key-${var.name_suffix}"
  })
}

resource "aws_kms_alias" "qida_key_alias" {
  name          = "alias/${var.kms_key_alias}"
  target_key_id = aws_kms_key.qida_key.id
}