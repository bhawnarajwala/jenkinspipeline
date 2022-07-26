resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"


tags = {
    Name = "myvpc"
}
}

resource "aws_subnet" "Public" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"

  tags = { 
    Name = "Public"
}
}



resource "aws_subnet" "Private" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "Private"
}
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "main"
  }
}

resource "aws_nat_gateway" "ngw" {
    
  subnet_id     = aws_subnet.Private.id

  tags = {
    Name = "gw NAT"
  }

}

resource "aws_security_group" "sg" {
  name =   "First-SG"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "First-SG"
}
}

