#######################################################################################################################
# Outputs for Networking Module
#######################################################################################################################

######
# VPC
######

output "vpc_id" {
  description = "The ID of the VPC"
  value       = "${aws_vpc.main.id}"
}

#########
# Subnets
#########


output "private_subnets_id1" {
  description = "List of IDs of private subnets"
  value       = "${aws_subnet.private[0].id}"
}

output "private_subnets_id2" {
  description = "List of IDs of private subnets"
  value       = "${aws_subnet.private[1].id}"
}

output "public_subnets_id1" {
  description = "List of IDs of public subnets"
  value       = "${aws_subnet.public[0].id}"
}

output "public_subnets_id2" {
  description = "List of IDs of public subnets"
  value       = "${aws_subnet.public[1].id}"
}