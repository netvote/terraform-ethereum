resource "aws_instance" "bastion" {
  ami                    = "ami-467ca739"
  subnet_id              = "${aws_subnet.eth_public_bastion.id}"
  vpc_security_group_ids = ["${aws_security_group.ethereum_alb.id}"]
  instance_type          = "t2.micro"
  key_name               = "${var.keyName}"

  tags = {
    Name        = "${var.environment} Bastion"
    Environment = "${var.environment}"
    Owner       = "${var.owner}"
    Managed     = "${var.managedBy}"
  }
}
