# IAM Roles
resource "aws_iam_role" "qida_ecs_es_task_execution_role" {
  name = "ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "qida_ecs_es_task_execution_policy_att" {
  role       = aws_iam_role.qida_ecs_es_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "qida_email_task_role" {
  name = "email-email-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "qida_email_task_role_policy" {
  name = "email-email-task-role-policy"
  role = aws_iam_role.qida_email_task_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [var.sqs_queue_emails_url]
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = ["*"]
      }
    ]
  })
}

# Security Group
resource "aws_security_group" "qida_email_service_sg" {
  name   = "ecs-sg-visit-processor-${var.name_suffix}"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Task Definition - Email Service
resource "aws_ecs_task_definition" "qida_email_service_ecs_td" {
  family                   = "email-service-${var.name_suffix}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.email_service_fargate_cpu_request
  memory                   = var.email_service_fargate_memory_request
  execution_role_arn       = aws_iam_role.qida_ecs_es_task_execution_role.arn
  task_role_arn            = aws_iam_role.qida_email_task_role.arn

  container_definitions = jsonencode([{
    name  = "email-service"
    image = "${var.ecr_repository_email_service}/${var.ecr_email_service_image}:${var.ecr_email_service_image_tag}"
    
    environment = [
      { 
        name = "SQS_QUEUE_URL", 
        value = var.sqs_queue_emails_url 
      },
      { 
        name = "SES_FROM_EMAIL",
        value = var.ses_email_identity
      }
    ]
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_email_service_lg.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "es"
      }
    }
  }])
}

# ECS Service
resource "aws_ecs_service" "email_service" {
  name            = "email-service"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.qida_email_service_ecs_td.arn
  desired_count   = var.email_service_min_replicas
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.qida_email_service_sg.id]
    assign_public_ip = false
  }
}

resource "aws_appautoscaling_target" "ecs_email_service" {
  max_capacity       = var.email_service_max_replicas
  min_capacity       = var.email_service_min_replicas
  resource_id        = "service/${var.ecs_cluster_name}/email-service"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_email_service_scale_on_cpu" {
  name               = "scale-on-cpu"
  resource_id        = aws_appautoscaling_target.ecs_email_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_email_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_email_service.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 80
  }
}

# SNS Topic for alerts
resource "aws_sns_topic" "sns_alerts_email_service_topic" {
  name = "ecs-alerts-email-service"
}

resource "aws_sns_topic_subscription" "sns_alerts_email_service_topic_subs" {
  topic_arn = aws_sns_topic.sns_alerts_email_service_topic.arn
  protocol  = "email"
  endpoint  = var.qida_alert_email
}

# CloudWatch
resource "aws_cloudwatch_log_group" "ecs_email_service_lg" {
  name              = "/aws/email_service/job"
  retention_in_days = 7

  kms_key_id = var.kms_key_id
}

# CPU
resource "aws_cloudwatch_metric_alarm" "ecs_email_service_cpu_high" {
  alarm_name          = "email-service-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU utilization of Email Service exceeds 80%"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = aws_ecs_service.email_service.name
  }

  alarm_actions = [aws_sns_topic.sns_alerts_email_service_topic.arn]
}

# Memory
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "visit-processor-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Memory utilization of Email Service exceeds 80%"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = aws_ecs_service.email_service.name
  }

  alarm_actions = [aws_sns_topic.sns_alerts_email_service_topic.arn]
}
