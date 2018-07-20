resource "aws_instance" "wyb-singleton" {
  ami                         = "ami-2757f631"
  instance_type               = "t2.nano"
  key_name                    = "wyb.pub"
  security_groups             = ["${aws_security_group.allow_ssh.id}"]
  subnet_id                   = "${aws_subnet.wyb_public_main.id}"
  associate_public_ip_address = true
  tags {
    Name                      = "washyobutt"
  }
}
