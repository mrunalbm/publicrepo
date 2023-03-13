#######################################################################################################################
# Variables for ECS Service Module
#######################################################################################################################

variable "app_name" {
  description = "The name of the APP"
  type        = string
}

variable "container_definition" {
  description = "A list of valid container definitions provided as a single valid JSON document. Please note that you should only provide values that are part of the container definition document"
  type        = string
}

variable "desired_count" {
  description = "Desired count for ecs tasks"
  type        = string
  default     = "1"
}

variable "ecs_cluster_name" {
  description = "The name of the cluster in which to add the ecs service"
  type        = string
}

variable "environment" {
  description = "The name of the environment. Used within tagging"
  type        = string
}

variable "ecs_cluster_id" {
  description = "The ARN of the ECS cluster"
  type        = string
}

variable "subnets" {
  description = "The subnets associated with the task or service"
  type        = list
}

variable "security_groups" {
  description = "The security groups associated with the task or service"
  type        = list
}

variable "lb_healthcheck_protocol" {
  description = "(Optional) The protocol to use to connect with the target. Options are: TCP, HTTP, HTTPS. Defaults to `HTTP`"
  type        = string
  default     = "HTTP"
}

variable "lb_healthcheck_port" {
  description = "(Optional) The port to use to connect with the target. Valid values are either ports `1-65536` or `traffic-port`. Defaults to `traffic-port`"
  type        = string
  default     = "traffic-port"
}

variable "lb_healthcheck_path" {
  description = "The Path used by the LB Health Check"
  type        = string
  default     = "/"
}

variable "lb_listener_port" {
  type        = string
  description = "The port on which the NLB will receive traffic. Defaults to `80`"
  default     = "80"
}

variable "lb_listener_protocol" {
  type        = string
  description = "The protocol for ALB listener. Protocols: `HTTP`, `HTTPS`. Defaults to `HTTP`"
  default     = "HTTP"
}

variable "lb_id" {
  type        = string
  description = "Network Load Balancer ID"
}

variable "lb_deregistration_delay" {
  type        = string
  description = "(Optional) The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is `0-3600` seconds. The default value is `300` seconds."
  default     = 300
}

variable "vpc_id" {
  description = "The ID of VPC where you spin-up the load balancer"
  type        = string
}

variable "container_name" {
  description = "The name of the container (please see task definition)"
  type        = string
}

variable "container_port" {
  description = "The port of the container (please see task definition)"
  type        = string
}

variable "health_check_grace_period_seconds" {
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 7200. Only valid for services configured to use load balancers."
  type        = string
  default     = "300"
}

variable "deployment_maximum_percent" {
  description = "The upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment. Not valid when using the DAEMON scheduling strategy."
  type        = string
  default     = "200"
}

variable "deployment_minimum_healthy_percent" {
  description = "The lower limit (as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment. Not valid when using the DAEMON scheduling strategy."
  type        = string
  default     = "100"
}

variable "cpu_high_threshold" {
  description = "Treshold for cloudwatch alarm to monitor CPU utilization for scaling up"
  type        = string
  default     = "70"
}

variable "cpu_low_threshold" {
  description = "Treshold for cloudwatch alarm to monitor CPU utilization for scaling down"
  type        = string
  default     = "20"
}

variable "ram_high_threshold" {
  description = "Treshold for cloudwatch alarm to monitor RAM utilization for scaling up"
  type        = string
  default     = "70"
}

variable "ram_low_threshold" {
  description = "Treshold for cloudwatch alarm to monitor RAM utilization for scaling down"
  type        = string
  default     = "20"
}

variable "ecs_image_version" {
  description = "The image version from ECR"
  default     = "latest"
  type        = string
}

variable "tags" {
  description = "More tags"
  type        = map
  default     = {}
}

variable "appautoscaling_ecs_min_capacity" {
  description = "The min capacity of the scalable target"
  type        = string
  default     = "1"
}

variable "appautoscaling_ecs_max_capacity" {
  description = "The max capacity of the scalable target"
  type        = string
  default     = "10"
}

variable "scaling_adjustment_add" {
  description = "The number of tasks to add in case of scale out"
  type        = string
  default     = "1"
}

variable "scaling_adjustment_remove" {
  description = "The number of tasks to remove in case of scale in"
  type        = string
  default     = "-1"
}

variable "strategy_type" {
  description = "Default ordered placement strategy for the ECS service for stratergy type "
  default     = "binpack"
  type        = string
}

variable "strategy_field" {
  description = "Default ordered placement strategy for the ECS service for stratergy field"
  default     = "cpu"
  type        = string
}

