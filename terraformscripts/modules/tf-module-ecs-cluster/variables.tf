#######################################################################################################################
# Variables for ASG Module
#######################################################################################################################

variable "environment" {
  description = "The environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "name" {
  description = "The name for the ASG Launch Configuration to be created"
  type        = string
}

variable "public_key" {
  type        = string
  description = "The public key part to use when connecting to the ECS instances"
}

variable "instance_type" {
  description = "Instance type that should be used"
  type        = string
  default     = "t2.micro"
}

variable "disk_size" {
  description = "The size of the root disk used for instance"
  type        = string
  default     = "32"
}

variable "user_data" {
  description = "A string containing entries for user_data"
  type        = string
  default     = ""
}

variable "desired_capacity" {
  description = "The desired size of the asg"
  default     = "1"
}

variable "min_size" {
  description = "The minimum group size of the instances that should be used"
  type        = string
  default     = "1"
}

variable "max_size" {
  description = "The maximum group size of the instances that should be used"
  type        = string
  default     = "10"
}

variable "subnet_ids" {
  description = "A list with the subnets used for ASG instances"
  type        = list
}

variable "iam_path" {
  description = "The path for the IAM resources"
  type        = string
  default     = "/"
}

variable "default_cooldown" {
  description = "The number of seconds after a scaling activity completes before another can begin"
  type        = string
  default     = "300"
}

variable "health_check_grace_period" {
  description = "The length of time that Auto Scaling waits before checking an instance's health status"
  type        = string
  default     = "300"
}

#############
# Autoscaling
#############

variable "enable_memory_autoscaling" {
  description = "Enable autoscaling trigger for memory reservation. Default: `0`. 0=False 1=True"
  default     = 0
}

variable "enable_cpu_autoscaling" {
  description = "Enable autoscaling trigger for CPU reservation. Default: `0`. 0=False 1=True"
  default     = 0
}

###########
# Threshold
###########
variable "memory_reservation_high_threshold" {
  description = "Memory reservation above this value will trigger autoscaling to launch an additional EC2 instance in the cluster"
  type        = string
  default     = "70"
}

variable "memory_reservation_low_threshold" {
  description = "Memory reservation below this value will trigger autoscaling to remove an EC2 instance from the cluster"
  type        = string
  default     = "40"
}

variable "cpu_reservation_high_threshold" {
  description = "CPU reservation above this value will trigger autoscaling to launch an additional EC2 instance in the cluster"
  type        = string
  default     = "70"
}

variable "cpu_reservation_low_threshold" {
  description = "CPU reservation below this value will trigger autoscaling to remove an EC2 instance from the cluster"
  type        = string
  default     = "40"
}

###########
# Tags
###########
variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
  type        = map
}

#####################
# AWS Session Manager
#####################
variable "enable_sessionmanager" {
  description = "Set to true if you want to access EC2 instances via AWS SSM Session Manager. 0=False, 1=True"
  default     = 1
}

variable "allowed_ssh_cidr" {
  description = "A CIDR block allowed to connect via SSH to ECS instances"
  type        = string
  default     = "0.0.0.0/0"
}

variable "allowed_cidr" {
  description = "A CIDR block allowed to connect on docker ports to ECS instances"
  type        = string
  default     = "0.0.0.0/0"
}

variable "container_from_port" {
  description = "Application container port - lower limit"
  type        = string
  default     = 0
}

variable "container_to_port" {
  description = "Application container port - upper limit"
  type        = string
  default     = 0
}

##################
# AMI
##################

variable "ecs_image_id" {
  description = "AMI ID used for ECS instances"
  type        = string
}


