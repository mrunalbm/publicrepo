#######################################################################################################################
# ASG Module
#######################################################################################################################

locals {
  name = "${var.environment}-${var.name}"
}

##################
# Userdata for EC2
##################
data "template_file" "ecs-user-data" {
  template = "${file("${path.module}/files/ecs_linux_user_data.sh")}"
  vars = {
    cluster_name = "${aws_ecs_cluster.this.name}"
  }
}

data "template_cloudinit_config" "ecs-user-data" {
  gzip          = "false"
  base64_encode = "false"

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.ecs-user-data.rendered}"
  }
}

#########################
# Security Group for EC2
#########################
resource "aws_security_group" "ecs" {
  name   = "${local.name}"
  #vpc_id = "${data.aws_subnet.cluster.vpc_id}"
  vpc_id = "${var.vpc_id}"

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    self      = true
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.allowed_ssh_cidr}"]
  }

  ingress {
    from_port   = "${var.container_from_port}"
    protocol    = "tcp"
    to_port     = "${var.container_to_port}"
    cidr_blocks = ["${var.allowed_cidr}"]
  }
    
}

##########
# Key Pair
##########
resource "aws_key_pair" "this" {
  key_name   = "${local.name}"
  public_key = "${var.public_key}"
}

###################
# IAM role for EC2
###################
resource "aws_iam_role" "ecs-instance" {
  name = "${local.name}"
  path = "${var.iam_path}"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-instance" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role       = "${aws_iam_role.ecs-instance.id}"
}

# Session Manager policy

