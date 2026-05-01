# Task role
resource "aws_iam_role" "qida_batch_task_role" {
  name = "task-role-${var.name_suffix}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}


resource "aws_iam_role_policy" "qida_batch_task_role_policy" {
  name = "batch-task-access"
  role = aws_iam_role.qida_batch_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Resource = [
          # aws_secretsmanager_secret.provider_db.arn,
          var.kms_key_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ]
        Resource = var.dynamodb_table_name
      },
      {
        Effect = "Allow"
        Action = "sns:Publish"
        Resource = var.sns_topic_visits_arn
      }
    ]
  })
}

# execution role
resource "aws_iam_role" "qida_batch_execution_role" {
  name = "execution-role-${var.name_suffix}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "qida_batch_execution_role_policy_att" {
  role       = aws_iam_role.qida_batch_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "qida_batch_execution_role_kms" {
  name = "execution-policy-kms-${var.name_suffix}"
  role = aws_iam_role.qida_batch_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "kms:Decrypt",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = [
        var.kms_key_arn,
        "${aws_cloudwatch_log_group.batch_producer_lg.arn}:*"
      ]
    }]
  })
}

resource "aws_iam_role" "qida_batch_service_role" {
  name = "batch-service-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "batch.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "batch_service_role_policy_att" {
  role       = aws_iam_role.qida_batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}


# Security Group
resource "aws_security_group" "qida_batch_sg" {
  name   = "batch-${var.name_suffix}-sg"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Job definition
resource "aws_batch_job_definition" "qida_jd_producer" {
  name = "jd-${var.name_suffix}"
  type = "container"

  platform_capabilities = ["FARGATE"]

  container_properties = jsonencode({
    image = "${var.ecr_repository_producer}/${var.ecr_producer_image}:${var.ecr_producer_image_tag}"
    command = ["curl", "-L", "qida.es"]
    
    environment = [
      #{ 
      #  name = "SECRET_ARN", 
      #  value = aws_secretsmanager_secret.provider_db.arn
      #},
      { 
        name = "DYNAMODB_TABLE", 
        value = var.dynamodb_table_name
      },
      { 
        name = "SNS_VISITS_ARN",
        value = var.sns_topic_visits_arn
      }
    ]
    
    volumes = [
      {
        host = {
          sourcePath = "/srv/qida"
        }
        name = "app"
      }
    ]

    mountPoints = [
      {
        sourceVolume  = "app"
        containerPath = "/srv/qida"
        readOnly      = false
      }
    ]
    
    resourceRequirements = [
      {
        type  = "VCPU"
        value = "0.25"
      },
      {
        type  = "MEMORY"
        value = "512"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.batch_producer_lg.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "bp"
      }
    }
    
    executionRoleArn = aws_iam_role.qida_batch_execution_role.arn
    taskRoleArn      = aws_iam_role.qida_batch_task_role.arn
  })
}

# compute environment
resource "aws_batch_compute_environment" "qida_producer_fargate" {
  name = "qida-producer-${var.name_suffix}"
  type = "MANAGED"
  state = "ENABLED"

  compute_resources {
    type           = "FARGATE"
    max_vcpus      = var.max_vcpus
    subnets        = var.private_subnet_ids
    security_group_ids = [aws_security_group.qida_batch_sg.id]

  }

  service_role = aws_iam_role.qida_batch_service_role.arn
}

# Job queue
resource "aws_batch_job_queue" "batch_producer_job_queue" {
  name                 = "producer-queue"
  state                = "ENABLED"
  priority             = 1
  
  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.qida_producer_fargate.arn
  }
}

# EventBridge IAM
resource "aws_iam_role" "eventbridge_batch_role" {
  name = "eventbridge-batch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_batch_role_policy" {
  name = "eventbridge-batch-policy"
  role = aws_iam_role.eventbridge_batch_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "batch:SubmitJob",
        "batch:DescribeJobs",
        "batch:TerminateJob"
      ]
      Resource = "*"
    }]
  })
}

# EventBridge rule and trigger
resource "aws_cloudwatch_event_rule" "batch_trigger_rule" {
  name                = "batch-producer-trigger"
  description         = "Trigger Batch producer job every hour"
  schedule_expression = "cron(0 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "batch" {
  rule      = aws_cloudwatch_event_rule.batch_trigger_rule.name
  target_id = "batch-producer"
  arn       = aws_batch_job_queue.batch_producer_job_queue.arn
  role_arn  = aws_iam_role.eventbridge_batch_role.arn

  batch_target {
    job_definition = aws_batch_job_definition.qida_jd_producer.arn
    job_name       = "batch-job-producer"
  }
}

# SNS
resource "aws_sns_topic" "sns_alerts_batch_job_fail_topic" {
  name = "batch-failed-job-alerts"
}

resource "aws_sns_topic_subscription" "sns_alerts_batch_job_fail_topic_subs" {
  topic_arn = aws_sns_topic.sns_alerts_batch_job_fail_topic.arn
  protocol  = "email"
  endpoint  = var.qida_alert_email
}

# CloudWatch
resource "aws_cloudwatch_log_group" "batch_producer_lg" {
  name              = "/aws/batch_producer/job"
  retention_in_days = 7

  kms_key_id = var.kms_key_id
}

resource "aws_cloudwatch_event_rule" "batch_job_failure_event_rule" {
  name        = "batch-job-failure"
  description = "Failed Batch jobs"

  event_pattern = jsonencode({
    source      = ["aws.batch"]
    detail-type = ["Batch Job State Change"]
    detail = {
      status = ["FAILED"]
    }
  })
}
resource "aws_cloudwatch_event_target" "batch_job_failure_event_target" {
  rule      = aws_cloudwatch_event_rule.batch_job_failure_event_rule.name
  target_id = "send-email"
  arn       = aws_sns_topic.sns_alerts_batch_job_fail_topic.arn
}

