output "security_group_id" {
  description = "Worker SG — add as a trusted source on the master SG"
  value       = aws_security_group.worker.id
}

output "instance_ids" {
  description = "Worker instance IDs, keyed by distro"
  value       = { for k, i in aws_instance.worker : k => i.id }
}

output "private_ips" {
  description = "Worker private IPs, keyed by distro"
  value       = { for k, i in aws_instance.worker : k => i.private_ip }
}

output "node_ids" {
  description = "Worker node_ids that will appear in /api/nodes"
  value       = { for k, v in local.workers : k => v.node_id }
}
