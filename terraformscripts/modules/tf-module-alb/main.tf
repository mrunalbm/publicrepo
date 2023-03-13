#######################################################################################################################
# Network Load Balancer Module
#######################################################################################################################

locals {
  name = "${var.environment}-${var.app_name}"
}

resource "aws_lb" "this" {
  name                             = "${local.name}-alb"
  internal                         = "${var.internal}"
  load_balancer_type               = "application"
  subnets                          = ["${var.lb_subnets[0]}" , "${var.lb_subnets[1]}"]
  enable_cross_zone_load_balancing = true
  
  access_logs {
    bucket  = "${var.access_logs_s3}"    
    enabled = "${var.access_logs_status}"
  }
}
