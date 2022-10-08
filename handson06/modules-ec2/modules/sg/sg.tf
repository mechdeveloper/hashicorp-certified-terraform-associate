resource "aws_security_group" "ec2-sg" {
    name = "myec2-sg"

    ingress = [{
      description = "Allow Inbound from Secret Application"
      from_port = local.app_port
      to_port = local.app_port
      protocol = "tcp"
      cidr_blocks = [ "0.0.0.0/0" ]
    }]
}

resource "aws_security_group" "elb-sg" {
    name = "myelb-sg"

    ingress = [{
      description = "Allow Inbound from Secret Application"
      from_port = local.app_port
      to_port = local.app_port
      protocol = "tcp"
      cidr_blocks = [ "0.0.0.0/0" ]
    }]
}

locals {
  app_port = 8444
}