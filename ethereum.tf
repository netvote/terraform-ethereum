resource "aws_instance" "bootnode" {
  ami                    = "ami-467ca739"
  subnet_id              = "${aws_subnet.eth_private_a.id}"
  vpc_security_group_ids = ["${aws_security_group.ethereum_ec2.id}"]
  instance_type          = "t2.micro"
  key_name               = "${var.keyName}"
  iam_instance_profile   = "${aws_iam_instance_profile.ethereum.id}"

  tags = {
    Name        = "${var.environment} Boot Node"
    Environment = "${var.environment}"
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
    source      = "init-scripts/bootnode-compose.yaml"
    destination = "/home/ec2-user/bootnode-compose.yaml"

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
      "sudo docker-compose -f /home/ec2-user/bootnode-compose.yaml up -d",
    ]

    connection {
      type         = "ssh"
      bastion_host = "${aws_instance.bastion.public_ip}"
      user         = "ec2-user"
    }
  }
}

data "template_file" "node1" {
  template = "${file("init-scripts/node-compose-template.yaml")}"

  vars {
    image_name       = "eth-node-1"
    bootnode_ip_port = "${aws_instance.bootnode.private_ip}:30310"
    alb_domain       = "${aws_alb.ethereum_nodes.dns_name}"
  }
}

data "template_file" "node2" {
  template = "${file("init-scripts/node-compose-template.yaml")}"

  vars {
    image_name       = "eth-node-2"
    bootnode_ip_port = "${aws_instance.bootnode.private_ip}:30310"
    alb_domain       = "${aws_alb.ethereum_nodes.dns_name}"
  }
}

data "template_file" "node_readonly" {
  template = "${file("init-scripts/node-compose-template.yaml")}"

  vars {
    image_name       = "eth-node-readonly"
    bootnode_ip_port = "${aws_instance.bootnode.private_ip}:30310"
    alb_domain       = "${aws_alb.ethereum_nodes.dns_name}"
  }
}

resource "aws_instance" "eth_node_readonly" {
  ami                    = "ami-467ca739"
  subnet_id              = "${aws_subnet.eth_public_bastion.id}"
  vpc_security_group_ids = ["${aws_security_group.ethereum_alb.id}"]
  instance_type          = "t2.medium"
  key_name               = "${var.keyName}"
  iam_instance_profile   = "${aws_iam_instance_profile.ethereum.id}"

  tags = {
    Name        = "${var.environment} Node Read-Only"
    Address     = "0xd5429bb0e3cc9b32464c803f78d2271667548962"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }

   provisioner "file" {
    source      = "init-scripts/install-docker.sh"
    destination = "/home/ec2-user/install-docker.sh"

    connection {
      type         = "ssh"
      host = "${aws_instance.eth_node_readonly.public_ip}"
      user         = "ec2-user"
    }
  }

  provisioner "file" {
    content     = "${data.template_file.node_readonly.rendered}"
    destination = "/home/ec2-user/node-compose.yaml"

    connection {
      type         = "ssh"
      host = "${aws_instance.eth_node_readonly.public_ip}"
      user         = "ec2-user"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 755 /home/ec2-user/install-docker.sh",
      "/home/ec2-user/install-docker.sh",
      "sudo docker-compose -f /home/ec2-user/node-compose.yaml up -d",
    ]

    connection {
      type         = "ssh"
      host = "${aws_instance.eth_node_readonly.public_ip}"
      user         = "ec2-user"
    }
  }
}

resource "aws_instance" "eth_node_readonly_2" {
  ami                    = "ami-467ca739"
  subnet_id              = "${aws_subnet.eth_public_c.id}"
  vpc_security_group_ids = ["${aws_security_group.ethereum_alb.id}"]
  instance_type          = "t2.medium"
  key_name               = "${var.keyName}"
  iam_instance_profile   = "${aws_iam_instance_profile.ethereum.id}"

  tags = {
    Name        = "${var.environment} Node Read-Only"
    Address     = "0xd5429bb0e3cc9b32464c803f78d2271667548962"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }

   provisioner "file" {
    source      = "init-scripts/install-docker.sh"
    destination = "/home/ec2-user/install-docker.sh"

    connection {
      type         = "ssh"
      host = "${aws_instance.eth_node_readonly_2.public_ip}"
      user         = "ec2-user"
    }
  }

  provisioner "file" {
    content     = "${data.template_file.node_readonly.rendered}"
    destination = "/home/ec2-user/node-compose.yaml"

    connection {
      type         = "ssh"
      host = "${aws_instance.eth_node_readonly_2.public_ip}"
      user         = "ec2-user"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 755 /home/ec2-user/install-docker.sh",
      "/home/ec2-user/install-docker.sh",
      "sudo docker-compose -f /home/ec2-user/node-compose.yaml up -d",
    ]

    connection {
      type         = "ssh"
      host = "${aws_instance.eth_node_readonly_2.public_ip}"
      user         = "ec2-user"
    }
  }
}

