/**
#Terraform Module - Generic VPC#

> This module creates all networking components.

# Overview #
* Generic module for deploying a customized VPC.
* It creates all networking components.

# Resources created within the module:

### VPC ###
  * Creates a new VPC.
  * You can edit different parameters when calling up the module.

### Subnet ###
  * Creates subnet resources.
  * You can choose whether to be private or public subnets.

### Routes ###
  * Creates public and private routes.
  * Creates a single RT for public access.
  * Creates as many private RT as the number of AZ deployed.

### Internet-Gateway ###
  * Creates an Internet-Gateway that will be attached to the VPC.
  * It creates a default route to the internet using the public-RT.

### NAT Gateway ###
  * Creates a NAT Gateway in each AZ.
  * It attaches the NAT Gateway to the private RT in each AZ.

### VPC Endpoints ###
  * Creates ECS Endpoint Services.
  * Creates ECR Endpoint

*/

#######################################################################################################################
# VPC Module
#######################################################################################################################

locals {
  max_subnet_length = "${max(length(var.private_subnets))}"
  nat_gateway_count = "${var.enable_nat_gateway_per_az ? length(var.azs) : 1}"
  vpc_id            = "${aws_vpc.main.id}"
}

######
# VPC
######
resource "aws_vpc" "main" {
  cidr_block                       = "${var.cidr}"
  instance_tenancy                 = "${var.instance_tenancy}"
  enable_dns_hostnames             = "${var.enable_dns_hostnames}"
  enable_dns_support               = "${var.enable_dns_support}"
  assign_generated_ipv6_cidr_block = "${var.assign_generated_ipv6_cidr_block}"

  #tags = "${merge(tomap("Name" = format("%s", var.vpc_name)), var.vpc_tags, var.tags)}"
  #tags = merge(var.additional_tags,{Name = "MyVPC"},)
}

###################
# Internet Gateway
###################
resource "aws_internet_gateway" "this" {
  count = "${length(var.public_subnets) > 0 ? 1 : 0}"

  vpc_id = "${local.vpc_id}"

  #tags = "${merge(tomap("Name", format("%s", var.igw_name)), var.tags)}"
}

########################################################################################################################
# Subnets
########################################################################################################################

################
# Public subnet
################
resource "aws_subnet" "public" {
  count = "${length(var.public_subnets) > 0 ? length(var.azs) : 0}"

  vpc_id                  = "${local.vpc_id}"
  cidr_block              = "${var.public_subnets[count.index]}"
  availability_zone       = "${element(var.azs, count.index)}"
  map_public_ip_on_launch = "${var.map_public_ip_on_launch}"

  #tags = "${merge(tomap("Name", format("public-%s", element(var.azs, count.index))), var.tags, var.subnet_tags)}"
}

#################
# Private subnet
#################
resource "aws_subnet" "private" {
  count = "${length(var.private_subnets) > 0 ? length(var.private_subnets) : 0}"

  vpc_id            = "${local.vpc_id}"
  cidr_block        = "${var.private_subnets[count.index]}"
  availability_zone = "${element(var.azs, count.index)}"

  #tags = "${merge(tomap("Name", format("private-%s", element(var.azs, count.index))), var.tags, var.subnet_tags)}"
}

##################
# Database subnet
##################
resource "aws_subnet" "database" {
  count = "${length(var.database_subnets) > 0 ? length(var.database_subnets) : 0}"

  vpc_id            = "${local.vpc_id}"
  cidr_block        = "${var.database_subnets[count.index]}"
  availability_zone = "${element(var.azs, count.index)}"

  #tags = "${merge(tomap("Name", format("db-%s", element(var.azs, count.index))), var.tags)}"
}

########################################################################################################################
# Route Tables
########################################################################################################################

######################
# Publiс route tables
######################
resource "aws_route_table" "public" {
  count = "${length(var.public_subnets) > 0 ? 1 : 0}"

  vpc_id = "${local.vpc_id}"

  #tags = "${merge(tomap("Name", format("%s-public", var.name)), var.tags)}"
}

######################
# Private route tables
######################
resource "aws_route_table" "private" {
  count = "${local.max_subnet_length > 0 ? local.nat_gateway_count : 0}"

  vpc_id = "${local.vpc_id}"

  #tags = "${merge(tomap("Name", (local.max_subnet_length > 0 ? format("private-%s", element(var.azs, count.index)) : "${var.name}-private" )), var.tags)}"

  lifecycle {
    ignore_changes = [propagating_vgws]
  }
}

########################################################################################################################
# Routes
########################################################################################################################

###############
# Public Routes
###############
resource "aws_route" "public_internet_gateway" {
  count = "${length(var.public_subnets) > 0 ? 1 : 0}"

  #route_table_id         = "${aws_route_table.public.id}"
  route_table_id         = "${element(aws_route_table.public.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  #gateway_id             = "${aws_internet_gateway.this.id}"
  gateway_id             = "${element(aws_internet_gateway.this.*.id, count.index)}"

  timeouts {
    create = "5m"
  }
}

####################
# Private NAT Routes
####################
resource "aws_route" "private_nat_gateway" {
  count = "${var.enable_nat_gateway ? local.nat_gateway_count : 0}"

  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.this.*.id, count.index)}"

  timeouts {
    create = "5m"
  }
}

########################################################################################################################
# NAT Gateway
########################################################################################################################
locals {
  nat_gateway_ips = "${aws_eip.nat.*.id}"
}

