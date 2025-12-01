output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.wireguard.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.wireguard.arn
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.wireguard.private_ip
}

output "public_ip" {
  description = "Elastic IP address (public)"
  value       = aws_eip.wireguard.public_ip
}

output "eip_allocation_id" {
  description = "Elastic IP allocation ID"
  value       = aws_eip.wireguard.id
}

output "kms_key_id" {
  description = "KMS key ID for EBS encryption"
  value       = aws_kms_key.ebs.id
}

output "kms_key_arn" {
  description = "KMS key ARN for EBS encryption"
  value       = aws_kms_key.ebs.arn
}