data "aws_iam_policy_document" "session-manager" {
  count = "${var.enable_sessionmanager}"

  statement {
    actions = [
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]

    resources = ["*"]
  }

  statement {
    actions   = ["s3:GetEncryptionConfiguration"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "session-manager" {
  count = "${var.enable_sessionmanager}"

  name   = "${local.name}-session-manager"
  policy = "${data.aws_iam_policy_document.session-manager[0].json}"
}

resource "aws_iam_role_policy_attachment" "session-manager" {
  count = "${var.enable_sessionmanager}"

  role       = "${aws_iam_role.ecs-instance.id}"
  policy_arn = "${aws_iam_policy.session-manager[0].arn}"
}

# Instance profile

resource "aws_iam_instance_profile" "ecs" {
  name = "${local.name}"
  path = "${var.iam_path}"
  role = "${aws_iam_role.ecs-instance.name}"
}

###############
# Launch config
###############
resource "aws_launch_configuration" "this" {
  name_prefix   = "${local.name}"
  image_id      = "${var.ecs_image_id}"
  instance_type = "${var.instance_type}"
  key_name      = "${aws_key_pair.this.key_name}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.disk_size}"
  }

  iam_instance_profile = "${aws_iam_instance_profile.ecs.name}"
  security_groups      = ["${aws_security_group.ecs.id}"]
  user_data            = "${data.template_cloudinit_config.ecs-user-data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

######
# ASG
######
resource "aws_autoscaling_group" "this" {
  name                      = "ASG-${local.name}"
  launch_configuration      = "${aws_launch_configuration.this.name}"
  vpc_zone_identifier       = ["${var.subnet_ids[0]}" , "${var.subnet_ids[1]}"]
  min_size                  = "${var.min_size}"
  max_size                  = "${var.max_size}"
  default_cooldown          = "${var.default_cooldown}"
  health_check_grace_period = "${var.health_check_grace_period}"
  enabled_metrics           = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]

  tag {
    key                 = "CreatedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "ASG-${local.name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "${var.environment}"
    propagate_at_launch = true
  }
}

##############
# ECS Cluster
##############
resource "aws_ecs_cluster" "this" {
  name = "${local.name}-cluster"
}

#########################################################################################
# A CloudWatch alarm that monitors memory reservation of the EC2 instance for scaling up
#########################################################################################
resource "aws_cloudwatch_metric_alarm" "ecs-memory-reservation-high" {
  count = "${var.enable_memory_autoscaling}"

  alarm_name          = "${aws_ecs_cluster.this.name}-memory-reservation-above-${var.memory_reservation_high_threshold}"
  alarm_description   = "This alarm monitors the ECS cluster ${aws_ecs_cluster.this.name} memory reservation for scaling up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryReservation"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "${var.memory_reservation_high_threshold}"

  alarm_actions = [
    "${element(aws_autoscaling_policy.ecs-scale-up-memory-reservation.*.arn, 0)}",
  ]
}

###########################################################################################
# A CloudWatch alarm that monitors memory reservation of the EC2 instance for scaling down
###########################################################################################
resource "aws_cloudwatch_metric_alarm" "ecs-memory-reservation-low" {
  count = "${var.enable_memory_autoscaling}"

  alarm_name          = "${aws_ecs_cluster.this.name}-memory-reservation-below-${var.memory_reservation_low_threshold}"
  alarm_description   = "This alarm monitors the ECS cluster ${aws_ecs_cluster.this.name} memory reservation for scaling down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryReservation"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "${var.memory_reservation_low_threshold}"

  alarm_actions = [
    "${element(aws_autoscaling_policy.ecs-scale-down-memory-reservation.*.arn, 0)}",
  ]
}

#####################################################################################
# A CloudWatch alarm that monitors cpu reservation of the EC2 instance for scaling up
#####################################################################################
resource "aws_cloudwatch_metric_alarm" "ecs-cpu-reservation-high" {
  count = "${var.enable_cpu_autoscaling}"

  alarm_name          = "${aws_ecs_cluster.this.name}-cpu-reservation-above-${var.cpu_reservation_high_threshold}"
  alarm_description   = "This alarm monitors the ECS cluster ${aws_ecs_cluster.this.name} cpu reservation for scaling up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "${var.cpu_reservation_high_threshold}"

  alarm_actions = [
    "${element(aws_autoscaling_policy.ecs-scale-up-cpu-reservation.*.arn, 0)}",
  ]
}

#######################################################################################
# A CloudWatch alarm that monitors cpu reservation of the EC2 instance for scaling down
#######################################################################################
resource "aws_cloudwatch_metric_alarm" "ecs-cpu-reservation-low" {
  count = "${var.enable_cpu_autoscaling}"

  alarm_name          = "${aws_ecs_cluster.this.name}-cpu-reservation-below-${var.cpu_reservation_low_threshold}"
  alarm_description   = "This alarm monitors the ECS cluster ${aws_ecs_cluster.this.name} cpu reservation for scaling down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "${var.cpu_reservation_low_threshold}"

  alarm_actions = [
    "${element(aws_autoscaling_policy.ecs-scale-down-cpu-reservation.*.arn, 0)}",
  ]
}

###########################
# ASG ECS scaling policies
###########################
resource "aws_autoscaling_policy" "ecs-scale-up-memory-reservation" {
  count = "${var.enable_memory_autoscaling}"

  name                   = "${aws_autoscaling_group.this.name}-scale-up-memory-reservation"
  autoscaling_group_name = "${aws_autoscaling_group.this.name}"

  adjustment_type    = "ChangeInCapacity"
  policy_type        = "SimpleScaling"
  cooldown           = "300"
  scaling_adjustment = "1"
}

resource "aws_autoscaling_policy" "ecs-scale-down-memory-reservation" {
  count = "${var.enable_memory_autoscaling}"

  name                   = "${aws_autoscaling_group.this.name}-scale-down-memory-reservation"
  autoscaling_group_name = "${aws_autoscaling_group.this.name}"

  adjustment_type    = "ChangeInCapacity"
  policy_type        = "SimpleScaling"
  cooldown           = "300"
  scaling_adjustment = "-1"
}

resource "aws_autoscaling_policy" "ecs-scale-up-cpu-reservation" {
  count = "${var.enable_cpu_autoscaling}"

  name                   = "${aws_autoscaling_group.this.name}-scale-up-cpu-reservation"
  autoscaling_group_name = "${aws_autoscaling_group.this.name}"

  adjustment_type    = "ChangeInCapacity"
  policy_type        = "SimpleScaling"
  cooldown           = "300"
  scaling_adjustment = "1"
}

resource "aws_autoscaling_policy" "ecs-scale-down-cpu-reservation" {
  count = "${var.enable_cpu_autoscaling}"

  name                   = "${aws_autoscaling_group.this.name}-scale-down-cpu-reservation"
  autoscaling_group_name = "${aws_autoscaling_group.this.name}"

  adjustment_type    = "ChangeInCapacity"
  policy_type        = "SimpleScaling"
  cooldown           = "300"
  scaling_adjustment = "-1"
}
