resource "aws_instance" "ipfs_c" {
  ami                    = "ami-467ca739"
  subnet_id              = "${aws_subnet.ipfs_c.id}"
  vpc_security_group_ids = ["${aws_security_group.ipfs_nodes.id}"]
  instance_type          = "t2.micro"
  key_name               = "${var.keyName}"

  tags = {
    Name        = "IPFS Node C"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }

  provisioner "file" {
    source      = "init-scripts/install-docker.sh"
    destination = "/home/ec2-user/install-docker.sh"

    connection {
      type         = "ssh"
      bastion_host = "${aws_instance.bastion.public_ip}"
      user         = "ec2-user"
    }
  }

  provisioner "file" {
    source     = "init-scripts/ipfs-compose.yaml"
    destination = "/home/ec2-user/docker-compose.yaml"

    connection {
      type         = "ssh"
      bastion_host = "${aws_instance.bastion.public_ip}"
      user         = "ec2-user"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 755 /home/ec2-user/install-docker.sh",
      "/home/ec2-user/install-docker.sh",
      "sudo docker-compose up -d",
    ]

    connection {
      type         = "ssh"
      bastion_host = "${aws_instance.bastion.public_ip}"
      user         = "ec2-user"
    }
  }
}

resource "aws_instance" "ipfs_a" {
  ami                    = "ami-467ca739"
  subnet_id              = "${aws_subnet.ipfs_a.id}"
  vpc_security_group_ids = ["${aws_security_group.ipfs_nodes.id}"]
  instance_type          = "t2.micro"
  key_name               = "${var.keyName}"

  tags = {
    Name        = "IPFS Node A"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }

  provisioner "file" {
    source      = "init-scripts/install-docker.sh"
    destination = "/home/ec2-user/install-docker.sh"

    connection {
      type         = "ssh"
      bastion_host = "${aws_instance.bastion.public_ip}"
      user         = "ec2-user"
    }
  }

  provisioner "file" {
    source     = "init-scripts/ipfs-compose.yaml"
    destination = "/home/ec2-user/docker-compose.yaml"

    connection {
      type         = "ssh"
      bastion_host = "${aws_instance.bastion.public_ip}"
      user         = "ec2-user"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 755 /home/ec2-user/install-docker.sh",
      "/home/ec2-user/install-docker.sh",
      "sudo docker-compose up -d",
    ]

    connection {
      type         = "ssh"
      bastion_host = "${aws_instance.bastion.public_ip}"
      user         = "ec2-user"
    }
  }
}

resource "aws_alb" "ipfs_gateway" {
  name               = "ipfs-gateway"
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.ethereum_alb.id}"]
  subnets            = ["${aws_subnet.ipfs_a.id}","${aws_subnet.ipfs_c.id}"]

  enable_deletion_protection = true

  tags {
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }
}

resource "aws_lb_target_group" "ipfs_5001" {
  name     = "ipfs-5001"
  port     = 5001
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.ethereum.id}"
}

resource "aws_lb_target_group" "ipfs_8080" {
  name     = "ipfs-8080"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.ethereum.id}"
}

resource "aws_lb_target_group_attachment" "ipfsc_5001" {
  target_group_arn = "${aws_lb_target_group.ipfs_5001.arn}"
  target_id        = "${aws_instance.ipfs_c.id}"
  port             = 5001
}

resource "aws_lb_target_group_attachment" "ipfsc_8080" {
  target_group_arn = "${aws_lb_target_group.ipfs_8080.arn}"
  target_id        = "${aws_instance.ipfs_c.id}"
  port             = 8080
}
resource "aws_lb_target_group_attachment" "ipfs_5001" {
  target_group_arn = "${aws_lb_target_group.ipfs_5001.arn}"
  target_id        = "${aws_instance.ipfs_a.id}"
  port             = 5001
}

resource "aws_lb_target_group_attachment" "ipfs_8080" {
  target_group_arn = "${aws_lb_target_group.ipfs_8080.arn}"
  target_id        = "${aws_instance.ipfs_a.id}"
  port             = 8080
}

resource "aws_lb_listener" "ipfs_gateway_https_5001" {
  load_balancer_arn = "${aws_alb.ipfs_gateway.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = "arn:aws:acm:us-east-1:891335278704:certificate/b2c107d1-6bfb-43d0-8420-7250ac294e60"

  default_action {
    target_group_arn = "${aws_lb_target_group.ipfs_8080.arn}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "ipfs_gateway_https_8080" {
  load_balancer_arn = "${aws_alb.ipfs_gateway.arn}"
  port              = "8443"
  protocol          = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = "arn:aws:acm:us-east-1:891335278704:certificate/b2c107d1-6bfb-43d0-8420-7250ac294e60"

  default_action {
    target_group_arn = "${aws_lb_target_group.ipfs_5001.arn}"
    type             = "forward"

  }
}
