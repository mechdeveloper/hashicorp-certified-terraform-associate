# Check provider_version.tf file for provider configuration

resource "aws_instance" "web" {
  ami           = "ami-08e2d37b6a0129927"
  instance_type = var.instancetype # Variable instancetype is being referenced here
}