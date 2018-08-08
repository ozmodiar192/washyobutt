# Create an EC2 instance to host the website
resource "aws_instance" "wybSingleton" {
  ami                         = "ami-2757f631"
  instance_type               = "t2.nano"
  key_name                    = "wyb.pub"
  security_groups             = ["${aws_security_group.allow_ssh.id}","${aws_security_group.allow_web.id}","${aws_security_group.allow_all_outbound.id}"]
  subnet_id                   = "${aws_subnet.wybPublic_main.id}"
  associate_public_ip_address = true
  tags {
    Name                      = "washyobuttSingleton"
  }
# provisioning commands
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y install nginx",
      "git clone https://github.com/ozmodiar192/washyobutt.git",
      "sudo ln -s ~/washyobutt/content/* /var/www/html/",
      "sudo service nginx start",
    ]
# Define connection for provisioner
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("../../private/wyb_provisioner")}"
    }
  }
}
