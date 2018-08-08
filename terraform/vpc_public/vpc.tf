# Define the VPC
resource "aws_vpc" "wybPublic" {
  cidr_block = "192.168.0.0/16"
  tags {
    Name     = "wybPublic"
  }
}

# Create Internet gateway for outbound access
resource "aws_internet_gateway" "wybPublic_igw" {
  vpc_id = "${aws_vpc.wybPublic.id}"
  tags {
    Name = "wybPublic_igw"
  }
}

# Create a subnet
resource "aws_subnet" "wybPublic_main" {
  vpc_id     = "${aws_vpc.wybPublic.id}"
  cidr_block = "192.168.1.0/24"
  tags {
    Name     = "wybPublic_main"
  }
}

# Create a default route to send all outbound traffic through the internet gateway
resource "aws_route_table" "wybMainRoute_default" {
  vpc_id       = "${aws_vpc.wybPublic.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.wybPublic_igw.id}"
  }
}

# Associate the route table to the subnet
resource "aws_route_table_association" "a" {
  subnet_id      = "${aws_subnet.wybPublic_main.id}"
  route_table_id = "${aws_route_table.wybMainRoute_default.id}"
}

