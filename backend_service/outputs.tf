output "instance_id" {
  description = "EC2 instance ID — used by CI/CD (SSM deploy)"
  value       = module.backend_service.instance_id
}

output "public_ip" {
  description = "Elastic IP of the master backend instance"
  value       = module.backend_service.public_ip
}

# Consumed by the dashboard layer via terraform_remote_state — used as the
# CloudFront custom origin domain for /api/* routing.
output "api_origin_domain" {
  description = "Public DNS to use as CloudFront origin domain"
  value       = module.backend_service.public_dns
}

output "api_port" {
  description = "Port master.py listens on"
  value       = module.backend_service.api_port
}

output "master_private_ip" {
  description = "Master private IP — workers use this over VPC"
  value       = module.backend_service.private_ip
}

output "worker_instance_ids" {
  description = "Worker instance IDs by distro"
  value       = module.worker_nodes.instance_ids
}

output "worker_private_ips" {
  description = "Worker private IPs by distro"
  value       = module.worker_nodes.private_ips
}

output "worker_node_ids" {
  description = "Worker node_ids that show up in /api/nodes"
  value       = module.worker_nodes.node_ids
}
