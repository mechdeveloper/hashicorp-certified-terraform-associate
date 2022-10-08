# Create public ip
resource "aws_eip" "lb" {
    vpc = true
}

# Create EC2 instance
resource "aws_instance" "myec2" {
    ami = "ami-08e2d37b6a0129927"
    instance_type = "t2.micro"
}

# Associate public ip with EC2 instance
# Direct Referncing attributes
resource "aws_eip_association" "eip_assoc" {
    # direct referencing
    instance_id = aws_instance.myec2.id 
    allocation_id = aws_eip.lb.id
}

# Attach security group
# Block Style Referncing attributes "${}"
resource "aws_security_group" "allow_tls" {
  name        = "ablearn-security-group"
  
  # Inbound
  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"

    # block style referencing
    cidr_blocks      = ["${aws_eip.lb.public_ip}/32"]
  }
}