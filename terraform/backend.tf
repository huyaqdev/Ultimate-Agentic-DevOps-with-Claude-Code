# Remote State Backend Configuration
#
# HOW TO USE:
# ------------
# Step 1: Run `terraform init` and `terraform apply` WITHOUT this backend block
#         to create the S3 bucket and DynamoDB table for state storage.
#
# Step 2: Once the state bucket exists, uncomment the terraform block below
#         and replace the placeholder values:
#           - bucket → your state S3 bucket name (from outputs or AWS console)
#           - dynamodb_table → your DynamoDB lock table name
#
# Step 3: Run `terraform init -migrate-state` to move local state to S3.
#         Terraform will prompt you to confirm the migration.
#
# WARNING: Do NOT uncomment this block before the bucket exists — Terraform
#          will fail to initialize if the backend bucket is missing.

# terraform {
#   backend "s3" {
#     bucket         = "demo-site-terraform-state"   # Replace with your state bucket name
#     key            = "demo-site/production/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "demo-site-terraform-locks"   # Replace with your DynamoDB table name
#     encrypt        = true
#   }
# }
