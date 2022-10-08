# Check provider_version.tf file for provider configuration

resource "aws_instance" "myec2" {
  ami           = "ami-08e2d37b6a0129927"
  instance_type = "t2.micro"

  # Create aws Keypair
  key_name = "private-key"

  # Establishes connection to be used by all 
  # generic remote provisioners (i.e. file/remote-exec)
  connection {
    type        = "ssh"
    user        = "ec2_user"
    private_key = file("./private-key.pem") # private-key.pem file must be present on local directory
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo amazon-linux-extras install -y nginx1",
      "sudo systemctl start nginx",
    ]
  }
}
