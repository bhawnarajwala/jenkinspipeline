resource "aws_vpc" "vpc" {
cidr_block = "${var.vpc-cidr}"
instance_tenancy        = "default"
enable_dns_hostnames    = true
tags      = {
Name    = "Test_VPC"
}
}

resource "aws_internet_gateway" "internet-gateway" {
vpc_id    = aws_vpc.vpc.id
tags = {
Name    = "internet_gateway"
}
}

resource "aws_subnet" "public-subnet-1" {
vpc_id                  = aws_vpc.vpc.id
cidr_block              = "${var.Public_Subnet_1}"
availability_zone       = "us-west-2a"
map_public_ip_on_launch = true
tags      = {
Name    = "public-subnet-1"
}
}

resource "aws_route_table" "public-route-table" {
vpc_id       = aws_vpc.vpc.id
route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.internet-gateway.id
}
tags       = {
Name     = "Public Route Table"
}
}
resource "aws_route_table_association" "public-subnet-1-route-table-association" {
subnet_id           = aws_subnet.public-subnet-1.id
route_table_id      = aws_route_table.public-route-table.id
}

resource "aws_subnet" "private-subnet-1" {
vpc_id                   = aws_vpc.vpc.id
cidr_block               = "${var.Private_Subnet_1}"
availability_zone        = "us-west-2a"
map_public_ip_on_launch  = false
tags      = {
Name    = "private-subnet-1"
}
}

resource "tls_private_key" "key" {
algorithm = "RSA"
}
resource "local_file" "private_key" {
filename          = "TEST.pem"
sensitive_content = tls_private_key.key.private_key_pem
file_permission   = "0400"
}
resource "aws_key_pair" "key_pair" {
key_name   = "TEST"
public_key = tls_private_key.key.public_key_openssh
}

resource "aws_security_group" "ssh-security-group" {
name        = "SSH Security Group"
description = "Enable SSH access on Port 22"
vpc_id      = aws_vpc.vpc.id
ingress {
description      = "SSH Access"
from_port        = 22
to_port          = 22
protocol         = "tcp"
cidr_blocks      = ["${var.ssh-location}"]
}
ingress {
description      = "Jenkin Access"
from_port        = 8080
to_port          = 8080
protocol         = "tcp"
cidr_blocks      = ["${var.ssh-location}"]
}
egress {
from_port        = 0
to_port          = 0
protocol         = "-1"
cidr_blocks      = ["0.0.0.0/0"]
}
tags   = {
Name = "SSH Security Group"
}
}

resource "aws_security_group" "webserver-security-group" {
name        = "Web Server Security Group"
description = "Enable HTTP/HTTPS access on Port 80/443 via ALB and SSH access on Port 22 via SSH SG"
vpc_id      = aws_vpc.vpc.id
ingress {
description      = "SSH Access"
from_port        = 22
to_port          = 22
protocol         = "tcp"
security_groups  = ["${aws_security_group.ssh-security-group.id}"]
}
ingress {
description      = "Jenkin Access"
from_port        = 8080
to_port          = 8080
protocol         = "tcp"
security_groups  = ["${aws_security_group.ssh-security-group.id}"]
}
egress {
from_port        = 0
to_port          = 0
protocol         = "-1"
cidr_blocks      = ["0.0.0.0/0"]
}
tags   = {
Name = "Web Server Security Group"
}
}

resource "aws_instance" "ec2_public" {
ami                    = "ami-a0cfeed8"
instance_type               = "${var.instance_type}"
key_name                    = "${var.key_name}"
vpc_security_group_ids            = ["${aws_security_group.ssh-security-group.id}"]
subnet_id                   = "${aws_subnet.public-subnet-1.id}"
associate_public_ip_address = true

lifecycle {
create_before_destroy = true
}
tags = {
"Name" = "EC2-PUBLIC"
"Env" = "dev"
}

provisioner "file" {
source      = "./${var.key_name}.pem"
destination = "/home/ec2-user/${var.key_name}.pem"
connection {
type        = "ssh"
user        = "ec2-user"
private_key = file("${var.key_name}.pem")
host        = self.public_ip
}
}

provisioner "remote-exec" {
inline = ["chmod 400 ~/${var.key_name}.pem"]
connection {
type        = "ssh"
user        = "ec2-user"
private_key = file("${var.key_name}.pem")
host        = self.public_ip
}
}
}