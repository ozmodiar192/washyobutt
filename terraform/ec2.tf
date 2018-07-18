resource "aws_instance" "wyb-singleton" {
  ami             = "ami-2757f631"
  instance_type   = "t2.nano"
  key_name        = "wyb.pub"
  security_groups = ["allow_ssh"]
  tags {
    Name = "washyobutt"
  }
}