resource "aws_eip" "nat" {
  count = "${(var.enable_nat_gateway) ? local.nat_gateway_count : 0}"

  vpc = true

  #tags = "${merge(tomap("Name", format("%s-%s", var.name, element(var.azs, (var.enable_nat_gateway ? count.index : 0)))), var.tags)}"
}

resource "aws_nat_gateway" "this" {
  count = "${var.enable_nat_gateway ? local.nat_gateway_count : 0}"

  allocation_id = "${element(local.nat_gateway_ips, count.index)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"

  #tags = "${merge(tomap("Name", format("%s-%s", var.natgw_name, element(var.azs, (var.enable_nat_gateway ? count.index : 0)))), var.tags)}"

  depends_on = [aws_internet_gateway.this]
}

########################################################################################################################
# Route table association
########################################################################################################################
resource "aws_route_table_association" "private" {
  count = "${length(var.private_subnets) > 0 ? length(var.private_subnets) : 0}"

  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, (var.enable_nat_gateway ? count.index : 0))}"
}

resource "aws_route_table_association" "public" {
  count = "${length(var.public_subnets) > 0 ? length(var.public_subnets) : 0}"

  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public[0].id}"
}

resource "aws_route_table_association" "database" {
  count = "${length(var.database_subnets) > 0 ? length(var.database_subnets) : 0}"

  subnet_id      = "${element(aws_subnet.database.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, (var.enable_nat_gateway ? count.index : 0))}"
}



########################################################################################################################
# VPC Endpoint for CloudWatch
########################################################################################################################
data "aws_vpc_endpoint_service" "cw" {
  count = "${var.enable_cw_endpoint ? 1 : 0}"

  service = "logs"
}

resource "aws_vpc_endpoint" "cw" {
  count = "${var.enable_cw_endpoint ? 1 : 0}"

  vpc_id            = "${local.vpc_id}"
  service_name      = "${data.aws_vpc_endpoint_service.cw[0].service_name}"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.vpce_default.id}",
  ]

  subnet_ids = [
    "${slice(aws_subnet.private.*.id, 0, length(var.azs))}",
  ]

  private_dns_enabled = true
}

########################################################################################################################
# VPC Endpoint for Elastic Container Registry
########################################################################################################################
data "aws_vpc_endpoint_service" "ecr-dkr" {
  count = "${var.enable_ecr_endpoint ? 1 : 0}"

  service = "ecr.dkr"
}

data "aws_vpc_endpoint_service" "ecr-api" {
  count = "${var.enable_ecr_endpoint ? 1 : 0}"

  service = "ecr.api"
}

resource "aws_vpc_endpoint" "ecr-dkr" {
  count = "${var.enable_ecr_endpoint ? 1 : 0}"

  vpc_id            = "${local.vpc_id}"
  service_name      = "${data.aws_vpc_endpoint_service.ecr-dkr[0].service_name}"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.vpce_default.id}",
  ]

  subnet_ids = [
    "${slice(aws_subnet.private.*.id, 0, length(var.azs))}",
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr-api" {
  count = "${var.enable_ecr_endpoint ? 1 : 0}"

  vpc_id            = "${local.vpc_id}"
  service_name      = "${data.aws_vpc_endpoint_service.ecr-api[0].service_name}"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.vpce_default.id}",
  ]

  subnet_ids = [
    "${slice(aws_subnet.private.*.id, 0, length(var.azs))}",
  ]

  private_dns_enabled = true
}

########################################################################################################################
# VPC Endpoint for Elastic Container Service
########################################################################################################################
data "aws_vpc_endpoint_service" "ecs" {
  count = "${var.enable_ecs_endpoint ? 1 : 0}"

  service = "ecs"
}

data "aws_vpc_endpoint_service" "ecs-agent" {
  count = "${var.enable_ecs_endpoint ? 1 : 0}"

  service = "ecs-agent"
}

data "aws_vpc_endpoint_service" "ecs-telemetry" {
  count = "${var.enable_ecs_endpoint ? 1 : 0}"

  service = "ecs-telemetry"
}

resource "aws_vpc_endpoint" "ecs" {
  count = "${var.enable_ecs_endpoint ? 1 : 0}"

  vpc_id            = "${local.vpc_id}"
  service_name      = "${data.aws_vpc_endpoint_service.ecs[0].service_name}"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.vpce_default.id}",
  ]

  subnet_ids = [
    "${slice(aws_subnet.private.*.id, 0, length(var.azs))}",
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecs-agent" {
  count = "${var.enable_ecs_endpoint ? 1 : 0}"

  vpc_id            = "${local.vpc_id}"
  service_name      = "${data.aws_vpc_endpoint_service.ecs-agent[0].service_name}"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.vpce_default.id}",
  ]

  subnet_ids = [
    "${slice(aws_subnet.private.*.id, 0, length(var.azs))}",
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecs-telemetry" {
  count = "${var.enable_ecs_endpoint ? 1 : 0}"

  vpc_id            = "${local.vpc_id}"
  service_name      = "${data.aws_vpc_endpoint_service.ecs-telemetry[0].service_name}"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.vpce_default.id}",
  ]

  subnet_ids = [
    "${slice(aws_subnet.private.*.id, 0, length(var.azs))}",
  ]

  private_dns_enabled = true
}



########################################################################################################################
# Security Groups
########################################################################################################################

########################
# Default Security Group
########################
resource "aws_default_security_group" "default" {
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#####################################
# VPC Endpoint Default Security Group
#####################################
resource "aws_security_group" "vpce_default" {
  name        = "default-vpce"
  description = "Default Security Group used for VPC Endpoints (allow access from VPC)"
  vpc_id      = "${local.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${aws_vpc.main.cidr_block}"]
  }
}
