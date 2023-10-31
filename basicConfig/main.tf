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

resource "aws_instance" "example" {
  ami           = "ami-011899242bb902164"
  instance_type = "t2.micro"
}