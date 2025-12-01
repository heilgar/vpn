# Root configuration - Orchestrates all modules for WireGuard VPN infrastructure

locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Workspace   = terraform.workspace
    },
    var.additional_tags
  )
}

################################################################################
# Logging and Monitoring Infrastructure
################################################################################

# KMS key for CloudWatch Logs encryption
resource "aws_kms_key" "logs" {
  description             = "${var.project_name} - CloudWatch Logs encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-logs-key"
    }
  )
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${var.project_name}-logs"
  target_key_id = aws_kms_key.logs.key_id
}

# KMS key policy for CloudWatch Logs
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_kms_key_policy" "logs" {
  key_id = aws_kms_key.logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })
}

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${var.project_name}-flow-logs"
  retention_in_days = var.cloudwatch_retention_days
  kms_key_id        = aws_kms_key.logs.arn

  tags = local.common_tags
}

################################################################################
# IAM Module
################################################################################

module "iam" {
  source = "./modules/iam"

  name_prefix               = var.project_name
  cloudwatch_log_group_name = "/aws/ec2/${var.project_name}"
  create_flow_logs_role     = true

  tags = local.common_tags
}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  source = "./modules/vpc"

  name_prefix          = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  availability_zone    = var.availability_zone
  enable_flow_logs     = true
  flow_logs_role_arn   = module.iam.vpc_flow_logs_role_arn
  flow_logs_destination_arn = aws_cloudwatch_log_group.vpc_flow_logs.arn

  tags = local.common_tags
}

################################################################################
# Security Groups Module
################################################################################

module "security_groups" {
  source = "./modules/security-groups"

  name_prefix       = var.project_name
  vpc_id            = module.vpc.vpc_id
  wireguard_port    = var.wireguard_port
  allowed_ssh_cidrs = var.allowed_ssh_cidrs

  tags = local.common_tags
}

################################################################################
# EC2 Module
################################################################################

module "ec2" {
  source = "./modules/ec2"

  name_prefix               = var.project_name
  aws_region                = var.aws_region
  subnet_id                 = module.vpc.public_subnet_id
  security_group_ids        = [module.security_groups.wireguard_sg_id]
  iam_instance_profile      = module.iam.instance_profile_name
  instance_type             = var.instance_type
  volume_size               = var.volume_size
  enable_detailed_monitoring = var.enable_detailed_monitoring
  cloudwatch_log_group_name = "/aws/ec2/${var.project_name}"
  cloudwatch_retention_days = var.cloudwatch_retention_days
  cloudwatch_kms_key_id     = aws_kms_key.logs.arn
  enable_automated_backups  = var.enable_automated_backups
  backup_retention_days     = var.backup_retention_days
  dlm_role_arn              = module.iam.dlm_role_arn
  key_name                  = var.key_name

  tags = local.common_tags
}
