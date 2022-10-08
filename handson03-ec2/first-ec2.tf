provider "aws" {
  region = "us-west-2"
  # access_key = ""
  # secret_key = ""
}

resource "aws_instance" "web" {
    ami = "ami-08e2d37b6a0129927"
    instance_type = "t2.micro"
}