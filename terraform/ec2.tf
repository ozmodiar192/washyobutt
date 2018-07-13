provider "aws" {
  access_key = "${var.accessKey}"
  secret_key = "${var.secretKey}"
  region     = "${var.region}"
}

resource "aws_instance" "wyb-singleton" {
  ami             = "ami-2757f631"
  instance_type   = "t2.nano"
  key_name        = "wyb"
  security_groups = ["allow_ssh"]
}
