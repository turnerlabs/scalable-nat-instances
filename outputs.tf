output "asg" {
  description = "The Autoscaling Group provisioning NAT instances"
  value       = aws_autoscaling_group.this
}

output "eni_ids" {
  description = "List of ENI IDs for the NAT instances"
  value       = [for i in aws_network_interface.this : i.id]
}

output "eni_private_ips" {
  description = "Private IPs of the ENI for the NAT instance"
  # workaround of https://github.com/terraform-providers/terraform-provider-aws/issues/7522
  value = flatten([for i in aws_network_interface.this : tolist(i.private_ips)])
}

output "sg_id" {
  description = "ID of the security group of the NAT instances"
  value       = aws_security_group.this.id
}

output "iam_role_name" {
  description = "Name of the IAM role for the NAT instances"
  value       = aws_iam_role.this.name
}
