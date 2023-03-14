#######################################################################################################################
# ECS Service Module
#######################################################################################################################
locals {
  name = "${var.environment}-${var.app_name}"
}

data "aws_lb" "lb" {
  arn = "${var.lb_id}"
}

#################################
# IAM role - ECS task (container)
#################################
resource "aws_iam_role" "ecs-task" {
  name        = "${local.name}-task-role"
  description = "The role to assume for the ECS-task for app: ${var.app_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-logs" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = "${aws_iam_role.ecs-task.id}"
}

############################
# IAM role - ECS autoscaling
############################
resource "aws_iam_role" "ecs-autoscaling" {
  name        = "${local.name}-autoscaling-role"
  description = "The role to assume for autoscalling ECS for app: ${var.app_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "application-autoscaling.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-autoscaling" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
  role       = "${aws_iam_role.ecs-autoscaling.id}"
}

###############
# Load Balancer
###############

# Target Group
resource "aws_lb_target_group" "this" {
  name                 = "${local.name}-tg"
  port                 = "${var.container_port}"
  protocol             = "HTTP"
  vpc_id               = "${var.vpc_id}"
  deregistration_delay = "${var.lb_deregistration_delay}"
  target_type          = "ip"

  health_check {
    protocol            = "${var.lb_healthcheck_protocol}"
    port                = "${var.lb_healthcheck_port}"
    path                = "${var.lb_healthcheck_protocol == "HTTP" || var.lb_healthcheck_protocol == "HTTPS" ? var.lb_healthcheck_path : ""}"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }
  depends_on = [data.aws_lb.lb]
}

# LB listener
resource "aws_lb_listener" "this" {
  
  load_balancer_arn = "${var.lb_id}"
  port              = "${var.lb_listener_port}"
  protocol          = "${var.lb_listener_protocol}"

  default_action {
    target_group_arn = "${aws_lb_target_group.this.id}"
    type             = "forward"
  }

  depends_on = [aws_lb_target_group.this]
}

#################
# Task Definition
#################
resource "aws_ecs_task_definition" "this" {
  task_role_arn         = "${aws_iam_role.ecs-task.arn}"
  execution_role_arn    = "${aws_iam_role.ecs-task.arn}"
  network_mode          = "awsvpc"
  container_definitions = "${var.container_definition}"
  family                = "${local.name}-task"
}

#############
# ECS Service
#############
resource "aws_ecs_service" "this" {
  name                               = "${local.name}-service"
  cluster                            = "${var.ecs_cluster_id}"
  desired_count                      = "${var.desired_count}"
  task_definition                    = "${aws_ecs_task_definition.this.id}:${aws_ecs_task_definition.this.revision}"
  health_check_grace_period_seconds  = "${var.health_check_grace_period_seconds}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
  deployment_maximum_percent         = "${var.deployment_maximum_percent}"

  ordered_placement_strategy {
    type  = "${var.strategy_type}"
    field = "${var.strategy_field}"
  }

  network_configuration {
    subnets          = ["${var.subnets[0]}", "${var.subnets[1]}"]
    security_groups  = ["${var.security_groups[0]}"]
    assign_public_ip = false
  }

  load_balancer {
    container_name   = "${var.container_name}"
    container_port   = "${var.container_port}"
    target_group_arn = "${aws_lb_target_group.this.arn}"
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }

  depends_on = [aws_iam_role.ecs-task]
}

#############################
# Autoscalling target for ECS
#############################
resource "aws_appautoscaling_target" "ecs" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.this.name}"
  role_arn           = "${aws_iam_role.ecs-autoscaling.arn}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = "${var.appautoscaling_ecs_min_capacity}"
  max_capacity       = "${var.appautoscaling_ecs_max_capacity}"

  lifecycle {
    ignore_changes = [role_arn]
  }
}

##############################
# CloudWatch log group for app
#################################
resource "aws_cloudwatch_log_group" "this" {
  name = "/ecs/${var.ecs_cluster_name}/${var.app_name}"
}


