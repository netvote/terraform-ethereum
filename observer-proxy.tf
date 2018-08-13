resource "aws_instance" "observer_proxy" {
  ami                    = "ami-467ca739"
  subnet_id              = "${aws_subnet.eth_public_bastion.id}"
  vpc_security_group_ids = ["${aws_security_group.observer_proxy.id}"]
  instance_type          = "t2.micro"
  key_name               = "${var.keyName}"
  iam_instance_profile   = "${aws_iam_instance_profile.ethereum.id}"

  provisioner "file" {
    source      = "init-scripts/install-docker.sh"
    destination = "/home/ec2-user/install-docker.sh"

    connection {
      type = "ssh"
      host = "${aws_instance.observer_proxy.public_ip}"
      user = "ec2-user"
    }
  }

  provisioner "file" {
    source      = "init-scripts/observer_proxy"
    destination = "/home/ec2-user/observer_proxy"

    connection {
      type = "ssh"
      host = "${aws_instance.observer_proxy.public_ip}"
      user = "ec2-user"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 755 /home/ec2-user/install-docker.sh",
      "/home/ec2-user/install-docker.sh",
      "cd /home/ec2-user/observer_proxy/",
      "sudo docker-compose up -d",
    ]

    connection {
      type = "ssh"
      host = "${aws_instance.observer_proxy.public_ip}"
      user = "ec2-user"
    }
  }

  tags = {
    Name        = "${var.environment} Observer Proxy"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }
}

resource "aws_security_group" "observer_proxy" {
  vpc_id = "${aws_vpc.ethereum.id}"

  tags = {
    Name        = "${var.environment} Observer Proxy"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }
}

resource "aws_security_group_rule" "observer_proxy_from_observer_proxyalb" {
  security_group_id        = "${aws_security_group.observer_proxy.id}"
  source_security_group_id = "${aws_security_group.observer_proxy_alb.id}"
  type                     = "ingress"
  from_port                = 8015
  to_port                  = 8015
  protocol                 = "all"
}

resource "aws_security_group_rule" "ssh_to_observer_proxy" {
  security_group_id = "${aws_security_group.observer_proxy.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "all"
}

resource "aws_security_group_rule" "observer_proxy_outbound" {
  security_group_id = "${aws_security_group.observer_proxy.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
}

resource "aws_security_group" "observer_proxy_alb" {
  vpc_id = "${aws_vpc.ethereum.id}"

  tags = {
    Name        = "${var.environment} ALB-Observer Proxy"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }
}

resource "aws_security_group_rule" "http_to_observer_proxyalb" {
  security_group_id = "${aws_security_group.observer_proxy_alb.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "all"
}

resource "aws_security_group_rule" "observer_proxyalb_to_observer_proxy" {
  security_group_id = "${aws_security_group.observer_proxy_alb.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
  from_port         = 8015
  to_port           = 8015
  protocol          = "all"
}

resource "aws_alb" "observer_proxy" {
  name               = "observer-proxy-web"
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.observer_proxy_alb.id}"]
  subnets            = ["${aws_subnet.eth_public_bastion.id}", "${aws_subnet.eth_public.id}"]

  enable_deletion_protection = false

  tags {
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }
}

resource "aws_route53_record" "observer_proxy" {
  zone_id = "${aws_route53_zone.private.zone_id}"
  name    = "observerproxy"
  type    = "CNAME"
  ttl     = "5"
  records = ["${aws_alb.observer_proxy.dns_name}"]
}

resource "aws_lb_target_group" "observer_proxy" {
  name     = "observerproxy"
  port     = 8015
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.ethereum.id}"
}

resource "aws_lb_target_group_attachment" "observer_proxy" {
  target_group_arn = "${aws_lb_target_group.observer_proxy.arn}"
  target_id        = "${aws_instance.observer_proxy.id}"
  port             = 8015
}

resource "aws_lb_listener" "https_observer_proxy" {
  load_balancer_arn = "${aws_alb.observer_proxy.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = "arn:aws:acm:us-east-1:891335278704:certificate/b2c107d1-6bfb-43d0-8420-7250ac294e60"
  default_action {
    target_group_arn = "${aws_lb_target_group.observer_proxy.arn}"
    type             = "forward"
  }
}
