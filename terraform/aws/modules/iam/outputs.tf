output "instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.wireguard.name
}

output "instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = aws_iam_instance_profile.wireguard.arn
}

output "instance_role_name" {
  description = "Name of the EC2 IAM role"
  value       = aws_iam_role.wireguard.name
}

output "instance_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.wireguard.arn
}

output "vpc_flow_logs_role_arn" {
  description = "ARN of the VPC Flow Logs IAM role"
  value       = var.create_flow_logs_role ? aws_iam_role.vpc_flow_logs[0].arn : ""
}

output "dlm_role_arn" {
  description = "ARN of the DLM IAM role for automated snapshots"
  value       = aws_iam_role.dlm.arn
}
