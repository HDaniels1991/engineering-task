terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  profile = "arrydan-Admin"
  region  = "eu-west-1"
  default_tags {
    tags = {
      Environment = var.stage
      Owner       = "Harry Daniels"
      Project     = "Antarctica"
    }
  }
}
