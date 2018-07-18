#Create a security group to allow incoming ssh from my current external IP
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow all inbound traffic"

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

# Create my keypair for access to the box
resource "aws_key_pair" "wyb_public" {
  key_name = "wyb.pub"
  public_key = "${var.publicKey}"
}

