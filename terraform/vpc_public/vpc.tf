resource "aws_vpc" "wyb_public" {
  cidr_block = "192.168.0.0/16"
  tags {
    Name     = "wyb_public"
  }
}

resource "aws_internet_gateway" "wyb_public_igw" {
  vpc_id = "${aws_vpc.wyb_public.id}"
  tags {
    Name = "wyb_public_igw"
  }
}

resource "aws_subnet" "wyb_public_main" {
  vpc_id     = "${aws_vpc.wyb_public.id}"
  cidr_block = "192.168.1.0/24"
  tags {
    Name     = "wyb_public_main"
  }
}

resource "aws_route_table" "wyb_main_default" {
  vpc_id       = "${aws_vpc.wyb_public.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.wyb_public_igw.id}"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = "${aws_subnet.wyb_public_main.id}"
  route_table_id = "${aws_route_table.wyb_main_default.id}"
}

