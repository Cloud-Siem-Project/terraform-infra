output "instance_id" { value = aws_instance.sim.id }
output "security_group_id" { value = aws_security_group.sim.id }
output "private_ip" { value = aws_instance.sim.private_ip }
