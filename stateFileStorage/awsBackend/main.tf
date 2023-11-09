# configuring terraform provider -- run this first before creating the cloud backend
# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 5.0"
#     }
#   }
# }
# config for aws backend for statefile
terraform {
  backend "s3" {
    bucket         = "juwon_terraform_statefile"
    dynamodb_table = "terraform-state-locking"
    key            = "tf/statefile/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
# Configure the AWS Provider
provider "aws" {
  region                   = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "vscodeTerraform"
}
# create an s3 bucket too store the statefile
resource "aws_s3_bucket" "juwon_terraform_statefile" {
  bucket        = "juwon-tf-bucket"
  force_destroy = true
}
# apply server side AES256 encrption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto_config" {
  bucket = aws_s3_bucket.juwon_terraform_statefile.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
# create dynamobd to lock the state file with using terraform apply
resource "aws_dynamodb_table" "juw0n_terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}