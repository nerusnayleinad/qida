# ECS Cluster
resource "aws_ecs_cluster" "qida_ecs_cluster" {
  name = "ecs-cluster-${var.name_suffix}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}