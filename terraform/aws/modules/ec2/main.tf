# EC2 Module - Creates WireGuard VPN server instance
# Includes EBS encryption, IMDSv2, CloudWatch monitoring, and automated backups

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

################################################################################
# KMS Keys for Encryption
################################################################################

resource "aws_kms_key" "ebs" {
  description             = "${var.name_prefix} - EBS volume encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-ebs-key"
    }
  )
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/${var.name_prefix}-ebs"
  target_key_id = aws_kms_key.ebs.key_id
}

################################################################################
# CloudWatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "wireguard" {
  name              = var.cloudwatch_log_group_name
  retention_in_days = var.cloudwatch_retention_days
  kms_key_id        = var.cloudwatch_kms_key_id

  tags = var.tags
}

################################################################################
# EC2 Instance
################################################################################

resource "aws_instance" "wireguard" {
  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  key_name      = var.key_name != "" ? var.key_name : null

  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = var.iam_instance_profile

  # Enforce IMDSv2 for enhanced security
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Encrypted root volume with KMS
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.volume_size
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    kms_key_id            = aws_kms_key.ebs.arn
    delete_on_termination = true

    tags = merge(
      var.tags,
      {
        Name = "${var.name_prefix}-root-volume"
      }
    )
  }

  # Enable detailed CloudWatch monitoring
  monitoring = var.enable_detailed_monitoring

  # Disable source/destination check for VPN routing
  source_dest_check = false

  # Minimal user data - Ansible handles full configuration
  user_data = base64encode(templatefile("${path.module}/user-data.sh.tpl", {
    cloudwatch_log_group = aws_cloudwatch_log_group.wireguard.name
    aws_region           = var.aws_region
  }))

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-server"
      Role = "wireguard-vpn"
    }
  )

  lifecycle {
    ignore_changes = [
      ami,
      user_data
    ]
  }
}

################################################################################
# Elastic IP
################################################################################

resource "aws_eip" "wireguard" {
  domain   = "vpc"
  instance = aws_instance.wireguard.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-eip"
    }
  )
}

################################################################################
# Automated Backups with Data Lifecycle Manager
################################################################################

resource "aws_dlm_lifecycle_policy" "backup" {
  count = var.enable_automated_backups ? 1 : 0

  description        = "Automated EBS snapshots for ${var.name_prefix}"
  execution_role_arn = var.dlm_role_arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["INSTANCE"]

    schedule {
      name = "Daily snapshots"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["03:00"]
      }

      retain_rule {
        count = var.backup_retention_days
      }

      tags_to_add = {
        SnapshotType = "DLM-Automated"
      }

      copy_tags = true
    }

    target_tags = {
      Role = "wireguard-vpn"
    }
  }

  tags = var.tags
}

# IAM role for DLM
resource "aws_iam_role" "dlm" {
  count = var.enable_automated_backups ? 1 : 0

  name_prefix        = "${var.name_prefix}-dlm-"
  assume_role_policy = data.aws_iam_policy_document.dlm_assume[0].json

  tags = var.tags
}

data "aws_iam_policy_document" "dlm_assume" {
  count = var.enable_automated_backups ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "dlm" {
  count = var.enable_automated_backups ? 1 : 0

  role       = aws_iam_role.dlm[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}
