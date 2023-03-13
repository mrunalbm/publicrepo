#######################################################################################################################
# Outputs for ECS Service Module
#######################################################################################################################

output "ecs_service_id" {
  value       = "${aws_ecs_service.this.id}"
  description = "The ID of the ECS service"
}

output "ecs_service_name" {
  value       = "${aws_ecs_service.this.name}"
  description = "The name of the ECS service"
}

output "ecs_task_def_id" {
  value       = "${aws_ecs_task_definition.this.id}"
  description = "The ID of the ECS task definition"
}

output "ecs_task_def_arn" {
  value       = "${aws_ecs_task_definition.this.arn}"
  description = "The ID of the ECS task definition"
}

output "ecs_cloudwatch_log_group_name" {
  value       = "${aws_cloudwatch_log_group.this.name}"
  description = "The name of the CloudWatch Log group"
}

output "ecs_task_role_id" {
  value       = "${aws_iam_role.ecs-task.id}"
  description = "The role used by the ECS task"
}

output "ecs_lb_port" {
  value = "${var.lb_listener_port}"
}
