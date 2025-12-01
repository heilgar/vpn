output "wireguard_sg_id" {
  description = "ID of the WireGuard security group"
  value       = aws_security_group.wireguard.id
}

output "wireguard_sg_arn" {
  description = "ARN of the WireGuard security group"
  value       = aws_security_group.wireguard.arn
}
