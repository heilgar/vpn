# Outputs for Ansible integration and infrastructure information

################################################################################
# Network Information
################################################################################

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = module.vpc.public_subnet_id
}

################################################################################
# EC2 Instance Information (for Ansible)
################################################################################

output "instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of WireGuard server (use this in Ansible inventory)"
  value       = module.ec2.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of WireGuard server"
  value       = module.ec2.private_ip
}

################################################################################
# Security Information
################################################################################

output "security_group_id" {
  description = "Security group ID for WireGuard server"
  value       = module.security_groups.wireguard_sg_id
}

output "kms_ebs_key_arn" {
  description = "KMS key ARN for EBS encryption"
  value       = module.ec2.kms_key_arn
}

output "kms_logs_key_arn" {
  description = "KMS key ARN for CloudWatch Logs encryption"
  value       = aws_kms_key.logs.arn
}

################################################################################
# IAM Information
################################################################################

output "instance_role_name" {
  description = "IAM role name for EC2 instance"
  value       = module.iam.instance_role_name
}

output "instance_profile_name" {
  description = "IAM instance profile name"
  value       = module.iam.instance_profile_name
}

################################################################################
# Ansible Inventory Output
################################################################################

output "ansible_inventory" {
  description = "Ansible inventory configuration in INI format"
  value = templatefile("${path.module}/templates/ansible-inventory.tpl", {
    instance_ip = module.ec2.public_ip
    instance_id = module.ec2.instance_id
  })
}

output "ansible_host_vars" {
  description = "Ansible host variables"
  value = {
    ansible_host     = module.ec2.public_ip
    ansible_user     = "ubuntu"
    instance_id      = module.ec2.instance_id
    vpc_id           = module.vpc.vpc_id
    security_group_id = module.security_groups.wireguard_sg_id
  }
}

################################################################################
# SSM Connect Command
################################################################################

output "ssm_connect_command" {
  description = "AWS SSM Session Manager connect command (no SSH key needed)"
  value       = "aws ssm start-session --target ${module.ec2.instance_id} --region ${var.aws_region}"
}

################################################################################
# Summary
################################################################################

output "deployment_summary" {
  description = "Deployment summary with next steps"
  value = <<-EOT

    TPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPW
    Q          WireGuard VPN Infrastructure Deployed                 Q
    ZPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP]

    Instance Details:
      " Instance ID:  ${module.ec2.instance_id}
      " Public IP:    ${module.ec2.public_ip}
      " Private IP:   ${module.ec2.private_ip}
      " Region:       ${var.aws_region}

    Security:
      " VPC ID:           ${module.vpc.vpc_id}
      " Security Group:   ${module.security_groups.wireguard_sg_id}
      " EBS Encrypted:    Yes (KMS)
      " IMDSv2:           Enforced
      " Flow Logs:        Enabled

    Access:
      " SSM Session Manager (recommended):
        aws ssm start-session --target ${module.ec2.instance_id} --region ${var.aws_region}

      " SSH (if enabled):
        ssh ubuntu@${module.ec2.public_ip}

    Next Steps:
      1. Update Ansible inventory with IP: ${module.ec2.public_ip}
      2. Configure Ansible vault with WireGuard keys
      3. Run Ansible playbook: ansible-playbook -i inventory/aws.ini playbooks/setup-wireguard.yml
      4. Connect clients to VPN at: ${module.ec2.public_ip}:51820

  EOT
}
