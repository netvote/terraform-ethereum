resource "aws_instance" "odk_aggregate" {
  ami                    = "ami-467ca739"
  subnet_id              = "${aws_subnet.eth_public_bastion.id}"
  vpc_security_group_ids = ["${aws_security_group.odk.id}"]
  instance_type          = "t2.micro"
  key_name               = "${var.keyName}"

  provisioner "file" {
    source      = "init-scripts/install-docker.sh"
    destination = "/home/ec2-user/install-docker.sh"

    connection {
      type = "ssh"
      host = "${aws_instance.odk_aggregate.public_ip}"
      user = "ec2-user"
    }
  }

  provisioner "file" {
    source      = "init-scripts/odk"
    destination = "/home/ec2-user/odk"

    connection {
      type = "ssh"
      host = "${aws_instance.odk_aggregate.public_ip}"
      user = "ec2-user"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 755 /home/ec2-user/install-docker.sh",
      "/home/ec2-user/install-docker.sh",
      "cd /home/ec2-user/odk/",
      "sudo docker-compose up -d",
    ]

    connection {
      type = "ssh"
      host = "${aws_instance.odk_aggregate.public_ip}"
      user = "ec2-user"
    }
  }

  tags = {
    Name        = "${var.environment} ODK Aggregate"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }
}

resource "aws_security_group" "odk" {
  vpc_id = "${aws_vpc.ethereum.id}"

  tags = {
    Name        = "${var.environment} ODK"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }
}

resource "aws_security_group_rule" "odk_from_odkalb" {
  security_group_id        = "${aws_security_group.odk.id}"
  source_security_group_id = "${aws_security_group.odk_alb.id}"
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "all"
}

resource "aws_security_group_rule" "ssh_to_odk" {
  security_group_id = "${aws_security_group.odk.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "all"
}

resource "aws_security_group_rule" "odk_outbound" {
  security_group_id = "${aws_security_group.odk.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
}

resource "aws_security_group" "odk_alb" {
  vpc_id = "${aws_vpc.ethereum.id}"

  tags = {
    Name        = "${var.environment} ALB-ODK"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }
}

resource "aws_security_group_rule" "http_to_odkalb" {
  security_group_id = "${aws_security_group.odk_alb.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
  from_port         = 80
  to_port           = 8080
  protocol          = "all"
}

resource "aws_security_group_rule" "odkalb_to_odk" {
  security_group_id = "${aws_security_group.odk_alb.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "all"
}

resource "aws_alb" "odk_aggregate" {
  name               = "odk-aggregate-web"
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.odk_alb.id}"]
  subnets            = ["${aws_subnet.eth_public_bastion.id}", "${aws_subnet.eth_public.id}"]

  enable_deletion_protection = false

  tags {
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }
}

resource "aws_route53_record" "odk" {
  zone_id = "${aws_route53_zone.private.zone_id}"
  name    = "odk"
  type    = "CNAME"
  ttl     = "5"
  records = ["${aws_alb.odk_aggregate.dns_name}"]
}

resource "aws_lb_target_group" "odk_aggregate" {
  name     = "odk-aggregate"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.ethereum.id}"
}

resource "aws_lb_target_group_attachment" "odk_aggregate" {
  target_group_arn = "${aws_lb_target_group.odk_aggregate.arn}"
  target_id        = "${aws_instance.odk_aggregate.id}"
  port             = 8080
}

resource "aws_lb_listener" "odk_aggregate" {
  load_balancer_arn = "${aws_alb.odk_aggregate.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.odk_aggregate.arn}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "https_odk_aggregate" {
  load_balancer_arn = "${aws_alb.odk_aggregate.arn}"
  port              = "443"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.odk_aggregate.arn}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "odk_aggregate8080" {
  load_balancer_arn = "${aws_alb.odk_aggregate.arn}"
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.odk_aggregate.arn}"
    type             = "forward"
  }
}
