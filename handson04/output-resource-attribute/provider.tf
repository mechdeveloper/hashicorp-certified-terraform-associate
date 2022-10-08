terraform {
  required_version = "1.2.9"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.34.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-west-2"
}