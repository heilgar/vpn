variable "aws_region" {
  description = "AWS region for VPN infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use for authentication"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name (e.g., production, staging, dev)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "wireguard-vpn"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for subnet"
  type        = string
  default     = "us-east-1a"
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type for WireGuard server"
  type        = string
  default     = "t4g.nano" # ARM-based Graviton2 ($0.0042/hr)
}

variable "volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "enable_ebs_encryption" {
  description = "Enable EBS volume encryption"
  type        = bool
  default     = true
}

# WireGuard Configuration
variable "wireguard_port" {
  description = "UDP port for WireGuard"
  type        = number
  default     = 51820
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH (leave empty to disable SSH ingress)"
  type        = list(string)
  default     = [] # Recommend using SSM Session Manager instead
}

variable "allowed_vpn_cidrs" {
  description = "CIDR blocks allowed to connect to WireGuard VPN"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict this in production
}

variable "key_name" {
  description = "SSH key pair name for EC2 access"
  type        = string
  default     = ""
}

# Monitoring and Logging
variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring for EC2"
  type        = bool
  default     = true
}

variable "cloudwatch_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# Backup Configuration
variable "enable_automated_backups" {
  description = "Enable automated EBS snapshots"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain automated snapshots"
  type        = number
  default     = 7
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

