output "alb_id" {
  value       = "${aws_lb.this.id}"
  description = "The ID of the Network Load Balancer"
}

output "alb_zone_id" {
  value       = "${aws_lb.this.zone_id}"
  description = "The DNS Zone ID for Network Load Balancer"
}

output "alb_dns_name" {
  value       = "${aws_lb.this.dns_name}"
  description = "The DNS Name of the Network Load Balancer"
}
