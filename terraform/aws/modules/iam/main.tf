# IAM Module - Creates IAM roles and policies for WireGuard EC2 instance
# Follows least privilege principle with SSM Session Manager support

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

################################################################################
# EC2 Instance Role
################################################################################

resource "aws_iam_role" "wireguard" {
  name_prefix        = "${var.name_prefix}-ec2-"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = var.tags
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# SSM Session Manager access (no SSH keys needed)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.wireguard.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Agent for metrics and logs
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.wireguard.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom policy for WireGuard-specific permissions
resource "aws_iam_role_policy" "wireguard" {
  name_prefix = "${var.name_prefix}-policy-"
  role        = aws_iam_role.wireguard.id
  policy      = data.aws_iam_policy_document.wireguard.json
}

data "aws_iam_policy_document" "wireguard" {
  # Read EC2 metadata for auto-configuration
  statement {
    sid = "ReadEC2Metadata"
    actions = [
      "ec2:DescribeTags",
      "ec2:DescribeInstances"
    ]
    resources = ["*"]
  }

  # CloudWatch Logs permissions
  statement {
    sid = "CloudWatchLogs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${var.cloudwatch_log_group_name}:*"
    ]
  }
}

resource "aws_iam_instance_profile" "wireguard" {
  name_prefix = "${var.name_prefix}-profile-"
  role        = aws_iam_role.wireguard.name

  tags = var.tags
}

################################################################################
# VPC Flow Logs Role
################################################################################

resource "aws_iam_role" "vpc_flow_logs" {
  count = var.create_flow_logs_role ? 1 : 0

  name_prefix        = "${var.name_prefix}-vpc-flow-logs-"
  assume_role_policy = data.aws_iam_policy_document.vpc_flow_logs_assume[0].json

  tags = var.tags
}

data "aws_iam_policy_document" "vpc_flow_logs_assume" {
  count = var.create_flow_logs_role ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  count = var.create_flow_logs_role ? 1 : 0

  name_prefix = "${var.name_prefix}-vpc-flow-logs-policy-"
  role        = aws_iam_role.vpc_flow_logs[0].id
  policy      = data.aws_iam_policy_document.vpc_flow_logs[0].json
}

data "aws_iam_policy_document" "vpc_flow_logs" {
  count = var.create_flow_logs_role ? 1 : 0

  statement {
    sid = "VPCFlowLogsPermissions"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

################################################################################
# DLM (Data Lifecycle Manager) Role for EBS Snapshots
################################################################################

resource "aws_iam_role" "dlm" {
  name_prefix        = "${var.name_prefix}-dlm-"
  assume_role_policy = data.aws_iam_policy_document.dlm_assume.json

  tags = var.tags
}

data "aws_iam_policy_document" "dlm_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "dlm" {
  name_prefix = "${var.name_prefix}-dlm-policy-"
  role        = aws_iam_role.dlm.id
  policy      = data.aws_iam_policy_document.dlm.json
}

data "aws_iam_policy_document" "dlm" {
  statement {
    sid = "DLMSnapshotPermissions"
    actions = [
      "ec2:CreateSnapshot",
      "ec2:CreateSnapshots",
      "ec2:DeleteSnapshot",
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
      "ec2:EnableFastSnapshotRestores",
      "ec2:DescribeFastSnapshotRestores",
      "ec2:DisableFastSnapshotRestores",
      "ec2:CopySnapshot",
      "ec2:ModifySnapshotAttribute",
      "ec2:DescribeSnapshotAttribute"
    ]
    resources = ["*"]
  }

  statement {
    sid = "DLMTagPermissions"
    actions = [
      "ec2:CreateTags"
    ]
    resources = ["arn:aws:ec2:*::snapshot/*"]
  }
}
