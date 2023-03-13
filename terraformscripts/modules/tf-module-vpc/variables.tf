#######################################################################################################################
# Variables for Networking Module
#######################################################################################################################

######
# VPC
######
variable "name" {
  description = "Name to be used on all the resources as identifier and the VPC name"
  type        = string
  default     = ""
}

variable "vpc_name" {
  description = "Name to be used on all the resources as identifier and the VPC name"
  type        = string
  default     = "main"
}


variable "igw_name" {
  description = "Name to be used on all the resources as identifier and the VPC name"
  type        = string
  default     = "IGW"
}


variable "natgw_name" {
  description = "Name to be used on all the resources as identifier and the VPC name"
  type        = string
  default     = "NATGW"
}


variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, eg: 192.168.100.0/24"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "A list of availability zones in the region, eg ['eu-west-1a','eu-west-1b']"
  default     = []
  type        = list
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  default     = "default"
  type        = string
}

variable "assign_generated_ipv6_cidr_block" {
  description = "Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC. You cannot specify the range of IP addresses, or the size of the CIDR block"
  default     = false
  type        = string
}

#########
# Subnets
#########
variable "public_subnets" {
  description = "A list of public subnets inside the VPC, eg: [192.168.100.0/24, 192.168.200.0/24]"
  default     = []
  type        = list
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC, eg: [192.168.100.0/24, 192.168.200.0/24]"
  default     = []
  type        = list
}

variable "database_subnets" {
  description = "A list of database subnets inside the VPC, eg: [192.168.100.0/24, 192.168.200.0/24]"
  default     = []
  type        = list
}

variable "create_database_subnet_group" {
  description = "Controls if database subnet group should be created"
  default     = true
  type        = string
}

variable "map_public_ip_on_launch" {
  description = "Should be false if you do not want to auto-assign public IP on launch in the public subnet"
  default     = true
  type        = string
}

###############
# NAT Gateways
###############
variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateway"
  default     = true
  type        = string
}

variable "enable_nat_gateway_per_az" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks (AZs)"
  default     = true
  type        = string
}

###################
# Endpoint Services
###################
variable "enable_s3_endpoint" {
  description = "Should be true if you want to provision an S3 endpoint to the VPC"
  default     = true
  type        = string
}

variable "enable_cw_endpoint" {
  description = "Should be true if you want to provision a CloudWatch endpoint to the VPC"
  default     = true
  type        = string
}

variable "enable_ecr_endpoint" {
  description = "Should be true if you want to provision an ECR endpoint to the VPC"
  default     = true
  type        = string
}

variable "enable_ecs_endpoint" {
  description = "Should be true if you want to provision an ECS endpoint to the VPC"
  default     = true
  type        = string
}


#############
# DNS Support
#############
variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  default     = true
  type        = string
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  default     = true
  type        = string
}

#######
# Tags
#######
variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
  type        = map(string)
}

variable "subnet_tags" {
  description = "A map of tags to add to subnets"
  default     = {}
  type        = map(string)
}

variable "vpc_tags" {
  description = "Additional tags for the VPC"
  default     = {}
  type        = map
}
