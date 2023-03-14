/*
locals {
  encoded_container_definition  = "${jsonencode(local.container_definition)}"
}
*/

locals {
  encoded_container_definition  = "${replace(replace(replace(jsonencode(local.container_definition), "/(\\[\\]|\\[\"\"\\]|\"\"|{})/", "null"), "/\"(true|false)\"/", "$1"), "/\"([0-9]+\\.?[0-9]*)\"/", "$1")}"
}

output "json" {
  description = "JSON encoded container definitions for use with other terraform resources such as aws_ecs_task_definition."
  value       = "[${local.encoded_container_definition}]"
}

output "container_name" {
  description = "Name of the container"
  value       = "${var.container_name}"
}
