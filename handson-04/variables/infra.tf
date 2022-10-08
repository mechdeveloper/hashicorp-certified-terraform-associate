resource "aws_security_group" "variables_demo" {

  name        = "ablearn-variables"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpn_ip] # Referencing a variable var.<variablename>
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpn_ip] # Referencing a variable var.<variablename>
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpn_ip] # Referencing a variable var.<variablename>
  }

}