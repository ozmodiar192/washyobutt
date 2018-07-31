#Create a security group to allow incoming ssh from my current external IP
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow inbound SSH traffic from my ip"
  vpc_id      = "${aws_vpc.wybPublic.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.icanhazip.body)}/32"]
  }

  tags {
    Name = "allow_ssh"
  }
}
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow website inbound traffic from all IPs"
  vpc_id      = "${aws_vpc.wybPublic.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443 
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow_web"
  }
}
resource "aws_security_group" "allow_all_outbound" {
  name        = "allow_all_outbound"
  description = "Allow all outbound traffic"
  vpc_id      = "${aws_vpc.wybPublic.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow_ssh"
  }
}

# Create my keypair for access to the box
resource "aws_key_pair" "wybPublic" {
  key_name   = "wyb.pub"
  public_key = "${var.publicKey}"
}
