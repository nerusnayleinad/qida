# ECR Repository
resource "aws_ecr_repository" "producer" {
  name = "batch-producer"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  image_tag_mutability = "IMMUTABLE"
  
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }
}

resource "aws_ecr_repository" "visit_processor" {
  name = "visit-processor"
  
  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "IMMUTABLE"
    
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }
}

resource "aws_ecr_repository" "email_service" {
  name = "email-service"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  image_tag_mutability = "IMMUTABLE"
  
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }
}

# ECR Lifecycle Policies
resource "aws_ecr_lifecycle_policy" "producer" {
  repository = aws_ecr_repository.producer.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "visit_processor" {
  repository = aws_ecr_repository.visit_processor.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "email_service" {
  repository = aws_ecr_repository.email_service.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}
