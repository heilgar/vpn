output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "s3_bucket_region" {
  description = "Region of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.region
}

output "next_steps" {
  description = "Instructions for next steps"
  value       = <<-EOT

    ✓ S3 backend bucket created successfully!

    Next steps:
    1. cd .. (back to aws directory)
    2. Update backend.tf if you changed the bucket name
    3. terraform init
    4. terraform plan
    5. terraform apply

  EOT
}
