terraform {
    required_providers {
       aws = {
        source = "hashicorp/aws"
      version = "~> 5.0"
       }
    }
}
# Configure the AWS Provider
provider "aws" {
    region                   = "us-east-1"
    shared_config_files      = ["~/.aws/config"]
    shared_credentials_files = ["~/.aws/credentials"]
    profile                  = "vscodeTerraform"
}

resource "aws_s3_bucket" "terraform_state_s3" {
  bucket        = "terraform-state"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto_conf" {
  bucket        = aws_s3_bucket.terraform_state_s3.bucket 
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}