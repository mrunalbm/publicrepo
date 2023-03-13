#######################################################################################################################
# Outputs for ASG Module
#######################################################################################################################

output "asg_id" {
  value       = "${aws_autoscaling_group.this.id}"
  description = "The ID of the ASG"
}

output "asg_arn" {
  value       = "${aws_autoscaling_group.this.arn}"
  description = "The ARN of the ASG"
}

output "asg_name" {
  value       = "${aws_autoscaling_group.this.name}"
  description = "The name of the ASG"
}

output "ecs_cluster_name" {
  value       = "${aws_ecs_cluster.this.name}"
  description = "The ECS cluster name"
}

output "ecs_cluster_id" {
  value       = "${aws_ecs_cluster.this.id}"
  description = "The ECS cluster ID"
}

output "ecs_sg_id" {
  value       = "${aws_security_group.ecs.id}"
  description = "The ECS security group id"
}

output "ecs_cluster_environment" {
  value       = "${var.environment}"
  description = "The ECS Environment name"
}
