variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "cloudwatch_log_group_name" {
  description = "Name of CloudWatch log group for EC2 logs"
  type        = string
}

variable "create_flow_logs_role" {
  description = "Whether to create VPC Flow Logs IAM role"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
