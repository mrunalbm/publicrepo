variable "app_name" {
  description = "The name of the APP"
  type        = string
}

variable "environment" {
  description = "The name of the environment. Used within tagging"
  type        = string
}

variable "lb_subnets" {
  description = "The subnet IDs used to spin-up the Load Balancer"
  type        = list
}

variable "internal" {
  description = "Set to `true` if you want youe NLB to be internal"
  default     = false
}

variable "tags" {
  description = "More tags"
  type        = map
  default     = {}
}

variable "access_logs_s3" {
  description = "S3 path for access log LB"
  type        = string
  default     = false  
}

variable "access_logs_status" {
  description = "Set to `true` if you want youe NLB to be internal"  
  default     = false
}
