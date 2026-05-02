# IAM Roles
resource "aws_iam_role" "qida_ecs_vp_task_execution_role" {
  name = "ecs-vp-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "qida_ecs_vp_task_execution_policy_att" {
  role       = aws_iam_role.qida_ecs_vp_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "qida_visits_task_role" {
  name = "ecs-visits-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "qida_ecs_visits_task_role_policy" {
  name = "ecs-visits-task-role-policy"
  role = aws_iam_role.qida_visits_task_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["sns:Publish"]
      Resource = [var.sns_topic_emails_arn]
    }]
  })
}

# Security Group
resource "aws_security_group" "qida_visit_processor_sg" {
  name   = "ecs-sg-visit-processor-${var.name_suffix}"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Task Definition - Visit Processor
resource "aws_ecs_task_definition" "qida_visit_processor_ecs_td" {
  family                   = "visit-processor-${var.name_suffix}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.qida_ecs_vp_task_execution_role.arn
  task_role_arn            = aws_iam_role.qida_visits_task_role.arn

  container_definitions = jsonencode([{
    name  = "visit-processor"
    image = "${var.ecr_repository_visit_processor}/${var.ecr_visit_processor_image}:${var.ecr_visit_processor_image_tag}"
    
    environment = [
      { 
        name = "SQS_QUEUE_VISITS_URL",
        value = var.sqs_queue_visits_url 
      },
      { 
        name = "SNS_TOPIC_EMAILS_ARN",
        value = var.sns_topic_emails_arn
      },
      { 
        name = "DJANGO_API_URL",
        value = var.django_api_url 
      }
    ]
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_visit_processor_lg.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "vp"
      }
    }
  }])
}

# ECS Service
resource "aws_ecs_service" "visit_processor" {
  name            = "visit-processor"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.qida_visit_processor_ecs_td.arn
  desired_count   = var.visit_processor_min_replicas
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.qida_visit_processor_sg.id]
    assign_public_ip = false
  }
}

# CloudWatch
resource "aws_cloudwatch_log_group" "ecs_visit_processor_lg" {
  name              = "/aws/visit_processor/job"
  retention_in_days = 7

  kms_key_id = var.kms_key_id
}

resource "aws_appautoscaling_target" "ecs_visit_processor" {
  max_capacity       = var.visit_processor_max_replicas
  min_capacity       = var.visit_processor_max_replicas
  resource_id        = "service/${var.ecs_cluster_name}/email-service"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_visit_processor_scale_on_cpu" {
  name               = "scale-on-cpu"
  resource_id        = aws_appautoscaling_target.ecs_visit_processor.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_visit_processor.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_visit_processor.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 80
  }
}

# SNS Topic for alerts
resource "aws_sns_topic" "sns_alerts_visit_processor_topic" {
  name = "ecs-alerts-email-service"
}

resource "aws_sns_topic_subscription" "sns_alerts_visit_processor_topic_subs" {
  topic_arn = aws_sns_topic.sns_alerts_visit_processor_topic.arn
  protocol  = "email"
  endpoint  = var.qida_alert_email
}

# CPU
resource "aws_cloudwatch_metric_alarm" "ecs_visit_processor_cpu_high" {
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
    ServiceName = aws_ecs_service.visit_processor.name
  }

  alarm_actions = [aws_sns_topic.sns_alerts_visit_processor_topic.arn]
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
    ServiceName = aws_ecs_service.visit_processor.name
  }

  alarm_actions = [aws_sns_topic.sns_alerts_visit_processor_topic.arn]
}
