resource "aws_instance" "bootnode" {
  ami                    = "ami-467ca739"
  subnet_id              = "${aws_subnet.eth_private.id}"
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
