variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where EC2 instance will be created"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to instance"
  type        = list(string)
}

variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t4g.nano"
}

variable "ami_id" {
  description = "AMI ID (leave empty to use latest Ubuntu 24.04 LTS)"
  type        = string
  default     = ""
}

variable "volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_name" {
  description = "CloudWatch log group name"
  type        = string
}

variable "cloudwatch_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "cloudwatch_kms_key_id" {
  description = "KMS key ID for CloudWatch Logs encryption"
  type        = string
  default     = null
}

variable "enable_automated_backups" {
  description = "Enable automated EBS snapshots via DLM"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain automated snapshots"
  type        = number
  default     = 7
}

variable "dlm_role_arn" {
  description = "IAM role ARN for DLM (required if enable_automated_backups is true)"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "SSH key pair name (leave empty to disable SSH key)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
