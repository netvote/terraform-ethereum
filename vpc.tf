resource "aws_eip" "ethereum" {
  vpc = true
}

resource "aws_route53_zone" "private" {
  name   = "netvote.internal"
  vpc_id = "${aws_vpc.ethereum.id}"
}

resource "aws_vpc" "ethereum" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }
}

resource "aws_subnet" "eth_public" {
  vpc_id     = "${aws_vpc.ethereum.id}"
  cidr_block = "10.0.0.0/24"

  tags = {
    Name        = "${var.environment} Public"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }
}

resource "aws_subnet" "eth_private_a" {
  vpc_id     = "${aws_vpc.ethereum.id}"
  cidr_block = "10.0.1.0/24"

  tags = {
    Name        = "${var.environment} Private AZ-a"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }

  availability_zone = "us-east-1a"
}

resource "aws_subnet" "eth_private_c" {
  vpc_id     = "${aws_vpc.ethereum.id}"
  cidr_block = "10.0.3.0/24"

  tags = {
    Name        = "${var.environment} Private AZ-c"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }

  availability_zone = "us-east-1c"
}

resource "aws_subnet" "eth_public_bastion" {
  vpc_id                  = "${aws_vpc.ethereum.id}"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment} Bastion"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }

  availability_zone = "us-east-1b"
}

resource "aws_nat_gateway" "eth_nat_gw" {
  allocation_id = "${aws_eip.ethereum.id}"
  subnet_id     = "${aws_subnet.eth_public.id}"

  tags = {
    Name        = "${var.environment}"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }
}

resource "aws_internet_gateway" "eth_igw" {
  vpc_id = "${aws_vpc.ethereum.id}"

  tags = {
    Name        = "${var.environment}"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }
}

resource "aws_route_table" "eth_nat_gw" {
  vpc_id = "${aws_vpc.ethereum.id}"

  route {
    nat_gateway_id = "${aws_nat_gateway.eth_nat_gw.id}"
    cidr_block     = "0.0.0.0/0"
  }

  tags = {
    Name        = "${var.environment} nat gw"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }
}

resource "aws_route_table_association" "eth_igw" {
  route_table_id = "${aws_route_table.eth_igw.id}"
  subnet_id      = "${aws_subnet.eth_public.id}"
}

resource "aws_route_table_association" "eth_bastion" {
  route_table_id = "${aws_route_table.eth_igw.id}"
  subnet_id      = "${aws_subnet.eth_public_bastion.id}"
}

resource "aws_route_table" "eth_igw" {
  vpc_id = "${aws_vpc.ethereum.id}"

  route {
    gateway_id = "${aws_internet_gateway.eth_igw.id}"
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name        = "${var.environment} igw"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }
}

resource "aws_main_route_table_association" "eth" {
  vpc_id         = "${aws_vpc.ethereum.id}"
  route_table_id = "${aws_route_table.eth_nat_gw.id}"
}

# SECURITY GROUPS

resource "aws_security_group" "ethereum_ec2" {
  vpc_id = "${aws_vpc.ethereum.id}"

  tags = {
    Name        = "${var.environment} EC2-SG"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }
}

resource "aws_security_group_rule" "ec2_sg_in" {
  security_group_id        = "${aws_security_group.ethereum_ec2.id}"
  source_security_group_id = "${aws_security_group.ethereum_ec2.id}"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
}

resource "aws_security_group_rule" "ec2_sg_out" {
  security_group_id        = "${aws_security_group.ethereum_ec2.id}"
  source_security_group_id = "${aws_security_group.ethereum_ec2.id}"
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
}

resource "aws_security_group_rule" "ec2_sg_all_out" {
  security_group_id = "${aws_security_group.ethereum_ec2.id}"
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
}

resource "aws_security_group_rule" "ec2_sg_in_alb" {
  security_group_id        = "${aws_security_group.ethereum_ec2.id}"
  source_security_group_id = "${aws_security_group.ethereum_alb.id}"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
}

resource "aws_security_group_rule" "ec2_sg_out_alb" {
  security_group_id        = "${aws_security_group.ethereum_ec2.id}"
  source_security_group_id = "${aws_security_group.ethereum_alb.id}"
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
}

resource "aws_security_group" "ethereum_alb" {
  vpc_id = "${aws_vpc.ethereum.id}"

  tags = {
    Name        = "${var.environment} ALB-SG"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }
}

resource "aws_security_group_rule" "ec2_alb_in_alb" {
  security_group_id        = "${aws_security_group.ethereum_alb.id}"
  source_security_group_id = "${aws_security_group.ethereum_alb.id}"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
}

resource "aws_security_group_rule" "ec2_alb_in_ec2" {
  security_group_id        = "${aws_security_group.ethereum_alb.id}"
  source_security_group_id = "${aws_security_group.ethereum_ec2.id}"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
}

resource "aws_security_group_rule" "ec2_alb_out_alb" {
  security_group_id        = "${aws_security_group.ethereum_alb.id}"
  source_security_group_id = "${aws_security_group.ethereum_alb.id}"
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
}

resource "aws_security_group_rule" "ec2_alb_out_ec2" {
  security_group_id        = "${aws_security_group.ethereum_alb.id}"
  source_security_group_id = "${aws_security_group.ethereum_ec2.id}"
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
}