resource "aws_instance" "eth_node1" {
  ami                    = "ami-467ca739"
  subnet_id              = "${aws_subnet.eth_private_a.id}"
  vpc_security_group_ids = ["${aws_security_group.ethereum_ec2.id}"]
  instance_type          = "t2.medium"
  key_name               = "${var.keyName}"
  iam_instance_profile   = "${aws_iam_instance_profile.ethereum.id}"

  tags = {
    Name        = "${var.environment} Node 1"
    Address     = "0x46a22cbdffe1fe792578ab5c9627cf0d8da5f186"
    Environment = "${var.environment}"
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
    content     = "${data.template_file.node1.rendered}"
    destination = "/home/ec2-user/node1-compose.yaml"

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
      "sudo docker-compose -f /home/ec2-user/node1-compose.yaml up -d",
    ]

    connection {
      type         = "ssh"
      bastion_host = "${aws_instance.bastion.public_ip}"
      user         = "ec2-user"
    }
  }
}

resource "aws_instance" "eth_node2" {
  ami                    = "ami-467ca739"
  subnet_id              = "${aws_subnet.eth_private_c.id}"
  vpc_security_group_ids = ["${aws_security_group.ethereum_ec2.id}"]
  instance_type          = "t2.medium"
  key_name               = "${var.keyName}"
  iam_instance_profile   = "${aws_iam_instance_profile.ethereum.id}"

  tags = {
    Name        = "${var.environment} Node 2"
    Address     = "0x6953882101696b2a92456ffb03e28b62240ff3f0"
    Environment = "${var.environment}"
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
    content     = "${data.template_file.node2.rendered}"
    destination = "/home/ec2-user/node2-compose.yaml"

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
      "sudo docker-compose -f /home/ec2-user/node2-compose.yaml up -d",
    ]

    connection {
      type         = "ssh"
      bastion_host = "${aws_instance.bastion.public_ip}"
      user         = "ec2-user"
    }
  }
}

resource "aws_alb" "ethereum_read_only_nodes" {
  name               = "ethereum-readonly-rpc-http-lb"
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.ethereum_alb.id}"]
  subnets            = ["${aws_subnet.eth_public_bastion.id}","${aws_subnet.eth_public_c.id}"]

  enable_deletion_protection = false

  tags {
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }
}

resource "aws_lb_target_group" "readonly_rpc" {
  name     = "ethereum-readonly-rpc"
  port     = 8545
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.ethereum.id}"
}

resource "aws_lb_target_group_attachment" "node_readonly_rpc" {
  target_group_arn = "${aws_lb_target_group.readonly_rpc.arn}"
  target_id        = "${aws_instance.eth_node_readonly.id}"
  port             = 8545
}

resource "aws_lb_target_group_attachment" "node_readonly_2_rpc" {
  target_group_arn = "${aws_lb_target_group.readonly_rpc.arn}"
  target_id        = "${aws_instance.eth_node_readonly_2.id}"
  port             = 8545
}

resource "aws_lb_listener" "readonly_rpc" {
  load_balancer_arn = "${aws_alb.ethereum_read_only_nodes.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = "arn:aws:acm:us-east-1:891335278704:certificate/b2c107d1-6bfb-43d0-8420-7250ac294e60"

  default_action {
    target_group_arn = "${aws_lb_target_group.readonly_rpc.arn}"
    type             = "forward"
  }
}


resource "aws_alb" "ethereum_nodes" {
  name               = "ethereum-rpc-http-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.ethereum_alb.id}"]
  subnets            = ["${aws_subnet.eth_private_a.id}", "${aws_subnet.eth_private_c.id}"]

  enable_deletion_protection = false

  tags {
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }
}

resource "aws_route53_record" "ethereum" {
  zone_id = "${aws_route53_zone.private.zone_id}"
  name    = "ethereum"
  type    = "CNAME"
  ttl     = "5"
  records = ["${aws_alb.ethereum_nodes.dns_name}"]
}

resource "aws_lb_target_group" "explorer" {
  name     = "ethereum-explorer"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.ethereum.id}"
}

resource "aws_lb_target_group" "rpc" {
  name     = "ethereum-rpc"
  port     = 8545
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.ethereum.id}"
}

resource "aws_lb_target_group_attachment" "node1_explorer" {
  target_group_arn = "${aws_lb_target_group.explorer.arn}"
  target_id        = "${aws_instance.eth_node1.id}"
  port             = 8000
}

resource "aws_lb_target_group_attachment" "node1_rpc" {
  target_group_arn = "${aws_lb_target_group.rpc.arn}"
  target_id        = "${aws_instance.eth_node1.id}"
  port             = 8545
}

resource "aws_lb_target_group_attachment" "node2_explorer" {
  target_group_arn = "${aws_lb_target_group.explorer.arn}"
  target_id        = "${aws_instance.eth_node2.id}"
  port             = 8000
}

resource "aws_lb_target_group_attachment" "node2_rpc" {
  target_group_arn = "${aws_lb_target_group.rpc.arn}"
  target_id        = "${aws_instance.eth_node2.id}"
  port             = 8545
}

resource "aws_lb_listener" "explorer" {
  load_balancer_arn = "${aws_alb.ethereum_nodes.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.explorer.arn}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "rpc" {
  load_balancer_arn = "${aws_alb.ethereum_nodes.arn}"
  port              = "8545"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.rpc.arn}"
    type             = "forward"
  }
}
