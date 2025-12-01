# Terraform backend configuration for S3 remote state
#
# Prerequisites (create S3 bucket first):
# 1. S3 bucket with versioning enabled
# 2. S3 bucket encryption enabled
#
# Run bootstrap first: cd bootstrap && terraform init && terraform apply

terraform {
  backend "s3" {
    bucket  = "wireguard-vpn-terraform-state-7f3a9c2b"
    key     = "vpn/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    profile = "array360"

    # Use S3-native state locking (DynamoDB is deprecated)
    use_lockfile = true

    # Use workspace-aware state files
    workspace_key_prefix = "workspaces"
  }

  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile


  default_tags {
    tags = {
      Project     = "WireGuard-VPN"
      ManagedBy   = "Terraform"
      Environment = var.environment
      Workspace   = terraform.workspace
    }
  }
}