###############################################################################
# A CloudWatch alarm that monitors CPU utilization of containers for scaling up
###############################################################################
resource "aws_cloudwatch_metric_alarm" "ecs-service-cpu-high" {
  alarm_name          = "${aws_ecs_service.this.name}-app-cpu-utilization-above-${var.cpu_high_threshold}"
  alarm_description   = "This alarm monitors ${aws_ecs_service.this.name} CPU utilization for scaling up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "${var.cpu_high_threshold}"
    alarm_actions       = ["${aws_appautoscaling_policy.ecs-scale-up-cpu.arn}"]

  dimensions = {
    ClusterName = "${var.ecs_cluster_name}"
    ServiceName = "${aws_ecs_service.this.name}"
  }
}


#################################################################################
# A CloudWatch alarm that monitors CPU utilization of containers for scaling down
#################################################################################
resource "aws_cloudwatch_metric_alarm" "ecs-service-cpu-low" {
  alarm_name          = "${aws_ecs_service.this.name}-app-cpu-utilization-below-${var.cpu_low_threshold}"
  alarm_description   = "This alarm monitors ${aws_ecs_service.this.name} CPU utilization for scaling down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "${var.cpu_low_threshold}"
  alarm_actions       = ["${aws_appautoscaling_policy.ecs-scale-down-cpu.arn}"]

  dimensions = {
    ClusterName = "${var.ecs_cluster_name}"
    ServiceName = "${aws_ecs_service.this.name}"
  }
}

##################################################################################
# A CloudWatch alarm that monitors memory utilization of containers for scaling up
##################################################################################
resource "aws_cloudwatch_metric_alarm" "ecs-service-memory-high" {
  alarm_name          = "${aws_ecs_service.this.name}-app-memory-utilization-above-${var.ram_high_threshold}"
  alarm_description   = "This alarm monitors ${aws_ecs_service.this.name} memory utilization for scaling up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "${var.ram_high_threshold}"
  alarm_actions       = ["${aws_appautoscaling_policy.ecs-scale-up-memory.arn}"]

  dimensions = {
    ClusterName = "${var.ecs_cluster_name}"
    ServiceName = "${aws_ecs_service.this.name}"
  }
}

####################################################################################
# A CloudWatch alarm that monitors memory utilization of containers for scaling down
####################################################################################
resource "aws_cloudwatch_metric_alarm" "ecs-service-memory-low" {
  alarm_name          = "${aws_ecs_service.this.name}-app-memory-utilization-below-${var.ram_low_threshold}"
  alarm_description   = "This alarm monitors ${aws_ecs_service.this.name} memory utilization for scaling down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "${var.ram_low_threshold}"
  alarm_actions       = ["${aws_appautoscaling_policy.ecs-scale-down-memory.arn}"]

  dimensions = {
    ClusterName = "${var.ecs_cluster_name}"
    ServiceName = "${aws_ecs_service.this.name}"
  }
}

#####################################
# Container scaling up policy for CPU
#####################################
resource "aws_appautoscaling_policy" "ecs-scale-up-cpu" {
  service_namespace  = "ecs"
  name               = "${aws_ecs_service.this.name}-scale-up-cpu"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = "${var.scaling_adjustment_add}"
    }
  }

  depends_on = [aws_appautoscaling_target.ecs]
}

########################################
# Container scalling down policy for CPU
#########################################
resource "aws_appautoscaling_policy" "ecs-scale-down-cpu" {
  service_namespace  = "ecs"
  name               = "${aws_ecs_service.this.name}-scale-down-cpu"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = "${var.scaling_adjustment_remove}"
    }
  }

  depends_on = [aws_appautoscaling_target.ecs]
}

#####################################
# Container scaling up policy for RAM
#####################################
resource "aws_appautoscaling_policy" "ecs-scale-up-memory" {
  service_namespace  = "ecs"
  name               = "${aws_ecs_service.this.name}-scale-up-memory"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = "${var.scaling_adjustment_add}"
    }
  }

  depends_on = [aws_appautoscaling_target.ecs]
}

#######################################
# Container scaling dwon policy for RAM
#######################################
resource "aws_appautoscaling_policy" "ecs-scale-down-memory" {
  service_namespace  = "ecs"
  name               = "${aws_ecs_service.this.name}-scale-down-memory"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = "${var.scaling_adjustment_remove}"
    }
  }

  depends_on = [aws_appautoscaling_target.ecs]
}
