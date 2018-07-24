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
  provisioner "file" {
    source      = "../../private/wyb_deploy"
    destination = "/home/ubuntu/.ssh/wyb_deploy"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("/home/matt/.ssh/wyb")}"
    }
  }
  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/ubuntu/.ssh/wyb_deploy"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("/home/matt/.ssh/wyb")}"
    }
  }
}
