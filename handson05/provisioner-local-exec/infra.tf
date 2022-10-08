# Check provider_version.tf file for provider configuration

resource "aws_instance" "myec2" {
  ami           = "ami-08e2d37b6a0129927"
  instance_type = "t2.micro"

  provisioner "local-exec" {
    command = "echo ${aws_instance.myec2.private_ip} >> private_ips.txt"
  }
}
