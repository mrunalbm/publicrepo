provider "aws" {
   profile = "dev"
}

terraform {
  backend "s3" {
    bucket = "my-tf-statefile-bucket"
    key    = "tfstate"
    region = "eu-west-2"
  }
}


module "aws-vpc" {
  source = "../modules/tf-module-vpc"

  vpc_name = "${var.vpc_name}"
  cidr = "${var.cidr}"
  public_subnets = "${var.public_subnets}"
  private_subnets = "${var.private_subnets}"
  azs = "${var.azs}"
  database_subnets = "${var.database_subnets}"

}


module "aws-ecr" {
  source = "../modules/tf-module-ecr"

  ecr_repos = ["webapp"]
  create_ecr_full_policy = "true"
  create_ecr_pull_policy = "true"
  enable_lifecycle_policy = "true"
  accounts_ids  = "${var.account_id}"
  image_tag_prefix = "WebApp"

}


module "aws-ecs-cluster" {
  source = "../modules/tf-module-ecs-cluster"
  
  environment = "${var.environment}"
  name = "WebApp"
  subnet_ids = ["${module.aws-vpc.private_subnets_id1}", "${module.aws-vpc.private_subnets_id2}"]
  ecs_image_id = "${var.ecs_image_id}"
  vpc_id = "${module.aws-vpc.vpc_id}"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ1+ecGWaKo2tDRHusRnNGfFh3JGyCgG19gCAEd4o4Ln mrunalbm@gmail.com"

  enable_memory_autoscaling = 1
  enable_cpu_autoscaling    = 1

  container_from_port = 8080
  container_to_port   = 8080
 
}

module "aws-elb-alb" {
  source = "../modules/tf-module-alb"

  environment = "${var.environment}"
  app_name = "WebApp"

  lb_subnets = ["${module.aws-vpc.public_subnets_id1}", "${module.aws-vpc.public_subnets_id2}"]

}

module "aws-ecs-task-definition" {
  source = "../modules/tf-module-ecs-task-definition"
 
  container_name               = "webapp"
  container_image              = "${var.ecr_reposiroty_url}:latest"
  container_memory_reservation = "512"
  container_cpu                = "1024"

  port_mappings = [
    {
      "containerPort" = 80
      "protocol"      = "http"
    },
  ]

  log_driver = "awslogs"

  log_options = {
    "awslogs-region"        = "${var.region}"
    "awslogs-group"         = "/ecs/${module.aws-ecs-cluster.ecs_cluster_name}/webapp"
    "awslogs-stream-prefix" = "webapp"
  }
}

module "aws-ecs-service" {
  source = "../modules/tf-module-ecs-service"

  app_name    = "webapp"
  environment = "${var.environment}"

  ecs_cluster_id   = "${module.aws-ecs-cluster.ecs_cluster_id}"
  ecs_cluster_name = "${module.aws-ecs-cluster.ecs_cluster_name}"

  deployment_minimum_healthy_percent = "100"
  deployment_maximum_percent         = "200"

  subnets         = ["${module.aws-vpc.private_subnets_id1}", "${module.aws-vpc.private_subnets_id2}"]
  security_groups = ["${module.aws-ecs-cluster.ecs_sg_id}"]

  container_definition = "${module.aws-ecs-task-definition.json}"

  enable_cpu_autoscaling    = false
  enable_memory_autoscaling = false

  vpc_id         = "${module.aws-vpc.vpc_id}"
  container_name = "webapp"
  container_port = 80

  lb_healthcheck_path     = "/"
  lb_deregistration_delay = "30"
  lb_listener_port        = "8082"
  lb_listener_protocol    = "HTTP"
  lb_id                   = "${module.aws-elb-alb.alb_id}"
  
}