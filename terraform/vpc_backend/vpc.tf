# Define the VPC
resource "aws_vpc" "wybBackend" {
  cidr_block = "192.168.2.0/24"
  tags {
    Name     = "wybBackend"
  }
}

# Create Internet gateway for outbound access
resource "aws_internet_gateway" "wybBackend_igw" {
  vpc_id = "${aws_vpc.wybBackend.id}"
  tags {
    Name = "wybBackend_igw"
  }
}

# Create a subnet
resource "aws_subnet" "wybBackend_main" {
  vpc_id     = "${aws_vpc.wybBackend.id}"
  cidr_block = "192.168.2.0/24"
  tags {
    Name     = "wybBackend_main"
  }
}

# Create a default route to send all outbound traffic through the internet gateway
resource "aws_route_table" "wybMainRoute_default" {
  vpc_id       = "${aws_vpc.wybBackend.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.wybBackend_igw.id}"
  }
}

# Associate the route table to the subnet
resource "aws_route_table_association" "a" {
  subnet_id      = "${aws_subnet.wybBackend_main.id}"
  route_table_id = "${aws_route_table.wybMainRoute_default.id}"
}

