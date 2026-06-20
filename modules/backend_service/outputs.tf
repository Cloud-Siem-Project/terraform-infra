output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.backend.id
}

output "public_ip" {
  description = "Elastic IP attached to the backend"
  value       = aws_eip.backend.public_ip
}

output "public_dns" {
  description = "Public DNS for the EIP — use as CloudFront custom origin domain"
  value       = aws_eip.backend.public_dns
}

output "api_port" {
  description = "Port master.py listens on"
  value       = var.api_port
}

output "private_ip" {
  description = "Private IP of the master — workers POST here over the VPC"
  value       = aws_instance.backend.private_ip
}

output "security_group_id" {
  description = "Master security group ID"
  value       = aws_security_group.backend.id
}

output "vpc_id" {
  description = "VPC the master lives in"
  value       = data.aws_vpc.default.id
}
