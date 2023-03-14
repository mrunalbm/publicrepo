######
# Account
######

variable "account_id" {
  description = "Account Id of account to be used"
  type        = list
  default     = ["493740600894"]
}

variable "environment" {
  description = "Env Type to use this for"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "region to use"
  type        = string
  default     = "eu-west-2"
}

########
# ECS
########

variable "ecs_image_id" {
  description = "Image to be used with ECS for Auto Scaling Group"
  type = string
  default = "ami-0a9d0b31a17ab6ef5"
}

variable "ecr_reposiroty_url" {
  description = "Repository to use"
  type = string
  default = "493740600894.dkr.ecr.eu-west-2.amazonaws.com/webapp"
}



#######################################################################################################################
# Variables for Networking Module
#######################################################################################################################

######
# VPC
######

variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, eg: 192.168.100.0/24"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "A list of availability zones in the region, eg ['eu-west-1a','eu-west-1b']"
  default     = ["eu-west-2a","eu-west-2b"]
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

variable "vpc_name" {
  description = "Name to be used on all the resources as identifier and the VPC name"
  type        = string
  default     = "main"
}



#########
# Subnets
#########
variable "public_subnets" {
  description = "A list of public subnets inside the VPC, eg: [192.168.100.0/24, 192.168.200.0/24]"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  type        = list
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC, eg: [192.168.100.0/24, 192.168.200.0/24]"
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
  type        = list
}

variable "database_subnets" {
  description = "A list of database subnets inside the VPC, eg: [192.168.100.0/24, 192.168.200.0/24]"
  default     = ["10.0.5.0/24", "10.0.6.0/24"]
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
  default     = {Managedby="Terraform"}
  type        = map
}

