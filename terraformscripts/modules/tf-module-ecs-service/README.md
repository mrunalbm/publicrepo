
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| app_name | The name of the APP | string | - | yes |
| appautoscaling_ecs_max_capacity | The max capacity of the scalable target | string | `1` | no |
| appautoscaling_ecs_min_capacity | The min capacity of the scalable target | string | `10` | no |
| container_definition | A list of valid container definitions provided as a single valid JSON document. Please note that you should only provide values that are part of the container definition document | string | - | yes |
| cpu_high_threshold | Treshold for cloudwatch alarm to monitor CPU utilization for scaling up | string | `70` | no |
| cpu_low_threshold | Treshold for cloudwatch alarm to monitor CPU utilization for scaling down | string | `20` | no |
| deployment_maximum_percent | The upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment. Not valid when using the DAEMON scheduling strategy. | string | `200` | no |
| deployment_minimum_healthy_percent | The lower limit (as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment. Not valid when using the DAEMON scheduling strategy. | string | `100` | no |
| desired_count | Desired count for ecs tasks | string | `1` | no |
| ecs_cluster_id | The ARN of the ECS cluster | string | - | yes |
| ecs_cluster_name | The name of the cluster in which to add the ecs service | string | - | yes |
| ecs_image_version | The image version from ECR | string | `latest` | no |
| environment | The name of the environment. Used within tagging | string | - | yes |
| health_check_grace_period_seconds | Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 7200. Only valid for services configured to use load balancers. | string | `300` | no |
| ram_high_threshold | Treshold for cloudwatch alarm to monitor RAM utilization for scaling up | string | `70` | no |
| ram_low_threshold | Treshold for cloudwatch alarm to monitor RAM utilization for scaling down | string | `20` | no |
| scaling_adjustment_add | The number of tasks to add in case of scale out | string | `1` | no |
| scaling_adjustment_remove | The number of tasks to remove in case of scale in | string | `-1` | no |
| tags | More tags | map | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| ecs_cloudwatch_log_group_name | The name of the CloudWatch Log group |
| ecs_service_id | The ID of the ECS service |
| ecs_service_name | The name of the ECS service |
| ecs_task_def_arn | The ID of the ECS task definition |
| ecs_task_def_id | The ID of the ECS task definition |

